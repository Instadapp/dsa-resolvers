// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";

contract MorphoHelpers {
    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function getAaveProtocolDataProvider() internal pure returns (address) {
        return 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
    }

    function getAaveIncentivesController() internal pure returns (address) {
        return 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
    }

    struct MorphoData {
        MarketDetail[] aaveMarketsCreated;
        bool isClaimRewardsPausedAave;
    }

    struct TokenConfig {
        address poolTokenAddress;
        address underlyingToken;
        uint256 decimals;
    }

    struct AaveMarketDetail {
        uint256 aEmissionPerSecond;
        uint256 vEmissionPerSecond;
        uint256 availableLiquidity;
        uint256 liquidityRate;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
    }

    struct MarketDetail {
        TokenConfig config;
        uint256 avgSupplyRate; //in wad
        uint256 avgBorrowRate; //in wad
        uint256 p2pSupplyRate;
        uint256 p2pBorrowRate;
        uint256 poolSupplyRate;
        uint256 poolBorrowRate;
        uint256 totalP2PSupply;
        uint256 totalPoolSupply;
        uint256 totalP2PBorrows;
        uint256 totalPoolBorrows;
        uint256 poolSupplyIndex; //exchange rate of cTokens for compound
        uint256 poolBorrowIndex;
        uint256 p2pSupplyDelta; //The total amount of underlying ERC20 tokens supplied through Morpho,
        //stored as matched peer-to-peer but supplied on the underlying pool
        uint256 p2pBorrowDelta; //The total amount of underlying ERC20 tokens borrow through Morpho,
        //stored as matched peer-to-peer but borrowed from the underlying pool
        uint256 reserveFactor;
        AaveMarketDetail aaveData;
        Flags flags;
    }

    struct Flags {
        bool isPaused;
        bool isPartiallyPaused;
        bool isP2PDisabled;
    }

    struct UserMarketData {
        MarketDetail marketData;
        uint256 borrowRate;
        uint256 supplyRate;
        uint256 totalSupplies;
        uint256 totalBorrows;
        uint256 p2pBorrows;
        uint256 p2pSupplies;
        uint256 poolBorrows;
        uint256 poolSupplies;
        uint256 maxWithdrawable;
        uint256 maxBorrowable;
    }

    struct UserData {
        uint256 healthFactor; //calculated by updating interest accrue indices for all markets
        uint256 collateralValue; //calculated by updating interest accrue indices for all markets
        uint256 debtValue; //calculated by updating interest accrue indices for all markets
        uint256 maxDebtValue; //calculated by updating interest accrue indices for all markets
        bool isLiquidatable;
        uint256 liquidationThreshold;
        UserMarketData[] marketData;
    }

    IAaveLens internal aavelens = IAaveLens(0x507fA343d0A90786d86C7cd885f5C49263A91FF4);
    IMorpho internal aaveMorpho = IMorpho(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);
    IAave internal protocolData = IAave(getAaveProtocolDataProvider());
    IAave internal incentiveData = IAave(getAaveIncentivesController());

    function getLiquidatyData(
        MarketDetail memory marketData_,
        address poolTokenAddress_,
        address asset
    ) internal view returns (MarketDetail memory) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            marketData_.aaveData.ltv,
            marketData_.aaveData.liquidationThreshold,
            marketData_.aaveData.liquidationBonus,

        ) = aavelens.getMarketConfiguration(poolTokenAddress_);

        (, , address vToken_) = protocolData.getReserveTokensAddresses(asset);

        (, marketData_.aaveData.aEmissionPerSecond, ) = incentiveData.getAssetData(asset);
        (, marketData_.aaveData.vEmissionPerSecond, ) = incentiveData.getAssetData(vToken_);
        (marketData_.aaveData.availableLiquidity, , , marketData_.aaveData.liquidityRate, , , , , , ) = protocolData
            .getReserveData(asset);
        return marketData_;
    }

    function getAaveMarketData(MarketDetail memory marketData_, address poolTokenAddress_)
        internal
        view
        returns (MarketDetail memory)
    {
        marketData_.config.poolTokenAddress = poolTokenAddress_;
        (
            marketData_.config.underlyingToken,
            ,
            marketData_.flags.isP2PDisabled,
            marketData_.flags.isPaused,
            marketData_.flags.isPartiallyPaused,
            marketData_.reserveFactor,
            ,
            ,
            ,
            ,
            marketData_.config.decimals
        ) = aavelens.getMarketConfiguration(poolTokenAddress_);

        marketData_ = getLiquidatyData(marketData_, poolTokenAddress_, marketData_.config.underlyingToken);

        return marketData_;
    }

    function getMarketData(address poolTokenAddress) internal view returns (MarketDetail memory marketData_) {
        marketData_ = getAaveMarketData(marketData_, poolTokenAddress);

        (
            marketData_.avgSupplyRate,
            marketData_.avgBorrowRate,
            marketData_.totalP2PSupply,
            marketData_.totalP2PBorrows,
            marketData_.totalPoolSupply,
            marketData_.totalPoolBorrows
        ) = aavelens.getMainMarketData(poolTokenAddress);

        (
            marketData_.p2pSupplyRate,
            marketData_.p2pBorrowRate,
            marketData_.poolSupplyRate,
            marketData_.poolBorrowRate
        ) = aavelens.getRatesPerYear(poolTokenAddress);

        (
            ,
            ,
            marketData_.poolSupplyIndex,
            marketData_.poolBorrowIndex,
            ,
            marketData_.p2pSupplyDelta,
            marketData_.p2pBorrowDelta
        ) = aavelens.getAdvancedMarketData(poolTokenAddress);
    }

    function getUserMarketData(address user, address poolTokenAddress)
        internal
        view
        returns (UserMarketData memory userMarketData_)
    {
        userMarketData_.marketData = getMarketData(poolTokenAddress);
        (userMarketData_.poolBorrows, userMarketData_.p2pBorrows, userMarketData_.totalBorrows) = aavelens
            .getCurrentBorrowBalanceInOf(poolTokenAddress, user);
        (userMarketData_.poolSupplies, userMarketData_.p2pSupplies, userMarketData_.totalSupplies) = aavelens
            .getCurrentSupplyBalanceInOf(poolTokenAddress, user);
        userMarketData_.borrowRate = aavelens.getCurrentUserBorrowRatePerYear(poolTokenAddress, user);
        userMarketData_.supplyRate = aavelens.getCurrentUserSupplyRatePerYear(poolTokenAddress, user);

        (userMarketData_.maxWithdrawable, userMarketData_.maxBorrowable) = aavelens.getUserMaxCapacitiesForAsset(
            user,
            poolTokenAddress
        );
    }

    function getUserMarkets(address user) internal view returns (address[] memory userMarkets_) {
        userMarkets_ = aavelens.getEnteredMarkets(user);
    }

    function getUserData(address user, address[] memory poolTokenAddresses)
        internal
        view
        returns (UserData memory userData_)
    {
        uint256 length_ = poolTokenAddresses.length;

        UserMarketData[] memory marketData_ = new UserMarketData[](length_);
        for (uint256 i = 0; i < length_; i++) {
            marketData_[i] = getUserMarketData(user, poolTokenAddresses[i]);
        }

        userData_.marketData = marketData_;
        // uint256 unclaimedRewards;

        userData_.healthFactor = aavelens.getUserHealthFactor(user);
        (
            userData_.collateralValue,
            userData_.maxDebtValue,
            userData_.liquidationThreshold,
            userData_.debtValue
        ) = aavelens.getUserBalanceStates(user);
        userData_.isLiquidatable = aavelens.isLiquidatable(user);
    }

    function getMorphoData() internal view returns (MorphoData memory morphoData_) {
        address[] memory aaveMarkets_ = aavelens.getAllMarkets();
        MarketDetail[] memory aaveMarket_ = new MarketDetail[](aaveMarkets_.length);

        uint256 length_ = aaveMarkets_.length;
        for (uint256 i = 0; i < length_; i++) {
            aaveMarket_[i] = getMarketData(aaveMarkets_[i]);
        }

        morphoData_.aaveMarketsCreated = aaveMarket_;

        morphoData_.isClaimRewardsPausedAave = aaveMorpho.isClaimRewardsPaused();
    }
}
