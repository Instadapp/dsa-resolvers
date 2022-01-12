// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    function getSwapRouter(
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) public view returns (bytes memory path) {
        address poolAddr = getPoolAddress(tokenIn, tokenOut, fee);
        uint256 maxPrice = 0;
        uint256 pathIndex = 0;
        uint256 MAX_INT = 2**256 - 1;

        for (uint256 i = 0; i < COMMON_ADDRESSES.length; i++) {
            uint256 price1 = getPrice(tokenIn, COMMON_ADDRESSES[i], fee);
            uint256 price2 = getPrice(COMMON_ADDRESSES[i], tokenOut, fee);
            uint256 price = (price1 + price2) / 2;

            if (maxPrice < price) {
                maxPrice = price;
                pathIndex = i;
            }
        }

        if (poolAddr != address(0)) {
            uint256 price = getPrice(tokenIn, tokenOut, fee);

            if (maxPrice < price) {
                maxPrice = price;

                pathIndex = MAX_INT;
            }
        }

        if (pathIndex != MAX_INT) {
            address[3] memory result = [tokenIn, COMMON_ADDRESSES[pathIndex], tokenOut];
            path = abi.encode(result);
        } else {
            address[2] memory result = [tokenIn, tokenOut];
            path = abi.encode(result);
        }
    }
}

contract InstaUniswapV3AutoRouterResolver is Resolver {
    string public constant name = "UniswapV3AutoRouter-Resolver-v1";
}
