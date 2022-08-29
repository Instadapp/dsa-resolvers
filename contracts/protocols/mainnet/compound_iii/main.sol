// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import "./helpers.sol";

/**
 *@title Compund III Resolver
 *@dev get user position, user configuration, market configuration.
 */
contract CompoundIIIResolver is CompoundIIIHelpers {
    /**
     *@dev get position of the user for all collaterals.
     *@notice get position details of the user in a market including overall position data, collaterals, rewards etc.
     *@param user Address of the user whose position details are needed.
     *@param market Address of the market for which the user's position details are needed.
     *@return UserData Overall position details of the user including balances, nonce, rewards and flags.
     *@return UserCollateralData Data related to the collateral assets for which user has the position.
     */
    function getPositionAll(address user, address market)
        public
        returns (UserData memory, UserCollateralData[] memory)
    {
        return (getUserData(user, market), getCollateralAll(user, market));
    }

    /**
     *@dev get position of the user for given collateral.
     *@notice get position details of the user in a market including overall position data, collaterals, rewards etc.
     *@param user Address of the user whose position details are needed.
     *@param market Address of the market for which the user's position details are needed
     *@param tokens IDs or offsets of the token as per comet market whose collateral details are needed.
     *@return UserData Overall position details of the user including balances, nonce, rewards and flags.
     *@return UserCollateralData Data related to the assets input for which user's collateral details are needed.
     */
    function getPosition(
        address user,
        address market,
        uint8[] calldata tokens
    ) public returns (UserData memory, UserCollateralData[] memory) {
        return (getUserData(user, market), getAssetCollaterals(user, market, tokens));
    }

    /**
     *@dev get market configuration.
     *@notice returns the market stats including market supplies, balances, rates, flags for market operations,
     *collaterals or assets active, base asset info etc.
     *@param comet Address of the comet market for which the user's position details are needed.
     *@return MarketCofig Struct containing data related to the market and the assets.
     */
    function getMarketConfiguration(address comet) public returns (MarketConfig memory) {
        return getMarketConfiguration(comet);
    }

    /**
     *@dev get collaterals list where user has positiom.
     *@notice get list of all collaterals in the market.
     *@return data array of token addresses supported in the market.
     */
    function getCollateralsList(address user, address cometMarket) public returns (address[] memory data) {
        return getList(user, cometMarket);
    }
}

contract InstaCompoundIIIResolver is CompoundIIIResolver {
    string public constant name = "Compound-III-Resolver-v1.0";
}
