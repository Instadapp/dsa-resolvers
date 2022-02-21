// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPool {
    struct UserConfigurationMap {
        uint256 data;
    }

    struct EModeCategory {
        // each eMode category has a custom ltv and liquidation threshold
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        // each eMode category may or may not have a custom oracle to override the individual assets price oracles
        address priceSource;
        string label;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    //user account data info
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getEModeCategoryData(uint8 id) external view returns (EModeCategory memory);

    //@return emode id of the user
    function getUserEMode(address user) external view returns (uint256);

    function getReservesList() external view virtual returns (address[] memory);

    function getUserConfiguration(address user) external view returns (UserConfigurationMap memory);

    function getReserveData(address asset) external view returns (ReserveConfigurationMap memory);
}

interface IPriceOracleGetter {
    // @notice Returns the base currency address
    // @dev Address 0x0 is reserved for USD as base currency.
    function BASE_CURRENCY() external view returns (address);

    // @notice Returns the base currency unit
    // @dev 1 ether for ETH, 1e8 for USD.
    function BASE_CURRENCY_UNIT() external view returns (uint256);

    // @notice Returns the asset price in the base currency
    function getAssetPrice(address asset) external view returns (uint256);
}

interface IAaveIncentivesController {
    //@notice returns total(accrued+non-accrued) rewards of user for given assets
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    //@notice Returns the unclaimed rewards of the user
    function getUserUnclaimedRewards(address user) external view returns (uint256);

    // @notice Returns the user index for a specific asset
    function getUserAssetData(address user, address asset) external view returns (uint256);

    // @dev Returns the configuration of the distribution for a certain asset
    // @return The asset index, the emission per second and the last updated timestamp
    function assets(address asset)
        external
        view
        returns (
            uint128,
            uint128,
            uint256
        );
}

interface IAaveOracle is IPriceOracleGetter {
    // @notice Returns a list of prices from a list of assets addresses
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

    // @notice Returns the address of the source for an asset address
    function getSourceOfAsset(address asset) external view returns (address);

    // @notice Returns the address of the fallback oracle
    function getFallbackOracle() external view returns (address);
}

interface IPoolAddressesProvider {
    // @notice Returns the address of the Pool proxy.
    function getPool() external view returns (address);

    // @notice Returns the address of the price oracle.
    function getPriceOracle() external view returns (address);

    // @notice Returns the address of the data provider.
    function getPoolDataProvider() external view returns (address);
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

interface IPriceOracle {
    // @notice Returns the asset price in the base currency
    function getAssetPrice(address asset) external view returns (uint256);
}

interface IStableDebtToken {
    // @notice Returns the stable rate of the user debt
    function getUserStableRate(address user) external view returns (uint256);
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

//chainlink price feed
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IERC20Detailed {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IUiIncentiveDataProviderV3 {
    struct AggregatedReserveIncentiveData {
        address underlyingAsset;
        IncentiveData aIncentiveData;
        IncentiveData vIncentiveData;
        IncentiveData sIncentiveData;
    }

    struct IncentiveData {
        address tokenAddress;
        address incentiveControllerAddress;
        RewardInfo[] rewardsTokenInformation;
    }

    struct RewardInfo {
        string rewardTokenSymbol;
        address rewardTokenAddress;
        address rewardOracleAddress;
        uint256 emissionPerSecond;
        uint256 incentivesLastUpdateTimestamp;
        uint256 tokenIncentivesIndex;
        uint256 emissionEndTimestamp;
        int256 rewardPriceFeed;
        uint8 rewardTokenDecimals;
        uint8 precision;
        uint8 priceFeedDecimals;
    }

    struct UserReserveIncentiveData {
        address underlyingAsset;
        UserIncentiveData aTokenIncentivesUserData;
        UserIncentiveData vTokenIncentivesUserData;
        UserIncentiveData sTokenIncentivesUserData;
    }

    struct UserIncentiveData {
        address tokenAddress;
        address incentiveControllerAddress;
        UserRewardInfo[] userRewardsInformation;
    }

    struct UserRewardInfo {
        string rewardTokenSymbol;
        address rewardOracleAddress;
        address rewardTokenAddress;
        uint256 userUnclaimedRewards;
        uint256 tokenIncentivesUserIndex;
        int256 rewardPriceFeed;
        uint8 priceFeedDecimals;
        uint8 rewardTokenDecimals;
    }

    function getReservesIncentivesData(IPoolAddressesProvider provider)
        external
        view
        returns (AggregatedReserveIncentiveData[] memory);

    function getUserReservesIncentivesData(IPoolAddressesProvider provider, address user)
        external
        view
        returns (UserReserveIncentiveData[] memory);

    // generic method with full data
    function getFullReservesIncentiveData(IPoolAddressesProvider provider, address user)
        external
        view
        returns (AggregatedReserveIncentiveData[] memory, UserReserveIncentiveData[] memory);
}

interface IRewardsDistributor {
    function getUserAssetData(
        address user,
        address asset,
        address reward
    ) external view returns (uint256);

    /**
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The incentivized asset
     * @param reward The reward token of the incentivized asset
     * @return The asset index, the emission per second, the last updated timestamp and the distribution end timestamp
     **/
    function getRewardsData(address asset, address reward)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev Returns the list of available reward token addresses of an incentivized asset
     * @param asset The incentivized asset
     * @return List of rewards addresses of the input asset
     **/
    function getRewardsByAsset(address asset) external view returns (address[] memory);

    /**
     * @dev Returns the list of available reward addresses
     * @return List of rewards supported in this contract
     **/
    function getRewardsList() external view returns (address[] memory);

    /**
     * @dev Returns a single rewards balance of an user from contract storage state, not including virtually accrued rewards since last distribution.
     * @param user The address of the user
     * @param reward The address of the reward token
     * @return Unclaimed rewards, from storage
     **/
    function getUserUnclaimedRewardsFromStorage(address user, address reward) external view returns (uint256);

    /**
     * @dev Returns a single rewards balance of an user, including virtually accrued and unrealized claimable rewards.
     * @param assets List of incentivized assets to check eligible distributions
     * @param user The address of the user
     * @param reward The address of the reward token
     * @return The rewards amount
     **/
    function getUserRewardsBalance(
        address[] calldata assets,
        address user,
        address reward
    ) external view returns (uint256);

    /**
     * @dev Returns a list all rewards of an user, including already accrued and unrealized claimable rewards
     * @param assets List of incentivized assets to check eligible distributions
     * @param user The address of the user
     * @return The function returns a Tuple of rewards list and the unclaimed rewards list
     **/
    function getAllUserRewardsBalance(address[] calldata assets, address user)
        external
        view
        returns (address[] memory, uint256[] memory);

    /**
     * @dev Returns the decimals of an asset to calculate the distribution delta
     * @param asset The address to retrieve decimals saved at storage
     * @return The decimals of an underlying asset
     */
    function getAssetDecimals(address asset) external view returns (uint8);
}

interface IRewardsController is IRewardsDistributor {
    function getRewardOracle(address reward) external view returns (address);

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);
}
