// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
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

    function getPositionInfoByTokenId(uint256 tokenId)
        public
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
        (token0, token1, fee, tickLower, tickUpper, liquidity) = positions(tokenId);
    }

    function getDepositAmount(
        uint256 tokenId,
        uint256 amountA,
        uint256 amountB
    )
        public
        view
        returns (
            uint256 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        if (tokenId == 0) tokenId = getLastNftId(msg.sender);
        (liquidity, amount0, amount1) = depositAmount(tokenId, amountA, amountB);
    }

    function getSigleDepositAmount(
        uint256 tokenId,
        address tokenA,
        uint256 amountA
    ) public view returns (address tokenB, uint256 amountB) {
        (tokenB, amountB) = singleDepositAmount(tokenId, tokenA, amountA);
    }

    function getWithdrawAmount(uint256 tokenId, uint128 liquidity)
        public
        view
        returns (uint256 amountA, uint256 amountB)
    {
        if (tokenId == 0) tokenId = getLastNftId(msg.sender);
        (amountA, amountB) = withdrawAmount(tokenId, liquidity);
    }

    function getCollectAmount(uint256 tokenId) public view returns (uint256 amountA, uint256 amountB) {
        (amountA, amountB) = collectInfo(tokenId);
    }

    function getUserNFTs(address user) public view returns (uint256[] memory tokenIds) {
        tokenIds = userNfts(user);
    }
}

contract UniswapV3Resolver is Resolver {
    string public constant name = "UniswapV3-Resolver-v1";
}
