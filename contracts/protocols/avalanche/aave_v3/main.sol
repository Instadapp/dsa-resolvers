// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import "./helpers.sol";

contract AaveV3Resolver is AaveV3Helper {
    function getPosition(address user, address[] memory tokens)
        public
        view
        returns (
            AaveV3UserData memory,
            AaveV3UserTokenData[] memory,
            AaveV3TokenData[] memory
        )
    {
        uint256 length = tokens.length;
        address[] memory _tokens = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            _tokens[i] = tokens[i] == getAvaxAddr() ? getWavaxAddr() : tokens[i];
        }

        AaveV3UserData memory userDetails = getUserData(user);
        // (TokenPrice[] memory tokenPrices, ) = getTokensPrices(userDetails.base.baseInUSD, _tokens);

        AaveV3UserTokenData[] memory tokensData = new AaveV3UserTokenData[](length);
        AaveV3TokenData[] memory collData = new AaveV3TokenData[](length);

        for (uint256 i = 0; i < length; i++) {
            tokensData[i] = getUserTokenData(user, _tokens[i]);
            collData[i] = userCollateralData(_tokens[i]);
        }

        return (userDetails, tokensData, collData);
    }

    function getPositionAll(address user)
        public
        view
        returns (
            AaveV3UserData memory,
            AaveV3UserTokenData[] memory,
            AaveV3TokenData[] memory
        )
    {
        return getPosition(user, getList());
    }

    function getConfiguration(address user) public view returns (bool[] memory collateral, bool[] memory borrowed) {
        uint256 data = getConfig(user).data;
        address[] memory reserveIndex = getList();

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
        data = getList();
    }
}

contract InstaAaveV3ResolverAvalanche is AaveV3Resolver {
    string public constant name = "AaveV3-Resolver-v1.0";
}
