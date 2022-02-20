// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is AaveV3Helper {
    function getPosition(address user, address[] memory tokens)
        public
        view
        returns (AaveUserTokenData[] memory, AaveUserData memory)
    {
        IPoolAddressesProvider addrProvider = IPoolAddressesProvider(getPoolAddressProvider());
        uint256 length = tokens.length;
        address[] memory _tokens = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            _tokens[i] = tokens[i] == getEthAddr() ? getWethAddr() : tokens[i];
        }

        AaveUserTokenData[] memory tokensData = new AaveUserTokenData[](length);

        for (uint256 i = 0; i < length; i++) {
            tokensData[i] = getUserTokenData(
                IAaveProtocolDataProvider(getAaveProtocolDataProvider()),
                user,
                _tokens[i]
            );
        }

        return (tokensData, getUserData(IAaveProtocolDataProvider(getAaveProtocolDataProvider()), user, _tokens, ethPrice));
    }

    function getConfiguration(address user) public view returns (bool[] memory collateral, bool[] memory borrowed) {
        IPoolAddressesProvider addrProvider = IPoolAddressesProvider(getPoolAddressProvider());
        uint256 data = getConfig(user, IPool(addrProvider.getPool())).data;
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
        IPoolddressesProvider addrProvider = IPoolAddressesProvider(getPoolAddressProvider());
        data = getList();
    }
}
