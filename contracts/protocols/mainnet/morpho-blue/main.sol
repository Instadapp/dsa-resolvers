// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Helpers } from "./helpers.sol";
import { MarketParams } from "./interfaces/IMorpho.sol";

/**
 * @title Morpho-Blue Resolver
 * @dev Get user position details and market details.
 */
contract MorphoBlueResolver is Helpers {
    function getPosition(
        address user,
        MarketParams[] memory marketParamsArr
    ) public view returns (UserData[] memory, MarketData[] memory) {
        uint256 length = marketParamsArr.length;

        UserData[] memory userData = new UserData[](length);
        MarketData[] memory marketData = new MarketData[](length);

        for (uint256 i = 0; i < length; i++) {
            // Update Addresses
            if (marketParamsArr[i].collateralToken == getEthAddr()) {
                marketParamsArr[i].collateralToken = getWethAddr();
            }

            if (marketParamsArr[i].loanToken == getEthAddr()) {
                marketParamsArr[i].loanToken = getWethAddr();
            }

            marketData[i] = getMarketConfig(marketParamsArr[i]);
            userData[i] = getUserConfig(marketData[i].id, marketParamsArr[i], user);
        }

        return (userData, marketData);
    }
}
