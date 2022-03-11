pragma solidity ^0.8.1;
// SPDX-License-Identifier: MIT
import "./interface.sol";
import "./libraries/PoolAddress.sol";

contract Helpers {
    INonfungiblePositionManager public constant nftManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    IUniswapV3Factory public constant factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    IUniLimitOrder public limitCon_ = IUniLimitOrder(0x94F401fAD3ebb89fB7380f5fF6E875A88E6Af916);

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

    function getCurrentTick(
        address token0_,
        address token1_,
        uint24 fee_
    ) public view returns (int24 currentTick_) {
        IUniswapV3PoolState poolState_ = IUniswapV3PoolState(getPoolAddress(token0_, token1_, fee_));
        (, currentTick_, , , , , ) = poolState_.slot0();
    }

    function getPositionInfo(uint256 tokenId_)
        public
        view
        returns (
            address token0_,
            address token1_,
            uint24 fee_,
            int24 tickLower_,
            int24 tickUpper_
        )
    {
        (, , token0_, token1_, fee_, tickLower_, tickUpper_, , , , , ) = nftManager.positions(tokenId_);
    }
}
