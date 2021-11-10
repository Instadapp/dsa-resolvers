// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import { DSMath } from "../../../../utils/dsmath.sol";
import "./interfaces.sol";

contract Helpers is DSMath {
    /**
     * @dev Return ethereum address
     */
    address internal constant ETHEREUM_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Return Weth address
     */
    address internal constant WETH_ADDRESS = 0x3B0B4787A01591DAf1bAc616465167e9f7DCD18e;

    /**
     * @dev Get Market Access Controller address
     */
    address internal constant MARKET_ACCESS_CONTROLLER_ADDRESS = 0xc6f769A0c46cFFa57d91E87ED3Bc0cd338Ce6361;

    /**
     * @dev Get Procolol Data Provider address
     */
    address internal constant PROTOCOL_DATA_PROVIDER_ADDRESS = 0xd25C4a0b0c088DC8d501e4292cF28da6829023c0;

    /**
     * @dev Get Chainlink ETH price feed address
     */
    address internal constant CHAINLINK_ETH_FEED_ADDRESS = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    struct UserTokenData {
        uint256 priceInETH;
        uint256 priceInUSD;
        uint256 supplyBalance;
        uint256 stableBorrowBalance;
        uint256 variableBorrowBalance;
        uint256 supplyRate;
        uint256 stableBorrowRate;
        uint256 userStableBorrowRate;
        uint256 variableBorrowRate;
        bool isCollateral;
        TokenData data;
    }

    struct TokenData {
        uint256 ltv;
        uint256 threshold;
        uint256 reserveFactor;
        bool usageAsCollateralEnabled;
        bool borrowEnabled;
        bool stableBorrrowEnabled;
        bool isActive;
        bool isFrozen;
        uint256 totalSupply;
        uint256 availableLiquidity;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
    }

    struct UserData {
        uint256 totalCollateralETH;
        uint256 totalBorrowsETH;
        uint256 availableBorrowsETH;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
        uint256 ethPriceInUsd;
        uint256 claimableRewards;
    }

    struct TokenPrice {
        uint256 priceInETH;
        uint256 priceInUSD;
    }

    /**
     * @dev Get tokens prices from Chainlink price feed
     * @param mac market access controller contract `IMarketAccessController`
     * @param tokens tokens addresses for getting prices
     */
    function getTokensPrices(IMarketAccessController mac, address[] memory tokens)
        internal
        view
        returns (TokenPrice[] memory tokenPrices, uint256 ethPrice)
    {
        uint256[] memory prices = IPriceOracle(mac.getPriceOracle()).getAssetsPrices(tokens);

        ethPrice = uint256(IChainlink(CHAINLINK_ETH_FEED_ADDRESS).latestAnswer());
        tokenPrices = new TokenPrice[](prices.length);

        for (uint256 index = 0; index < prices.length; index += 1) {
            tokenPrices[index] = TokenPrice(prices[index], wmul(prices[index], uint256(ethPrice) * 10**10));
        }
    }

    /**
     * @dev Get token data
     * @param dataProvider data provider contract `IProtocolDataProvider`
     * @param user token holder
     * @param token token address
     * @param priceInETH token price in ETH
     * @param priceInUSD token price is USD
     */
    function getTokenData(
        IProtocolDataProvider dataProvider,
        address user,
        address token,
        uint256 priceInETH,
        uint256 priceInUSD
    ) internal view returns (UserTokenData memory tokenData) {
        TokenData memory data = _getTokenData(dataProvider, token);

        (
            tokenData.supplyBalance,
            tokenData.stableBorrowBalance,
            tokenData.variableBorrowBalance,
            ,
            ,
            tokenData.userStableBorrowRate,
            ,
            ,
            tokenData.isCollateral
        ) = dataProvider.getUserReserveData(token, user);

        (
            data.availableLiquidity,
            data.totalStableDebt,
            data.totalVariableDebt,
            tokenData.supplyRate,
            tokenData.variableBorrowRate,
            tokenData.stableBorrowRate,
            ,
            ,
            ,

        ) = dataProvider.getReserveData(token);

        tokenData.priceInETH = priceInETH;
        tokenData.priceInUSD = priceInUSD;
        tokenData.data = data;
    }

    /**
     * @dev Get extended token data from configurator
     * @param dataProvider data provider contract `IProtocolDataProvider`
     * @param token token address
     */
    function _getTokenData(IProtocolDataProvider dataProvider, address token)
        private
        view
        returns (TokenData memory data)
    {
        (
            ,
            data.ltv,
            data.threshold,
            ,
            data.reserveFactor,
            data.usageAsCollateralEnabled,
            data.borrowEnabled,
            data.stableBorrrowEnabled,
            data.isActive,
            data.isFrozen
        ) = dataProvider.getReserveConfigurationData(token);
        (address depositTokenAddress, , ) = dataProvider.getReserveTokensAddresses(token);

        data.totalSupply = IToken(depositTokenAddress).totalSupply();
    }

    /**
     * @dev Get user data
     * @param pool leding pool contract `ILendingPool`
     * @param dataProvider data provider contract `IProtocolDataProvider`
     * @param user user address
     * @param ethPriceInUsd ETH price in USD
     */
    function getUserData(
        ILendingPool pool,
        IProtocolDataProvider dataProvider,
        address user,
        uint256 ethPriceInUsd
    ) internal view returns (UserData memory userData) {
        (
            userData.totalCollateralETH,
            userData.totalBorrowsETH,
            userData.availableBorrowsETH,
            userData.currentLiquidationThreshold,
            userData.ltv,
            userData.healthFactor
        ) = pool.getUserAccountData(user);
        (RewardExplained memory rewardData, ) = dataProvider.explainReward(user, 1);

        userData.claimableRewards = rewardData.amountClaimable;
        userData.ethPriceInUsd = ethPriceInUsd;
    }
}
