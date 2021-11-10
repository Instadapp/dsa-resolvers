// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IProtocolDataProvider {
    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentDepositBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scalaedVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address depositTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function explainReward(address user, uint32 at) external view returns (RewardExplained memory, uint32);
}

struct RewardExplained {
    uint256 amountClaimable;
    uint256 amountExtra;
    uint256 maxBoost;
    uint256 boostLimit;
    uint32 latestClaimAt;
    RewardExplainedEntry[] allocations;
}

struct RewardExplainedEntry {
    uint256 amount;
    uint256 extra;
    address pool;
    uint32 since;
    uint32 factor;
    RewardType rewardType;
}

enum RewardType {
    WorkReward,
    BoostReward
}

interface ILendingPool {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface IToken {
    function totalSupply() external view returns (uint256);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}

interface IMarketAccessController {
    function getLendingPool() external view returns (address);

    function getPriceOracle() external view returns (address);
}

interface IPriceOracle {
    function geAssetPrice(address asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

    function getSourceOfAsset(address asset) external view returns (uint256);

    function getFallbackOracle() external view returns (uint256);
}
