// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./helpers.sol";

/**
 *@title Morpho-Blue Resolver
 *@dev Get user position details and market details.
 */
contract MorphoBlueResolver is Helpers {
    using MathLib for uint256;
    using MorphoLib for IMorpho;
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;
    using SafeERC20 for ERC20;
    using SharesMathLib for uint256;

    function getPosition(address user, MarketParams[] memory marketParams) 
        public 
        view 
        returns(PositionData[] memory positionData, MarketData[] memory marketData)
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