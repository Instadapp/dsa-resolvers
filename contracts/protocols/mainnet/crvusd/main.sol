// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./helpers.sol";

/**
 *@title Curve USD Resolver
 *@dev get user position, user configuration, market configuration.
 */
contract CurveUSDResolver is CRVHelpers {
    /**
     *@dev get position of the user for given collateral.
     *@notice get position details of the user in a market.
     *@param user Address of the user whose position details are needed.
     *@param market Address of the market for which the user's position details are needed
     *@param index  This is used for getting controller.
     *@return positionData position details of the user - balances, collaterals and flags.
     *@return marketConfig the market configuration details.
     */
    function getPosition(
        address user,
        address market,
        uint256 index
    ) public view returns (PositionData memory positionData, MarketConfig memory marketConfig) {
        IController controller = getController(market, index);
        uint256[4] memory res = controller.user_state(user);
        positionData.borrow = res[2];
        positionData.supply = res[0];
        positionData.N = res[3];
        positionData.existLoan = controller.loan_exists(user);
        positionData.health = positionData.existLoan ? controller.health(user, false) : 0;
        positionData.loanId = controller.loan_ix(user);
        if (positionData.existLoan) {
            uint256[2] memory prices = controller.user_prices(user);
            UserPrices memory userPrices = UserPrices(prices[0], prices[1]);
            positionData.prices = userPrices;
        }

        marketConfig = getMarketConfig(market, index);
    }

    /**
     *@dev get position of the user for given collateral.
     *@notice get position details of the user in a market.
     *@param user Address of the user whose position details are needed.
     *@param markets Addresses of the market for which the user's position details are needed
     *@param indexes  Array of index. It should be matched with markets.
     *@return positionData Array of positions details of the user - balances, collaterals and flags.
     *@return marketConfig Array of markets configuration details.
     */
    function getPositionAll(
        address user,
        address[] memory markets,
        uint256[] memory indexes
    ) public view returns (PositionData[] memory positionData, MarketConfig[] memory marketConfig) {
        require(markets.length == indexes.length);
        uint256 length = markets.length;
        positionData = new PositionData[](length);
        marketConfig = new MarketConfig[](length);
        for (uint256 i = 0; i < length; i++) {
            (positionData[i], marketConfig[i]) = getPosition(user, markets[i], indexes[i]);
        }
    }

    /**
     *@dev get position of the user for all collaterals.
     *@notice get position details of the user in a market.
     *@param market Address of the market for which the user's position details are needed
     *@param index  This is used for getting controller.
     *@return marketConfig Detailed market configuration.
     */
    function getMarketDetails(address market, uint256 index) public view returns (MarketConfig memory marketConfig) {
        marketConfig = getMarketConfig(market, index);
    }

    /**
     *@dev get position of the user for all collaterals.
     *@notice get position details of the user in a market.
     *@param markets Addresses of the market for which the user's position details are needed
     *@param indexes  Array of index. It should be matched with markets.
     *@return marketConfig Array of detailed market configuration.
     */
    function getMarketDetailsAll(address[] memory markets, uint256[] memory indexes)
        public
        view
        returns (MarketConfig[] memory marketConfig)
    {
        require(markets.length == indexes.length);
        uint256 length = markets.length;
        marketConfig = new MarketConfig[](length);

        for (uint256 i = 0; i < length; i++) {
            marketConfig[i] = getMarketConfig(markets[i], indexes[i]);
        }
    }
}

contract InstaCurveUSDResolver is CurveUSDResolver {
    string public constant name = "CRVUSD-Resolver-v1.0";
}
