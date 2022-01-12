pragma solidity 0.7.6;
pragma abicoder v2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { DSMath } from "../../../utils/dsmath.sol";
import "./contracts/interfaces/IUniswapV3Pool.sol";
import "./contracts/libraries/TickMath.sol";
import "./contracts/libraries/FullMath.sol";
import "./contracts/libraries/FixedPoint128.sol";
import "./contracts/libraries/LiquidityAmounts.sol";
import "./contracts/libraries/PositionKey.sol";
import "./contracts/libraries/PoolAddress.sol";
import "./interfaces.sol";
import "hardhat/console.sol";

abstract contract Helpers is DSMath {
    using SafeMath for uint256;

    /**
     * @dev Return ethereum address
     */
    address internal constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Return Wrapped ETH address
     */
    address internal constant wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ISwapRouter private swapRouter = ISwapRouter(getUniswapSwapRouterAddr());
    IUniswapV3Factory private factory = IUniswapV3Factory(getUniswapV3FactoryAddr());
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    address[] COMMON_ADDRESSES = [
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
        0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
        0x6B175474E89094C44Da98b954EedeAC495271d0F // DAI
    ];

    INonfungiblePositionManager private nftManager = INonfungiblePositionManager(getUniswapNftManagerAddr());

    /**
     * @dev Return uniswap v3 NFT Manager Address
     */
    function getUniswapNftManagerAddr() internal pure returns (address) {
        return 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    }

    function getUniswapSwapRouterAddr() internal pure returns (address) {
        return 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    }

    function getUniswapV3FactoryAddr() internal pure returns (address) {
        return 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    }

    function changeETHtoWETH(address token) internal pure returns (address) {
        if (token == ethAddr) return wethAddr;
        return token;
    }

    function convert18ToDec(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10**(18 - _dec));
    }

    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10**(18 - _dec));
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

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    struct PoolConfig {
        address tokenA;
        address tokenB;
        uint24 fee;
    }

    struct PoolData {
        address token0;
        address token1;
        uint24 fee;
        address pool;
        bool isCreated;
        int24 currentTick;
        uint160 sqrtRatio;
    }

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    function poolDetails(PoolConfig memory poolConfig) internal view returns (PoolData memory poolData) {
        poolData.token0 = poolConfig.tokenA == ethAddr ? (wethAddr) : (poolConfig.tokenA);
        poolData.token1 = poolConfig.tokenB == ethAddr ? (wethAddr) : (poolConfig.tokenB);
        poolData.fee = poolConfig.fee;
        (poolData.token0, poolData.token1) = poolData.token0 < poolData.token1
            ? (poolData.token0, poolData.token1)
            : (poolData.token1, poolData.token0);

        poolData.pool = getPoolAddress(poolData.token0, poolData.token1, poolData.fee);
        poolData.isCreated = isContract(poolData.pool);
        if (poolData.isCreated) {
            IUniswapV3Pool pool = IUniswapV3Pool(poolData.pool);
            (poolData.sqrtRatio, poolData.currentTick, , , , , ) = pool.slot0();
        }

        poolData.token0 = poolData.token0 == wethAddr ? (ethAddr) : (poolData.token0);
        poolData.token1 = poolData.token1 == wethAddr ? (ethAddr) : (poolData.token1);
    }

    struct PositionInfo {
        address token0;
        address token1;
        address pool;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        int24 currentTick;
        uint128 liquidity;
        uint128 tokenOwed0;
        uint128 tokenOwed1;
        uint256 amount0;
        uint256 amount1;
        uint256 collectAmount0;
        uint256 collectAmount1;
    }

    function positions(uint256 tokenId) internal view returns (PositionInfo memory pInfo) {
        (
            ,
            ,
            pInfo.token0,
            pInfo.token1,
            pInfo.fee,
            pInfo.tickLower,
            pInfo.tickUpper,
            pInfo.liquidity,
            ,
            ,
            ,

        ) = nftManager.positions(tokenId);
        (, , , , , , , , , , pInfo.tokenOwed0, pInfo.tokenOwed1) = nftManager.positions(tokenId);
        pInfo.pool = getPoolAddress(pInfo.token0, pInfo.token1, pInfo.fee);
        IUniswapV3Pool pool = IUniswapV3Pool(pInfo.pool);
        (, pInfo.currentTick, , , , , ) = pool.slot0();
        {
            (pInfo.amount0, pInfo.amount1, , ) = withdrawAmount(tokenId, pInfo.liquidity, 0);
        }
        (pInfo.collectAmount0, pInfo.collectAmount1) = collectInfo(tokenId);

        pInfo.token0 == wethAddr ? (ethAddr) : (pInfo.token0);
        pInfo.token1 == wethAddr ? (ethAddr) : (pInfo.token1);
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

    struct MintParams {
        address tokenA;
        address tokenB;
        uint24 fee;
        int24 lowerTick;
        int24 upperTick;
        uint256 amountA;
        uint256 amountB;
        uint256 slippage;
    }

    function mintAmount(MintParams memory mintParams)
        internal
        view
        returns (
            address token0,
            address token1,
            uint256 liquidity,
            uint256 amount0,
            uint256 amount1,
            uint256 amount0Min,
            uint256 amount1Min
        )
    {
        {
            (token0, token1) = mintParams.tokenA < mintParams.tokenB
                ? (mintParams.tokenA, mintParams.tokenB)
                : (mintParams.tokenB, mintParams.tokenA);
        }

        // compute the liquidity amount
        {
            IUniswapV3Pool pool = IUniswapV3Pool(getPoolAddress(token0, token1, mintParams.fee));
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

            liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(mintParams.lowerTick),
                TickMath.getSqrtRatioAtTick(mintParams.upperTick),
                mintParams.amountA,
                mintParams.amountB
            );

            (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(mintParams.lowerTick),
                TickMath.getSqrtRatioAtTick(mintParams.upperTick),
                uint128(liquidity)
            );
        }

        amount0Min = getMinAmount(TokenInterface(token0), amount0, mintParams.slippage);
        amount1Min = getMinAmount(TokenInterface(token1), amount1, mintParams.slippage);
    }

    function depositAmount(
        uint256 tokenId,
        uint256 amountA,
        uint256 amountB,
        uint256 slippage
    )
        internal
        view
        returns (
            uint256 liquidity,
            uint256 amount0,
            uint256 amount1,
            uint256 amount0Min,
            uint256 amount1Min
        )
    {
        PositionInfo memory positionInfo;
        (
            ,
            ,
            positionInfo.token0,
            positionInfo.token1,
            positionInfo.fee,
            positionInfo.tickLower,
            positionInfo.tickUpper,
            ,
            ,
            ,
            ,

        ) = nftManager.positions(tokenId);

        IUniswapV3Pool pool = IUniswapV3Pool(
            getPoolAddress(positionInfo.token0, positionInfo.token1, positionInfo.fee)
        );

        // compute the liquidity amount
        {
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

            liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(positionInfo.tickLower),
                TickMath.getSqrtRatioAtTick(positionInfo.tickUpper),
                amountA,
                amountB
            );

            (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(positionInfo.tickLower),
                TickMath.getSqrtRatioAtTick(positionInfo.tickUpper),
                uint128(liquidity)
            );

            // amount0 = sub(amountA, amount0);
            // amount1 = sub(amountB, amount1);
        }

        amount0Min = getMinAmount(TokenInterface(positionInfo.token0), amount0, slippage);
        amount1Min = getMinAmount(TokenInterface(positionInfo.token1), amount1, slippage);
    }

    function singleDepositAmount(
        uint256 tokenId,
        address tokenA,
        uint256 amountA,
        uint256 slippage
    )
        internal
        view
        returns (
            uint256 liquidity,
            address tokenB,
            uint256 amountB,
            uint256 amountAMin,
            uint256 amountBMin
        )
    {
        tokenA = changeETHtoWETH(tokenA);
        PositionInfo memory positionInfo;
        (
            ,
            ,
            positionInfo.token0,
            positionInfo.token1,
            positionInfo.fee,
            positionInfo.tickLower,
            positionInfo.tickUpper,
            ,
            ,
            ,
            ,

        ) = nftManager.positions(tokenId);

        bool reverseFlag = false;
        if (tokenA != positionInfo.token0) {
            (tokenB, tokenA) = (positionInfo.token0, positionInfo.token1);
            reverseFlag = true;
        } else {
            tokenB = positionInfo.token1;
        }

        IUniswapV3Pool pool = IUniswapV3Pool(
            getPoolAddress(positionInfo.token0, positionInfo.token1, positionInfo.fee)
        );
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        // liquidity = LiquidityAmounts.getLiquidityForAmounts(
        //     sqrtPriceX96,
        //     TickMath.getSqrtRatioAtTick(mintParams.lowerTick),
        //     TickMath.getSqrtRatioAtTick(mintParams.upperTick),
        //     mintParams.amountA,
        //     mintParams.amountB
        // );

        if (!reverseFlag) {
            liquidity = LiquidityAmounts.getLiquidityForAmount0(
                TickMath.getSqrtRatioAtTick(positionInfo.tickLower),
                TickMath.getSqrtRatioAtTick(positionInfo.tickUpper),
                amountA
            );
            (, amountB) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(positionInfo.tickLower),
                TickMath.getSqrtRatioAtTick(positionInfo.tickUpper),
                uint128(liquidity)
            );
        } else {
            liquidity = LiquidityAmounts.getLiquidityForAmount1(
                TickMath.getSqrtRatioAtTick(positionInfo.tickLower),
                TickMath.getSqrtRatioAtTick(positionInfo.tickUpper),
                amountA
            );
            (amountB, ) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(positionInfo.tickLower),
                TickMath.getSqrtRatioAtTick(positionInfo.tickUpper),
                uint128(liquidity)
            );
        }

        amountAMin = getMinAmount(TokenInterface(tokenA), amountA, slippage);
        amountBMin = getMinAmount(TokenInterface(tokenB), amountB, slippage);
    }

    function singleMintAmount(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 slippage,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper
    )
        internal
        view
        returns (
            uint256 liquidity,
            uint256 amountB,
            uint256 amountAMin,
            uint256 amountBMin
        )
    {
        tokenA = changeETHtoWETH(tokenA);
        tokenB = changeETHtoWETH(tokenB);
        bool reverseFlag = false;
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
            reverseFlag = true;
        }

        IUniswapV3Pool pool = IUniswapV3Pool(getPoolAddress(tokenA, tokenB, fee));
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        if (!reverseFlag) {
            liquidity = LiquidityAmounts.getLiquidityForAmount0(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amountA
            );
            (, amountB) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                uint128(liquidity)
            );
        } else {
            liquidity = LiquidityAmounts.getLiquidityForAmount1(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amountA
            );
            (amountB, ) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                uint128(liquidity)
            );
        }

        amountAMin = getMinAmount(TokenInterface(tokenA), amountA, slippage);
        amountBMin = getMinAmount(TokenInterface(tokenB), amountB, slippage);
    }

    function withdrawAmount(
        uint256 tokenId,
        uint256 liquidity,
        uint256 slippage
    )
        internal
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 amount0Min,
            uint256 amount1Min
        )
    {
        PositionInfo memory positionInfo;
        (
            ,
            ,
            positionInfo.token0,
            positionInfo.token1,
            positionInfo.fee,
            positionInfo.tickLower,
            positionInfo.tickUpper,
            positionInfo.liquidity,
            ,
            ,
            ,

        ) = nftManager.positions(tokenId);

        IUniswapV3Pool pool = IUniswapV3Pool(
            getPoolAddress(positionInfo.token0, positionInfo.token1, positionInfo.fee)
        );
        {
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
            (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(positionInfo.tickLower),
                TickMath.getSqrtRatioAtTick(positionInfo.tickUpper),
                uint128(positionInfo.liquidity >= liquidity ? positionInfo.liquidity : liquidity)
            );
        }

        amount0Min = getMinAmount(TokenInterface(positionInfo.token0), amount0, slippage);
        amount1Min = getMinAmount(TokenInterface(positionInfo.token1), amount1, slippage);
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

    function getPrice(
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) internal view returns (uint256 price) {
        (tokenIn, tokenOut) = tokenIn > tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);

        console.log("+++++++++++++++++", tokenIn, tokenOut, getPoolAddress(tokenIn, tokenOut, fee));
        IUniswapV3Pool pool = IUniswapV3Pool(getPoolAddress(tokenIn, tokenOut, fee));
        uint160 sqrtPriceX96;
        (sqrtPriceX96, , , , , , ) = pool.slot0();
        console.log(sqrtPriceX96);
        return uint256(sqrtPriceX96).mul(uint256(sqrtPriceX96)).mul(1e18) >> (96 * 2);
    }
}
