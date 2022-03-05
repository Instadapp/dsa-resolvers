// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IJoetrollerV1Storage {
    enum Version {
        VANILLA,
        COLLATERALCAP,
        WRAPPEDNATIVE
    }
}
struct JTokenMetadata {
    address jToken;
    uint256 exchangeRateStored;
    uint256 supplyRatePerSecond;
    uint256 borrowRatePerSecond;
    uint256 reserveFactorMantissa;
    uint256 totalBorrows;
    uint256 totalReserves;
    uint256 totalSupply;
    uint256 totalCash;
    uint256 totalCollateralTokens;
    bool isListed;
    uint256 collateralFactorMantissa;
    address underlyingAssetAddress;
    uint256 jTokenDecimals;
    uint256 underlyingDecimals;
    IJoetrollerV1Storage.Version version;
    uint256 collateralCap;
    uint256 underlyingPrice;
    bool supplyPaused;
    bool borrowPaused;
    uint256 supplyCap;
    uint256 borrowCap;
}
struct JTokenBalances {
    address jToken;
    uint256 jTokenBalance; // Same as collateral balance - the number of jTokens held
    uint256 balanceOfUnderlyingStored; // Balance of underlying asset supplied by. Accrue interest is not called.
    uint256 supplyValueUSD;
    uint256 collateralValueUSD; // This is supplyValueUSD multiplied by collateral factor
    uint256 borrowBalanceStored; // Borrow balance without accruing interest
    uint256 borrowValueUSD;
    uint256 underlyingTokenBalance; // Underlying balance current held in user's wallet
    uint256 underlyingTokenAllowance;
    bool collateralEnabled;
}

interface JToken {
    function balanceOf(address owner) external view returns (uint256);
}
struct AccountLimits {
    JToken[] markets;
    uint256 liquidity;
    uint256 shortfall;
    uint256 totalCollateralValueUSD;
    uint256 totalBorrowValueUSD;
    uint256 healthFactor;
}

interface Joetroller {
    function getAllMarkets() external view returns (JToken[] memory);
}

interface IJoeLens {
    function jTokenMetadata(JToken jToken) external returns (JTokenMetadata memory);

    function jTokenBalances(JToken jToken, address account) external returns (JTokenBalances memory);

    function getAccountLimits(Joetroller joetroller, address account) external returns (AccountLimits memory);
}

interface IPriceOracle {
    function getUnderlyingPrice(JToken jToken) external view returns (uint256);
}
