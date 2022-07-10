// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

struct LiquidityStatus {
    uint256 collateralValue;
    uint256 liabilityValue;
    uint256 numBorrows;
    bool borrowIsolated;
}

struct AssetLiquidity {
    address underlying;
    LiquidityStatus status;
}

struct AssetConfig {
    address eTokenAddress;
    bool borrowIsolated;
    uint32 collateralFactor;
    uint32 borrowFactor;
    uint24 twapWindow;
}

// Query
struct Query {
    address eulerContract;
    address account;
    address[] markets;
}

// Response
struct ResponseMarket {
    // Universal
    address underlying;
    string name;
    string symbol;
    uint8 decimals;
    address eTokenAddr;
    address dTokenAddr;
    address pTokenAddr;
    AssetConfig config;
    uint256 poolSize;
    uint256 totalBalances;
    uint256 totalBorrows;
    uint256 reserveBalance;
    uint32 reserveFee;
    uint256 borrowAPY;
    uint256 supplyAPY;
    // Pricing
    uint256 twap;
    uint256 twapPeriod;
    uint256 currPrice;
    uint16 pricingType;
    uint32 pricingParameters;
    address pricingForwarded;
    // Account specific
    uint256 underlyingBalance;
    uint256 eulerAllowance;
    uint256 eTokenBalance;
    uint256 eTokenBalanceUnderlying;
    uint256 dTokenBalance;
    LiquidityStatus liquidityStatus;
}

struct Response {
    uint256 timestamp;
    uint256 blockNumber;
    ResponseMarket[] markets;
    address[] enteredMarkets;
}

interface IEulerMarkets {
    function enterMarket(uint256 subAccountId, address newMarket) external;

    function getEnteredMarkets(address account) external view returns (address[] memory);

    function exitMarket(uint256 subAccountId, address oldMarket) external;

    function underlyingToEToken(address underlying) external view returns (address);

    function underlyingToDToken(address underlying) external view returns (address);

    function underlyingToAssetConfig(address underlying) external view returns (AssetConfig memory);

    function interestRate(address underlying) external view returns (int96);

    function reserveFee(address underlying) external view returns (uint32);
}

interface IEulerExecution {
    function detailedLiquidity(address account) external view returns (AssetLiquidity[] memory assets);

    function liquidity(address account) external view returns (LiquidityStatus memory status);

    function getPriceFull(address underlying)
        external
        view
        returns (
            uint256 twap,
            uint256 twapPeriod,
            uint256 currPrice
        );
}

interface IEToken {
    function balanceOfUnderlying(address account) external view returns (uint256);
}

interface IDToken {
    function balanceOf(address account) external view returns (uint256);
}

interface IEulerGeneralView {
    function computeAPYs(
        uint256 borrowSPY,
        uint256 totalBorrows,
        uint256 totalBalancesUnderlying,
        uint32 reserveFee
    ) external view returns (uint256 borrowAPY, uint256 supplyAPY);

    function getTotalSupplyAndDebts(address underlying)
        external
        view
        returns (
            uint256 poolSize,
            uint256 totalBalances,
            uint256 totalBorrows,
            uint256 reserveBalance
        );

    function doQueryBatch(Query[] memory qs) external view returns (Response[] memory r);

    function doQuery(Query memory q) external view returns (Response memory r);
}
