// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

enum Position {
    POOL_SUPPLIER,
    P2P_SUPPLIER,
    POOL_BORROWER,
    P2P_BORROWER
}

/* NESTED STRUCTS */

struct MarketSideDelta {
    uint256 scaledDelta; // In pool unit.
    uint256 scaledP2PTotal; // In peer-to-peer unit.
}

struct Deltas {
    MarketSideDelta supply;
    MarketSideDelta borrow;
}

struct MarketSideIndexes {
    uint128 poolIndex;
    uint128 p2pIndex;
}

struct Indexes {
    MarketSideIndexes supply;
    MarketSideIndexes borrow;
}

struct PauseStatuses {
    bool isP2PDisabled;
    bool isSupplyPaused;
    bool isSupplyCollateralPaused;
    bool isBorrowPaused;
    bool isWithdrawPaused;
    bool isWithdrawCollateralPaused;
    bool isRepayPaused;
    bool isLiquidateCollateralPaused;
    bool isLiquidateBorrowPaused;
    bool isDeprecated;
}

/* STORAGE STRUCTS */

// This market struct is able to be passed into memory.
struct Market {
    // SLOT 0-1
    Indexes indexes;
    // SLOT 2-5
    Deltas deltas; // 1024 bits
    // SLOT 6
    address underlying; // 160 bits
    PauseStatuses pauseStatuses; // 80 bits
    // SLOT 7
    address variableDebtToken; // 160 bits
    uint32 lastUpdateTimestamp; // 32 bits
    uint16 reserveFactor; // 16 bits
    uint16 p2pIndexCursor; // 16 bits
    // SLOT 8
    address aToken; // 160 bits
    // SLOT 9
    address stableDebtToken; // 160 bits
    // SLOT 10
    uint256 idleSupply; // 256 bits
}

struct Iterations {
    uint128 repay;
    uint128 withdraw;
}

/* STACK AND RETURN STRUCTS */

struct LiquidityData {
    uint256 borrowable; // The maximum debt value allowed to borrow (in base currency).
    uint256 maxDebt; // The maximum debt value allowed before being liquidatable (in base currency).
    uint256 debt; // The debt value (in base currency).
}

struct IndexesParams {
    MarketSideIndexes256 lastSupplyIndexes;
    MarketSideIndexes256 lastBorrowIndexes;
    uint256 poolSupplyIndex; // The current pool supply index.
    uint256 poolBorrowIndex; // The current pool borrow index.
    uint256 reserveFactor; // The reserve factor percentage (10 000 = 100%).
    uint256 p2pIndexCursor; // The peer-to-peer index cursor (10 000 = 100%).
    Deltas deltas; // The deltas and peer-to-peer amounts.
    uint256 proportionIdle; // in ray.
}

struct GrowthFactors {
    uint256 poolSupplyGrowthFactor; // The pool's supply index growth factor (in ray).
    uint256 p2pSupplyGrowthFactor; // Peer-to-peer supply index growth factor (in ray).
    uint256 poolBorrowGrowthFactor; // The pool's borrow index growth factor (in ray).
    uint256 p2pBorrowGrowthFactor; // Peer-to-peer borrow index growth factor (in ray).
}

struct MarketSideIndexes256 {
    uint256 poolIndex;
    uint256 p2pIndex;
}

struct Indexes256 {
    MarketSideIndexes256 supply;
    MarketSideIndexes256 borrow;
}

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct MatchingEngineVars {
    address underlying;
    MarketSideIndexes256 indexes;
    uint256 amount;
    uint256 maxIterations;
    bool borrow;
    function(address, address, uint256, uint256, bool) updateDS; // This function will be used to update the data-structure.
    bool demoting; // True for demote, False for promote.
    function(uint256, uint256, MarketSideIndexes256 memory, uint256) pure returns (uint256, uint256, uint256) step; // This function will be used to decide whether to use the algorithm for promoting or for demoting.
}

// struct LiquidityVars {
//     address user;
//     IAaveOracle oracle;
//     DataTypes.EModeCategory eModeCategory;
// }

struct PromoteVars {
    address underlying;
    uint256 amount;
    uint256 p2pIndex;
    uint256 maxIterations;
    function(address, uint256, uint256) returns (uint256, uint256) promote;
}

struct BorrowWithdrawVars {
    uint256 onPool;
    uint256 inP2P;
    uint256 toWithdraw;
    uint256 toBorrow;
}

struct SupplyRepayVars {
    uint256 onPool;
    uint256 inP2P;
    uint256 toSupply;
    uint256 toRepay;
}

struct LiquidateVars {
    uint256 closeFactor;
    uint256 seized;
}

struct AmountToSeizeVars {
    uint256 liquidationBonus;
    uint256 borrowedTokenUnit;
    uint256 collateralTokenUnit;
    uint256 borrowedPrice;
    uint256 collateralPrice;
}

// Max gas to consume during the matching process for supply, borrow, withdraw and repay functions.
struct MaxGasForMatching {
    uint64 supply;
    uint64 borrow;
    uint64 withdraw;
    uint64 repay;
}

struct AssetLiquidityData {
    uint256 collateralValue; // The collateral value of the asset.
    uint256 maxDebtValue; // The maximum possible debt value of the asset.
    uint256 debtValue; // The debt value of the asset.
    uint256 underlyingPrice; // The price of the token.
    uint256 collateralFactor; // The liquidation threshold applied on this token.
}

interface IMorphoGetter {
    function POOL() external view returns (address);

    function ADDRESSES_PROVIDER() external view returns (address);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function E_MODE_CATEGORY_ID() external view returns (uint256);

    function market(address underlying) external view returns (Market memory);

    function marketsCreated() external view returns (address[] memory);

    function scaledCollateralBalance(address underlying, address user) external view returns (uint256);

    function scaledP2PBorrowBalance(address underlying, address user) external view returns (uint256);

    function scaledP2PSupplyBalance(address underlying, address user) external view returns (uint256);

    function scaledPoolBorrowBalance(address underlying, address user) external view returns (uint256);

    function scaledPoolSupplyBalance(address underlying, address user) external view returns (uint256);

    function supplyBalance(address underlying, address user) external view returns (uint256);

    function borrowBalance(address underlying, address user) external view returns (uint256);

    function collateralBalance(address underlying, address user) external view returns (uint256);

    function userCollaterals(address user) external view returns (address[] memory);

    function userBorrows(address user) external view returns (address[] memory);

    function isManaging(address delegator, address manager) external view returns (bool);

    function userNonce(address user) external view returns (uint256);

    function defaultIterations() external view returns (Iterations memory);

    function positionsManager() external view returns (address);

    function rewardsManager() external view returns (address);

    function treasuryVault() external view returns (address);

    function isClaimRewardsPaused() external view returns (bool);

    function updatedIndexes(address underlying) external view returns (Indexes256 memory);

    function liquidityData(address user) external view returns (LiquidityData memory);

    function getNext(
        address underlying,
        Position position,
        address user
    ) external view returns (address);

    function getBucketsMask(address underlying, Position position) external view returns (uint256);
}

interface IMorpho is IMorphoGetter {}

interface IAave {
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
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

    function getRewardsData(address asset, address reward)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getRewardsList() external view returns (address[] memory);

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
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
}

interface AaveAddressProvider {
    function getLendingPool() external view returns (address);

    function getPriceOracle() external view returns (address);
}

interface AavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata _assets) external view returns (uint256[] memory);

    function getSourceOfAsset(address _asset) external view returns (uint256);

    function getFallbackOracle() external view returns (uint256);
}

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}

interface IAToken {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function totalSupply() external view returns (uint256);
}
