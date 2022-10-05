// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract MorphoHelpers is DSMath {
    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function getAaveLens() internal pure returns (address) {
        return 0x507fA343d0A90786d86C7cd885f5C49263A91FF4;
    }

    function getCompoundLens() internal pure returns (address) {
        return 0x930f1b46e1D081Ec1524efD95752bE3eCe51EF67;
    }

    function getCompMorpho() internal pure returns (address) {
        return 0x8888882f8f843896699869179fB6E4f7e3B58888;
    }

    function getAaveMorpho() internal pure returns (address) {
        return 0x777777c9898D384F785Ee44Acfe945efDFf5f3E0;
    }

    function getAaveProtocolDataProvider() internal pure returns (address) {
        return 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
    }

    function getAaveIncentivesController() internal pure returns (address) {
        return 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
    }

    function getComptroller() internal pure returns (address) {
        return 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    }

    enum Underlying {
        AAVEV2,
        COMPOUNDV2
    }

    struct MorphoData {
        MarketDetail[] aaveMarketsCreated;
        MarketDetail[] compMarketsCreated;
        bool isClaimRewardsPausedAave;
        bool isClaimRewardsPausedComp;
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

    struct CompoundMarketDetail {
        uint256 compSpeed;
        uint256 compSupplySpeed;
        uint256 compBorrowSpeed;
        uint256 collateralFactor;
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
        CompoundMarketDetail compData;
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
        uint256 healthFactor; //calculated by updating interest accrue indices for all markets for comp
        uint256 collateralValue; //calculated by updating interest accrue indices for all markets for comp
        uint256 debtValue; //calculated by updating interest accrue indices for all markets for comp
        uint256 maxDebtValue; //calculated by updating interest accrue indices for all markets for comp
        bool isLiquidatable;
        uint256 liquidationThreshold; //for AAVE
        uint256 unclaimedRewards; //only for compound as of now
        UserMarketData[] marketData;
    }

    IAaveLens internal aavelens = IAaveLens(getAaveLens());
    ICompoundLens internal compLens = ICompoundLens(getCompoundLens());
    IMorpho internal aaveMorpho = IMorpho(getAaveMorpho());
    IMorpho internal compMorpho = IMorpho(getCompMorpho());
    IAave internal protocolData = IAave(getAaveProtocolDataProvider());
    IAave internal incentiveData = IAave(getAaveIncentivesController());
    IComp internal comptroller = IComp(getComptroller());

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

    function getCompSpeeds(CompoundMarketDetail memory cf_, address poolTokenAddress_)
        internal
        view
        returns (CompoundMarketDetail memory)
    {
        cf_.compSpeed = comptroller.compSpeeds(poolTokenAddress_);
        cf_.compSupplySpeed = comptroller.compSupplySpeeds(poolTokenAddress_);
        cf_.compBorrowSpeed = comptroller.compBorrowSpeeds(poolTokenAddress_);
        return cf_;
    }

    function getCompMarketData(MarketDetail memory marketData_, address poolTokenAddress_)
        internal
        view
        returns (MarketDetail memory)
    {
        TokenConfig memory tokenData_;
        CompoundMarketDetail memory cf_;
        Flags memory flags_;

        tokenData_.poolTokenAddress = poolTokenAddress_;
        tokenData_.decimals = TokenInterface(poolTokenAddress_).decimals();
        (
            tokenData_.underlyingToken,
            ,
            flags_.isP2PDisabled,
            flags_.isPaused,
            flags_.isPartiallyPaused,
            marketData_.reserveFactor,
            ,
            cf_.collateralFactor
        ) = compLens.getMarketConfiguration(poolTokenAddress_);

        cf_ = getCompSpeeds(cf_, poolTokenAddress_);

        marketData_.config = tokenData_;
        marketData_.compData = cf_;
        marketData_.flags = flags_;

        return marketData_;
    }

    function getMarketData(Underlying pool, address poolTokenAddress)
        internal
        view
        returns (MarketDetail memory marketData_)
    {
        ILens lens_ = pool == Underlying.AAVEV2 ? ILens(getAaveLens()) : ILens(getCompoundLens());
        if (pool == Underlying.AAVEV2) {
            marketData_ = getAaveMarketData(marketData_, poolTokenAddress);
        } else {
            marketData_ = getCompMarketData(marketData_, poolTokenAddress);
        }
        (
            marketData_.avgSupplyRate,
            marketData_.avgBorrowRate,
            marketData_.totalP2PSupply,
            marketData_.totalP2PBorrows,
            marketData_.totalPoolSupply,
            marketData_.totalPoolBorrows
        ) = lens_.getMainMarketData(poolTokenAddress);

        (
            marketData_.p2pSupplyRate,
            marketData_.p2pBorrowRate,
            marketData_.poolSupplyRate,
            marketData_.poolBorrowRate
        ) = (pool == Underlying.AAVEV2)
            ? aavelens.getRatesPerYear(poolTokenAddress)
            : compLens.getRatesPerBlock(poolTokenAddress);

        (
            ,
            ,
            marketData_.poolSupplyIndex,
            marketData_.poolBorrowIndex,
            ,
            marketData_.p2pSupplyDelta,
            marketData_.p2pBorrowDelta
        ) = pool == Underlying.AAVEV2
            ? aavelens.getAdvancedMarketData(poolTokenAddress)
            : compLens.getAdvancedMarketData(poolTokenAddress);
    }

    function getUserMarketData(
        address user,
        address poolTokenAddress,
        Underlying pool
    ) internal view returns (UserMarketData memory userMarketData_) {
        ILens lens_ = pool == Underlying.AAVEV2 ? ILens(getAaveLens()) : ILens(getCompoundLens());
        userMarketData_.marketData = getMarketData(pool, poolTokenAddress);
        if (pool == Underlying.AAVEV2) {
            (userMarketData_.poolBorrows, userMarketData_.p2pBorrows, userMarketData_.totalBorrows) = aavelens
                .getCurrentBorrowBalanceInOf(poolTokenAddress, user);
            (userMarketData_.poolSupplies, userMarketData_.p2pSupplies, userMarketData_.totalSupplies) = aavelens
                .getCurrentSupplyBalanceInOf(poolTokenAddress, user);
            userMarketData_.borrowRate = aavelens.getCurrentUserBorrowRatePerYear(poolTokenAddress, user);
            userMarketData_.supplyRate = aavelens.getCurrentUserSupplyRatePerYear(poolTokenAddress, user);
        } else {
            (userMarketData_.p2pBorrows, userMarketData_.poolBorrows, userMarketData_.totalBorrows) = compLens
                .getCurrentBorrowBalanceInOf(poolTokenAddress, user);
            (userMarketData_.p2pSupplies, userMarketData_.poolSupplies, userMarketData_.totalSupplies) = compLens
                .getCurrentSupplyBalanceInOf(poolTokenAddress, user);
            userMarketData_.borrowRate = compLens.getCurrentUserBorrowRatePerBlock(poolTokenAddress, user);
            userMarketData_.supplyRate = compLens.getCurrentUserSupplyRatePerBlock(poolTokenAddress, user);
        }
        (userMarketData_.maxWithdrawable, userMarketData_.maxBorrowable) = lens_.getUserMaxCapacitiesForAsset(
            user,
            poolTokenAddress
        );
    }

    function getUserMarkets(address user, Underlying pool) internal view returns (address[] memory userMarkets_) {
        ILens lens_ = pool == Underlying.AAVEV2 ? ILens(getAaveLens()) : ILens(getCompoundLens());
        userMarkets_ = lens_.getEnteredMarkets(user);
    }

    function getUserData(
        address user,
        address[] memory poolTokenAddresses,
        Underlying pool
    ) internal view returns (UserData memory userData_) {
        uint256 length_ = poolTokenAddresses.length;

        UserMarketData[] memory marketData_ = new UserMarketData[](length_);
        for (uint256 i = 0; i < length_; i++) {
            marketData_[i] = getUserMarketData(user, poolTokenAddresses[i], pool);
        }

        userData_.marketData = marketData_;
        // uint256 unclaimedRewards;
        address[] memory userMarkets_ = getUserMarkets(user, pool);

        if (pool == Underlying.AAVEV2) {
            userData_.healthFactor = aavelens.getUserHealthFactor(user);
            (
                userData_.collateralValue,
                userData_.maxDebtValue,
                userData_.liquidationThreshold,
                userData_.debtValue
            ) = aavelens.getUserBalanceStates(user);
            userData_.isLiquidatable = aavelens.isLiquidatable(user);
        } else {
            userData_.healthFactor = compLens.getUserHealthFactor(user, userMarkets_);
            (userData_.collateralValue, userData_.debtValue, userData_.maxDebtValue) = compLens.getUserBalanceStates(
                user,
                userMarkets_
            );
            userData_.isLiquidatable = compLens.isLiquidatable(user, userMarkets_);
            userData_.unclaimedRewards = compLens.getUserUnclaimedRewards(userMarkets_, user);
        }
    }

    function getMorphoData() internal view returns (MorphoData memory morphoData_) {
        ILens aaveLens_ = ILens(getAaveLens());
        ILens compLens_ = ILens(getCompoundLens());
        address[] memory aaveMarkets_ = aaveLens_.getAllMarkets();
        address[] memory compMarkets_ = compLens_.getAllMarkets();
        MarketDetail[] memory aaveMarket_ = new MarketDetail[](aaveMarkets_.length);
        MarketDetail[] memory compMarket_ = new MarketDetail[](compMarkets_.length);

        uint256 length_ = aaveMarkets_.length;
        for (uint256 i = 0; i < length_; i++) {
            aaveMarket_[i] = getMarketData(Underlying.AAVEV2, aaveMarkets_[i]);
        }
        length_ = compMarkets_.length;
        for (uint256 i = 0; i < length_; i++) {
            compMarket_[i] = getMarketData(Underlying.COMPOUNDV2, compMarkets_[i]);
        }

        morphoData_.aaveMarketsCreated = aaveMarket_;
        morphoData_.compMarketsCreated = compMarket_;

        morphoData_.isClaimRewardsPausedAave = aaveMorpho.isClaimRewardsPaused();
        morphoData_.isClaimRewardsPausedComp = compMorpho.isClaimRewardsPaused();
    }
}
