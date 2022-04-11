pragma solidity ^0.7.6;
// SPDX-License-Identifier: MIT
import "./interface.sol";
import "./libraries/PoolAddress.sol";

contract Helpers {
    INonfungiblePositionManager public constant nftManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    IUniswapV3Factory public constant factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    IUniLimitOrder public constant limitCon_ = IUniLimitOrder(0x94F401fAD3ebb89fB7380f5fF6E875A88E6Af916);

    /**
     * @dev Get pool address
     * @notice Fetches pool address with token0, token1, and fee
     * @param token0_ Address token0
     * @param token1_ Address token1
     * @param fee_ Fee
     */
    function getPoolAddress(
        address token0_,
        address token1_,
        uint24 fee_
    ) internal view returns (address poolAddr) {
        poolAddr = PoolAddress.computeAddress(
            nftManager.factory(),
            PoolAddress.PoolKey({ token0: token0_, token1: token1_, fee: fee_ })
        );
    }

    /**
     * @dev Get current tick
     * @notice Returns current tick of pool
     * @param token0_ Address token0
     * @param token1_ Address token1
     * @param fee_ Fee
     */
    function getCurrentTick(
        address token0_,
        address token1_,
        uint24 fee_
    ) public view returns (int24 currentTick_) {
        IUniswapV3PoolState poolState_ = IUniswapV3PoolState(getPoolAddress(token0_, token1_, fee_));
        (, currentTick_, , , , , ) = poolState_.slot0();
    }

    /**
     * @dev Get info of NFT
     * @notice Get position info of token ID
     * @param tokenId_ Token ID
     */
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
