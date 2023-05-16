// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import "./helpers.sol";

/**
 *@title Spark Resolver
 *@dev get user position, user configuration & reserves list.
 */
contract SparkResolver is SparkHelper {
    /**
     * @dev get position of the user
     * @notice get position of user, including details of user's 
     overall position, rewards and assets owned for the tokens passed.
     * @param user The address of the user whose details are needed.
     * @param tokens Array of token addresses corresponding to which user details are needed.
     * @return SparkUserData user's overall position (e.g. total collateral, total borrows, e-mode id etc.).
     * @return SparkUserTokenData details of user's tokens for the tokens passed 
     (e.g. supplied amount, borrowed amount, supply rate etc.).
     * @return SparkTokenData details of tokens (e.g. symbol, decimals, ltv etc.).
     * @return ReserveIncentiveData details of user's rewards corresponding to the tokens passed.
     */
    function getPosition(address user, address[] memory tokens)
        public
        view
        returns (
            SparkUserData memory,
            SparkUserTokenData[] memory,
            SparkTokenData[] memory,
            ReserveIncentiveData[] memory
        )
    {
        uint256 length = tokens.length;
        address[] memory _tokens = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            _tokens[i] = tokens[i] == getEthAddr() ? getWethAddr() : tokens[i];
        }

        SparkUserData memory userDetails = getUserData(user);

        SparkUserTokenData[] memory tokensData = new SparkUserTokenData[](length);
        SparkTokenData[] memory collData = new SparkTokenData[](length);

        for (uint256 i = 0; i < length; i++) {
            tokensData[i] = getUserTokenData(user, _tokens[i]);
            collData[i] = userCollateralData(_tokens[i]);
        }

        return (userDetails, tokensData, collData, getIncentivesInfo(user));
    }

    /**
     * @dev get position of the user for all tokens.
     * @notice get position of user, including details of user's 
     overall position, rewards and assets owned for all tokens available in market.
     * @param user The address of the user whose details are needed.
     * @return SparkUserData user's overall position (e.g. total collateral, total borrows, e-mode id etc.).
     * @return SparkUserTokenData user's details of tokens(e.g. supplied amount, borrowed amount, supply rate etc.).
     * @return SparkTokenData details of tokens (e.g. symbol, decimals, ltv etc.).
     * @return ReserveIncentiveData details of user's rewards corresponding to the tokens in the market.
     */
    function getPositionAll(address user)
        public
        view
        returns (
            SparkUserData memory,
            SparkUserTokenData[] memory,
            SparkTokenData[] memory,
            ReserveIncentiveData[] memory
        )
    {
        return getPosition(user, getList());
    }

    /**
     * @dev get user's configuration.
     * @notice get configuration of user, whether the token is used as collateral or borrowed or not.
     * @param user The address of the user whose configuration is needed.
     * @return collateral array with an element as true if 
     the corresponding token is used as collateral by the user, false otherwise.
     * @return borrowed array with an element as true if 
     the corresponding token is borrowed by the user, false otherwise.
     */
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

    /**
     * @dev get reserves list.
     * @notice get list of all tokens available in the market.
     * @return data array of token addresses available in the market.
     */
    function getReservesList() public view returns (address[] memory data) {
        data = getList();
    }
}

contract InstaSparkResolver is SparkResolver {
    string public constant name = "Spark-Resolver-v1.0";
}
