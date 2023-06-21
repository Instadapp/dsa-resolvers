// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Types } from "./library/Types.sol";
import { IPool } from "./library/aave-v3-core/interfaces/IPool.sol";
import { IAaveOracle } from "./library/aave-v3-core/interfaces/IAaveOracle.sol";
import { IAToken } from "./library/aave-v3-core/interfaces/IAToken.sol";
import { IERC20 } from "./library/aave-v3-core/IERC20.sol";

interface IMorpho {
    function marketsCreated() external view returns (address[] memory);

    function market(address underlying) external view returns (Types.Market memory);

    function updatedIndexes(address underlying) external view returns (Types.Indexes256 memory);

    function scaledP2PSupplyBalance(address underlying, address user) external view returns (uint256);

    function scaledPoolSupplyBalance(address underlying, address user) external view returns (uint256);

    function userCollaterals(address user) external view returns (address[] memory);

    function collateralBalance(address underlying, address user) external view returns (uint256);

    function scaledP2PBorrowBalance(address underlying, address user) external view returns (uint256);

    function scaledPoolBorrowBalance(address underlying, address user) external view returns (uint256);

    function liquidityData(address user) external view returns (Types.LiquidityData memory);

    function isClaimRewardsPaused() external view returns (bool);
}

interface IPoolDataProvider {
    // @notice Returns the reserve data
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 unbacked,
            uint256 accruedToTreasuryScaled,
            uint256 totalAToken,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );
}

interface IAaveProtocolDataProvider is IPoolDataProvider {
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

    function getPaused(address asset) external view returns (bool isPaused);

    function getLiquidationProtocolFee(address asset) external view returns (uint256);

    function getReserveEModeCategory(address asset) external view returns (uint256);

    function getReserveCaps(address asset) external view returns (uint256 borrowCap, uint256 supplyCap);

    // @notice Returns the debt ceiling of the reserve
    function getDebtCeiling(address asset) external view returns (uint256);

    // @notice Returns the debt ceiling decimals
    function getDebtCeilingDecimals() external pure returns (uint256);

    function getATokenTotalSupply(address asset) external view returns (uint256);

    function getReserveData(address asset)
        external
        view
        override
        returns (
            uint256 unbacked,
            uint256 accruedToTreasuryScaled,
            uint256 totalAToken,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}

interface AaveAddressProvider {
    function getPool() external view returns (address);

    function getPriceOracle() external view returns (address);
}

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}
