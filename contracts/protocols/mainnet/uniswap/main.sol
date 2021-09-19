// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    /**
     * @dev Sort token address
     * @param _token0: token0 Address
     * @param _token1: token1 Address
     */
    function sort(address _token0, address _token1) external view returns (address token0, address token1) {
        if (_token0 < _token1) {
            token0 = _token1;
            token1 = _token0;
        } else {
            token0 = _token0;
            token1 = _token1;
        }
    }

    function getPoolDetails(PoolConfig[] memory poolConfigs) public view returns (PoolData[] memory poolDatas) {
        poolDatas = new PoolData[](poolConfigs.length);
        for (uint256 i = 0; i < poolConfigs.length; i++) {
            poolDatas[i] = poolDetails(poolConfigs[i]);
        }
    }

    function getPositionInfoByTokenId(uint256 tokenId) public view returns (PositionInfo memory pInfo) {
        (pInfo) = positions(tokenId);
    }

    function getPositionsInfo(address user, uint256[] memory stakedTokenIds)
        public
        view
        returns (uint256[] memory tokenIds, PositionInfo[] memory positionsInfo)
    {
        tokenIds = userNfts(user);
        positionsInfo = new PositionInfo[](tokenIds.length + stakedTokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            (positionsInfo[i]) = positions(tokenId);
        }

        for (uint256 i = 0; i < stakedTokenIds.length; i++) {
            uint256 tokenId = stakedTokenIds[i];
            (positionsInfo[tokenIds.length + i]) = positions(tokenId);
        }
    }

    function getMintAmount(MintParams memory mintParams)
        public
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
        mintParams.tokenA = mintParams.tokenA == ethAddr ? (wethAddr) : (mintParams.tokenA);
        mintParams.tokenB = mintParams.tokenB == ethAddr ? (wethAddr) : (mintParams.tokenB);

        (token0, token1, liquidity, amount0, amount1, amount0Min, amount1Min) = mintAmount(mintParams);

        token0 == wethAddr ? (ethAddr) : (token0);
        token1 == wethAddr ? (ethAddr) : (token1);
    }

    function getDepositAmount(
        uint256 tokenId,
        uint256 amountA,
        uint256 amountB,
        uint256 slippage
    )
        public
        view
        returns (
            uint256 liquidity,
            uint256 amount0,
            uint256 amount1,
            uint256 amount0Min,
            uint256 amount1Min
        )
    {
        (liquidity, amount0, amount1, amount0Min, amount1Min) = depositAmount(tokenId, amountA, amountB, slippage);
    }

    function getSingleDepositAmount(
        uint256 tokenId,
        address tokenA,
        uint256 amountA,
        uint256 slippage
    )
        public
        view
        returns (
            uint256 liquidity,
            address tokenB,
            uint256 amountB,
            uint256 amountAMin,
            uint256 amountBMin
        )
    {
        (liquidity, tokenB, amountB, amountAMin, amountBMin) = singleDepositAmount(tokenId, tokenA, amountA, slippage);
    }

    function getSingleMintAmount(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 slippage,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper
    )
        public
        view
        returns (
            uint256 liquidity,
            uint256 amountB,
            uint256 amountAMin,
            uint256 amountBMin
        )
    {
        (liquidity, amountB, amountAMin, amountBMin) = singleMintAmount(
            tokenA,
            amountA,
            tokenB,
            slippage,
            fee,
            tickLower,
            tickUpper
        );
    }

    function getWithdrawAmount(
        uint256 tokenId,
        uint256 liquidity,
        uint256 slippage
    )
        public
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 amount0Min,
            uint256 amount1Min
        )
    {
        (amount0, amount1, amount0Min, amount1Min) = withdrawAmount(tokenId, liquidity, slippage);
    }

    function getCollectAmount(uint256 tokenId) public returns (uint256 amountA, uint256 amountB) {
        (amountA, amountB) = collectInfo(tokenId);
    }

    function getUserNFTs(address user) public view returns (uint256[] memory tokenIds) {
        tokenIds = userNfts(user);
    }
}

contract InstaUniswapV3Resolver is Resolver {
    string public constant name = "UniswapV3-Resolver-v1";
}
