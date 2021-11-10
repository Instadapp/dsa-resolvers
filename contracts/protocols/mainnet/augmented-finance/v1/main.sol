// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    /**
     * @dev Get positions on Augmented Finance
     * @param user user address
     * @param tokens token addresses
     */
    function getPositions(address user, address[] memory tokens)
        public
        view
        returns (UserTokenData[] memory, UserData memory)
    {
        IMarketAccessController mac = IMarketAccessController(MARKET_ACCESS_CONTROLLER_ADDRESS);
        IProtocolDataProvider dataProvider = IProtocolDataProvider(PROTOCOL_DATA_PROVIDER_ADDRESS);
        ILendingPool pool = ILendingPool(mac.getLendingPool());
        uint256 size = tokens.length;
        address[] memory addresses = new address[](size);

        for (uint256 index = 0; index < size; index += 1) {
            addresses[index] = tokens[index] == ETHEREUM_ADDRESS ? WETH_ADDRESS : tokens[index];
        }

        UserTokenData[] memory tokensData = new UserTokenData[](size);
        (TokenPrice[] memory tokenPrices, uint256 ethPrice) = getTokensPrices(mac, addresses);

        for (uint256 index = 0; index < size; index += 1) {
            tokensData[index] = getTokenData(
                dataProvider,
                user,
                addresses[index],
                tokenPrices[index].priceInETH,
                tokenPrices[index].priceInUSD
            );
        }

        return (tokensData, getUserData(pool, dataProvider, user, ethPrice));
    }
}

contract InstaAugmentedFinanceV1Resolver is Resolver {
    string public constant name = "Augmented-Finance-V1-Resolver";
}
