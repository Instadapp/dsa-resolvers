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

    function getPositionInfoByTokenId(uint256 tokenId) public view returns (PositionInfo memory pInfo) {
        (pInfo) = positions(tokenId);
    }

    function getPositionsInfo(address user)
        public
        view
        returns (uint256[] memory tokenIds, PositionInfo[] memory positionsInfo)
    {
        tokenIds = userNfts(user);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            (positionsInfo[i]) = positions(tokenId);
        }
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
    )
        public
        view
        returns (
            address,
            uint256,
            address,
            uint256
        )
    {
        (address tokenB, uint256 amountB) = singleDepositAmount(tokenId, tokenA, amountA);
        return (tokenA, amountA, tokenB, amountB);
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

contract InstaUniswapV3Resolver is Resolver {
    string public constant name = "UniswapV3-Resolver-v1";
}
