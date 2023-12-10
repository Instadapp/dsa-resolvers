// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./helpers.sol";

/**
 * @title Morpho-Blue Resolver
 * @dev Get user position details and market details.
 */
contract MorphoBlueResolver is Helpers {
    function getPosition(address user, MarketParams[] memory marketParams)
        public
        view
        returns (UserData[] memory userDataData, MarketData[] memory marketData)
    {
        uint256 length = marketParams.length;

        for (uint256 i = 0; i < length; i++) {
            // Update ETH address to WETH
            if (marketParams[i].collateralToken == getEthAddr()) {
                marketParams[i].collateralToken = getWethAddr();
            }

            if (marketParams[i].loanToken == getEthAddr()) {
                marketParams[i].loanToken = getWethAddr();
            }

            marketData[i] = getMarketConfig(marketParams[i]);
            userDataData[i] = getUserConfig(user, marketParams[i]);
        }
    }
}
