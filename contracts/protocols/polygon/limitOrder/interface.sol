pragma solidity ^0.7.6;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

interface IUniswapV3PoolState {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

interface IPeripheryImmutableState {
    function factory() external view returns (address);
}

interface INonfungiblePositionManager is IPeripheryImmutableState, IERC721Enumerable {
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

interface IUniLimitOrder {
    function nftToOwner(uint256) external view returns (address);

    function token0To1(uint256) external view returns (bool);

    function returnArray(address) external view returns (uint256[] memory);
}
