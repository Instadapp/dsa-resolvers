// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import "./helpers.sol";

contract AaveV3Resolver is AaveV3Helper {
    function getPosition(address user, address[] memory tokens)
        public
        view
        returns (
            AaveV3UserTokenData[] memory,
            AaveV3TokenData[] memory,
            AaveV3UserData memory
        )
    {
        uint256 length = tokens.length;
        address[] memory _tokens = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            _tokens[i] = tokens[i] == getEthAddr() ? getWethAddr() : tokens[i];
        }

        AaveV3UserTokenData[] memory tokensData = new AaveV3UserTokenData[](length);
        AaveV3TokenData[] memory collData = new AaveV3TokenData[](length);
        (TokenPrice[] memory tokenPrices, uint256 ethPrice) = getTokensPrices(_tokens);

        for (uint256 i = 0; i < length; i++) {
            tokensData[i] = getUserTokenData(user, _tokens[i]);
            collData[i] = userCollateralData(_tokens[i], tokenPrices[i]);
        }

        return (tokensData, collData, getUserData(user, _tokens));
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
