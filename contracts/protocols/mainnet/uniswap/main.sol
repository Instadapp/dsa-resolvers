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

    function getPositionInfo(uint256 tokenId)
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
    ) public view returns (uint256 liquidity) {
        if (tokenId == 0) tokenId = getLastNftId(msg.sender);
        liquidity = depositAmount(tokenId, amountA, amountB);
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
}

contract UniswapV3Resolver is Resolver {
    string public constant name = "UniswapV3-Resolver-v1";
}
