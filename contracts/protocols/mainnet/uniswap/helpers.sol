pragma solidity 0.7.6;
pragma abicoder v2;

import { DSMath } from "../../../utils/dsmath.sol";
import "./contracts/interfaces/IUniswapV3Pool.sol";
import "./contracts/libraries/TickMath.sol";
import "./contracts/libraries/FullMath.sol";
import "./contracts/libraries/SqrtPriceMath.sol";
import "./contracts/libraries/FixedPoint96.sol";
import "./contracts/libraries/FixedPoint128.sol";
import "./interfaces.sol";

library PositionKey {
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

library LiquidityAmounts {
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({ token0: tokenA, token1: tokenB, fee: fee });
    }

    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

abstract contract Helpers is DSMath {
    /**
     * @dev Return ethereum address
     */
    address internal constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Return Wrapped ETH address
     */
    address internal constant wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    INonfungiblePositionManager private nftManager = INonfungiblePositionManager(getUniswapNftManagerAddr());

    /**
     * @dev Return uniswap v3 NFT Manager Address
     */
    function getUniswapNftManagerAddr() internal pure returns (address) {
        return 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    }

    function convert18ToDec(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10**(18 - _dec));
    }

    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10**(18 - _dec));
    }

    function changeEthAddress(address buy, address sell)
        internal
        pure
        returns (TokenInterface _buy, TokenInterface _sell)
    {
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr ? TokenInterface(wethAddr) : TokenInterface(sell);
    }

    /**
     * @dev Return uniswap v3 Swap Router Address
     */
    function getUniswapRouterAddr() internal pure returns (address) {
        return 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    }

    /**
     * @dev Get Last NFT Index
     * @param user: User address
     */
    function getLastNftId(address user) internal view returns (uint256 tokenId) {
        uint256 len = nftManager.balanceOf(user);
        tokenId = nftManager.tokenOfOwnerByIndex(user, len - 1);
    }

    function getMinAmount(
        TokenInterface token,
        uint256 amt,
        uint256 slippage
    ) internal view returns (uint256 minAmt) {
        uint256 _amt18 = convertTo18(token.decimals(), amt);
        minAmt = wmul(_amt18, sub(WAD, slippage));
        minAmt = convert18ToDec(token.decimals(), minAmt);
    }

    function positions(uint256 tokenId)
        internal
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity
        )
    {
        (, , token0, token1, fee, tickLower, tickUpper, liquidity, , , , ) = nftManager.positions(tokenId);
    }

    function getPoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) internal view returns (address poolAddr) {
        poolAddr = PoolAddress.computeAddress(
            nftManager.factory(),
            PoolAddress.PoolKey({ token0: token0, token1: token1, fee: fee })
        );
    }

    function depositAmount(
        uint256 tokenId,
        uint256 amountA,
        uint256 amountB
    ) internal view returns (uint256 liquidity) {
        (, , address _token0, address _token1, uint24 _fee, int24 tickLower, int24 tickUpper, , , , , ) = nftManager
        .positions(tokenId);

        IUniswapV3Pool pool = IUniswapV3Pool(getPoolAddress(_token0, _token1, _fee));

        // compute the liquidity amount
        {
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
            uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
            uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

            liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                amountA,
                amountB
            );
        }
    }

    function withdrawAmount(uint256 tokenId, uint128 liquidity)
        internal
        view
        returns (uint256 amount0, uint256 amount1)
    {
        require(liquidity > 0, "liquidity should greater than 0");
        (
            ,
            ,
            address _token0,
            address _token1,
            uint24 _fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 positionLiquidity,
            ,
            ,
            ,

        ) = nftManager.positions(tokenId);

        require(positionLiquidity >= liquidity, "Liquidity amount is over than position liquidity amount");

        IUniswapV3Pool pool = IUniswapV3Pool(getPoolAddress(_token0, _token1, _fee));
        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) = pool.slot0();
        if (currentTick < tickLower) {
            amount0 = SqrtPriceMath.getAmount0Delta(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity,
                false
            );
        } else if (currentTick < tickUpper) {
            amount0 = SqrtPriceMath.getAmount0Delta(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity,
                false
            );
            amount1 = SqrtPriceMath.getAmount1Delta(
                TickMath.getSqrtRatioAtTick(tickLower),
                sqrtPriceX96,
                liquidity,
                false
            );
        } else {
            amount1 = SqrtPriceMath.getAmount1Delta(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity,
                false
            );
        }
    }

    function collectInfo(uint256 tokenId) internal view returns (uint256 amount0, uint256 amount1) {
        (
            ,
            ,
            address _token0,
            address _token1,
            uint24 _fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 _feeGrowthInside0LastX128,
            uint256 _feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = nftManager.positions(tokenId);

        IUniswapV3Pool pool = IUniswapV3Pool(getPoolAddress(_token0, _token1, _fee));

        (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pool.positions(
            PositionKey.compute(getUniswapNftManagerAddr(), tickLower, tickUpper)
        );

        tokensOwed0 += uint128(
            FullMath.mulDiv(feeGrowthInside0LastX128 - _feeGrowthInside0LastX128, liquidity, FixedPoint128.Q128)
        );
        tokensOwed1 += uint128(
            FullMath.mulDiv(feeGrowthInside1LastX128 - _feeGrowthInside1LastX128, liquidity, FixedPoint128.Q128)
        );

        amount0 = tokensOwed0;
        amount1 = tokensOwed1;
    }
}
