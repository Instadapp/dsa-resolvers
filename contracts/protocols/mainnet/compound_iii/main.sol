// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import "./helpers.sol";

/**
 *@title Compund III Resolver
 *@dev get user position, user configuration, market configuration.
 */
contract CompoundIIIResolver is Helpers {
    /**
     *@dev get position of the user for all collaterals.
     */
    function getPositionAll(address user, address market)
        public
        view
        returns (UserData memory, UserCollateralData[] memory)
    {}

    /**
     *@dev get position of the user for given collateral.
     */
    function getPosition(
        address user,
        address market,
        address token
    ) public view returns (UserCollateralData[] memory) {
        return getPosition(user, getList());
    }

    function getMarketConfig(address compet) public view returns (MarketConfig memory) {}

    /**
     *@dev get reserves list.
     *@notice get list of all tokens available in the market.
     *@return data array of token addresses available in the market.
     */
    function getCollateralsList() public view returns (address[] memory data) {}
}

contract InstaAaveV3ResolverArbitrum is AaveV3Resolver {
    string public constant name = "Compound-III-Resolver-v1.0";
}
