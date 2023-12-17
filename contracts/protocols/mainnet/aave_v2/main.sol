// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is AaveHelpers {
    function getPosition(address user, address[] memory tokens)
        public
        view
        returns (AaveUserTokenData[] memory, AaveUserData memory)
    {
        AaveAddressProvider addrProvider = AaveAddressProvider(getAaveAddressProvider());
        uint256 length = tokens.length;
        address[] memory _tokens = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            _tokens[i] = tokens[i] == getEthAddr() ? getWethAddr() : tokens[i];
        }

        AaveUserTokenData[] memory tokensData = new AaveUserTokenData[](length);
        (TokenPrice[] memory tokenPrices, uint256 ethPrice) = getTokensPrices(addrProvider, _tokens);

        for (uint256 i = 0; i < length; i++) {
            tokensData[i] = getTokenData(
                AaveProtocolDataProvider(getAaveProtocolDataProvider()),
                user,
                _tokens[i],
                tokenPrices[i].priceInEth,
                tokenPrices[i].priceInUsd
            );
        }

        return (tokensData, getUserData(AaveLendingPool(addrProvider.getLendingPool()), user, ethPrice, _tokens));
    }

    function getConfiguration(address user) public view returns (bool[] memory collateral, bool[] memory borrowed) {
        AaveAddressProvider addrProvider = AaveAddressProvider(getAaveAddressProvider());
        uint256 data = getConfig(user, AaveLendingPool(addrProvider.getLendingPool())).data;
        address[] memory reserveIndex = getList(AaveLendingPool(addrProvider.getLendingPool()));

        collateral = new bool[](reserveIndex.length);
        borrowed = new bool[](reserveIndex.length);

        for (uint256 i = 0; i < reserveIndex.length; i++) {
            if (isUsingAsCollateralOrBorrowing(data, i)) {
                collateral[i] = (isUsingAsCollateral(data, i)) ? true : false;
                borrowed[i] = (isBorrowing(data, i)) ? true : false;
            }
        }
    }

    function getReservesList() public view returns (address[] memory data) {
        AaveAddressProvider addrProvider = AaveAddressProvider(getAaveAddressProvider());
        data = getList(AaveLendingPool(addrProvider.getLendingPool()));
    }
}

contract InstaAaveV2Resolver is Resolver {
    string public constant name = "AaveV2-Resolver-v1.6";
}
