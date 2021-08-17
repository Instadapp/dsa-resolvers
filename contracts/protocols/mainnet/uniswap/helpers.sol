pragma solidity 0.7.6;
pragma abicoder v2;

import { DSMath } from "../../../utils/dsmath.sol";
import "./contracts/interfaces/IUniswapV3Pool.sol";
import "./contracts/libraries/TickMath.sol";
import "./contracts/libraries/TickBitmap.sol";
import "./contracts/libraries/SwapMath.sol";
import "./contracts/libraries/FullMath.sol";
import "./contracts/libraries/SqrtPriceMath.sol";
import "./contracts/libraries/LiquidityMath.sol";
import "./contracts/libraries/FixedPoint96.sol";
import "./contracts/libraries/FixedPoint128.sol";
import "./contracts/libraries/LiquidityAmounts.sol";
import "./contracts/libraries/PositionKey.sol";
import "./contracts/libraries/PoolAddress.sol";
import "./interfaces.sol";

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

    function userNfts(address user) internal view returns (uint256[] memory tokenIds) {
        uint256 len = nftManager.balanceOf(user);
        tokenIds = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = nftManager.tokenOfOwnerByIndex(user, i);
            tokenIds[i] = tokenId;
        }
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
    )
        internal
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (, , address _token0, address _token1, uint24 _fee, int24 tickLower, int24 tickUpper, , , , , ) = nftManager
        .positions(tokenId);

        IUniswapV3Pool pool = IUniswapV3Pool(getPoolAddress(_token0, _token1, _fee));

        // compute the liquidity amount
        {
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

            liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amountA,
                amountB
            );

            (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );

            amount0 = sub(amountA, amount0);
            amount1 = sub(amountB, amount1);
        }
    }

    function singleDepositAmount(
        uint256 tokenId,
        address tokenA,
        uint256 amountA
    ) internal view returns (address tokenB, uint256 amountB) {
        (, , address _token0, address _token1, uint24 _fee, int24 tickLower, int24 tickUpper, , , , , ) = nftManager
        .positions(tokenId);

        bool reverseFlag = false;
        if (tokenA != _token0) {
            (tokenA, tokenB) = (_token0, _token1);
            reverseFlag = true;
        } else {
            tokenB = _token1;
        }

        if (!reverseFlag) {
            uint128 liquidity = LiquidityAmounts.getLiquidityForAmount0(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amountA
            );
            amountB = LiquidityAmounts.getAmount1ForLiquidity(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
        } else {
            uint128 liquidity = LiquidityAmounts.getLiquidityForAmount1(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amountA
            );
            amountB = LiquidityAmounts.getAmount0ForLiquidity(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
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
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            liquidity
        );
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
