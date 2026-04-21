// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./interfaces.sol";
import "./helpers.sol";

/**
 *@title Venus Core Pool Resolver
 *@dev Get user position, market data, and reserves list for Venus Core Pool on BSC.
 */
contract VenusCoreResolver is VenusCoreHelper {
    /**
     *@dev Get position of the user for specific vTokens.
     *@notice Returns user's overall position, per-market user data, and market-level data.
     *@param user The address of the user whose details are needed.
     *@param vTokens Array of vToken addresses to query.
     *@return VenusUserData user's overall position (liquidity, shortfall, XVS accrued).
     *@return VenusUserMarketData[] user's per-market details (supply, borrow, collateral status).
     *@return VenusMarketData[] market-level details (rates, totals, risk parameters).
     */
    function getPosition(
        address user,
        address[] memory vTokens
    )
        public
        view
        returns (
            VenusUserData memory,
            VenusUserMarketData[] memory,
            VenusMarketData[] memory
        )
    {
        uint256 length = vTokens.length;
        VenusUserData memory userData = getUserData(user);
        VenusUserMarketData[] memory userMarketsData = new VenusUserMarketData[](length);
        VenusMarketData[] memory marketsData = new VenusMarketData[](length);

        for (uint256 i = 0; i < length; i++) {
            userMarketsData[i] = getUserMarketData(user, vTokens[i]);
            marketsData[i] = getMarketData(vTokens[i]);
        }

        return (userData, userMarketsData, marketsData);
    }

    /**
     *@dev Get position of the user for all markets.
     *@notice Returns user's overall position across all listed Venus Core Pool markets.
     *@param user The address of the user whose details are needed.
     *@return VenusUserData user's overall position.
     *@return VenusUserMarketData[] user's per-market details for all markets.
     *@return VenusMarketData[] market-level details for all markets.
     */
    function getPositionAll(
        address user
    )
        public
        view
        returns (
            VenusUserData memory,
            VenusUserMarketData[] memory,
            VenusMarketData[] memory
        )
    {
        return getPosition(user, getMarketsList());
    }

    /**
     *@dev Get list of all Venus Core Pool markets.
     *@return vTokens Array of vToken addresses in the core pool.
     */
    function getMarketsList() public view returns (address[] memory vTokens) {
        vTokens = comptroller.getAllMarkets();
    }
}

contract InstaVenusCoreResolverBSC is VenusCoreResolver {
    string public constant name = "VenusCore-Resolver-BSC-v1.0";
}
