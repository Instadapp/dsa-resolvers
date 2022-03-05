//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract TraderJoeHelper is DSMath {
    function getJoetroller() internal view returns (address) {
        return 0xdc13687554205E5b89Ac783db14bb5bba4A1eDaC;
    }

    function getJoelens() internal view returns (address) {
        return 0xFDF50FEa3527FaD31Fa840B748FD3694aE8a47cc;
    }

    function getPriceOracle() internal view returns (address) {
        return 0xd7Ae651985a871C1BC254748c40Ecc733110BC2E;
    }

    function getWethAddress() internal view returns (address) {
        return 0x929f5caB61DFEc79a5431a7734a68D714C4633fa;
    }

    struct JoeTokenData {
        uint256 supplyRatePerSecond;
        uint256 borrowRatePerSecond;
        uint256 collateralCap;
        uint256 underlyingPrice;
        uint256 priceInETH;
        uint256 priceInUSD;
        // uint256 totalBorrows;
        // uint256 totalReserves;
        // uint256 totalSupply;
        // uint256 totalCash;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 reserveFactorMantissa;
        uint256 collateralFactorMantissa;
        uint256 jTokenDecimals;
        uint256 underlyingDecimals;
    }

    struct UserTokenData {
        address jToken;
        uint256 jTokenBalance;
        uint256 supplyBalance;
        uint256 supplyValueUSD;
        uint256 collateralValueUSD;
        uint256 borrowBalanceStored;
        uint256 borrowValueUSD;
        uint256 underlyingTokenBalance;
        uint256 underlyingTokenAllowance;
        JoeTokenData tokenData;
    }

    struct UserData {
        uint256 liquidity;
        uint256 shortfall;
        uint256 totalCollateralUSD;
        uint256 totalBorrowUSD;
        uint256 healthFactor;
        UserTokenData[] tokensData;
    }

    function getTokenPrices(JToken jToken, uint256 decimals)
        internal
        view
        returns (uint256 priceInEth, uint256 priceInUsd)
    {
        uint256 price = IPriceOracle(getPriceOracle()).getUnderlyingPrice(jToken);
        uint256 ethPrice = IPriceOracle(getPriceOracle()).getUnderlyingPrice(JToken(getWethAddress()));
        // console.log("ethPrice");
        // console.log(ethPrice);
        priceInUsd = price / 10**(18 - decimals);
        priceInEth = wdiv(priceInUsd, ethPrice);
    }

    function getTraderjoeData(address owner, address[] memory jTokens) public returns (UserData memory userData) {
        Joetroller joetroller = Joetroller(getJoetroller());
        IJoeLens joeLens = IJoeLens(getJoelens());
        AccountLimits memory account = joeLens.getAccountLimits(joetroller, owner);
        (
            userData.liquidity,
            userData.shortfall,
            userData.totalCollateralUSD,
            userData.totalBorrowUSD,
            userData.healthFactor
        ) = (
            account.liquidity,
            account.shortfall,
            account.totalCollateralValueUSD,
            account.totalBorrowValueUSD,
            account.healthFactor
        );

        UserTokenData[] memory assetData = new UserTokenData[](jTokens.length);
        assetData = getAssetData(owner, jTokens);
        userData.tokensData = assetData;
    }

    function getAssetData(address owner, address[] memory jTokens) internal returns (UserTokenData[] memory joeTokens) {
        IJoeLens joeLens = IJoeLens(getJoelens());
        joeTokens = new UserTokenData[](jTokens.length);
        for (uint256 i = 0; i < jTokens.length; i++) {
            JToken jtoken = JToken(jTokens[i]);
            JTokenBalances memory balanceData = joeLens.jTokenBalances(jtoken, owner);
            joeTokens[i] = UserTokenData(
                balanceData.jToken,
                balanceData.jTokenBalance,
                balanceData.balanceOfUnderlyingStored,
                balanceData.supplyValueUSD,
                balanceData.collateralValueUSD,
                balanceData.borrowBalanceStored,
                balanceData.borrowValueUSD,
                balanceData.underlyingTokenBalance,
                balanceData.underlyingTokenAllowance,
                getTokenData(jtoken)
            );
        }
    }

    function getTokenData(JToken jtoken) internal returns (JoeTokenData memory tokenData) {
        IJoeLens joeLens = IJoeLens(getJoelens());
        JTokenMetadata memory jData = joeLens.jTokenMetadata(jtoken);
        (uint256 priceInEth, uint256 priceInUsd) = getTokenPrices(jtoken, tokenData.underlyingDecimals);
        tokenData = JoeTokenData(
            jData.supplyRatePerSecond,
            jData.borrowRatePerSecond,
            jData.collateralCap,
            jData.underlyingPrice,
            priceInEth,
            priceInUsd,
            jData.supplyCap,
            jData.borrowCap,
            jData.reserveFactorMantissa,
            jData.collateralFactorMantissa,
            jData.jTokenDecimals,
            jData.underlyingDecimals
        );
    }
}
