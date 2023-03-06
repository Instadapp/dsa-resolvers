// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import { DSMath } from "../../../../utils/dsmath.sol";

contract MorphoHelpers is DSMath {
    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function getAWethAddr() internal pure returns (address) {
        return 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    }

    function getChainlinkEthFeed() internal pure returns (address) {
        return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    }

    function getAaveProtocolDataProvider() internal pure returns (address) {
        return 0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3;
    }

    function getAaveIncentivesController() internal pure returns (address) {
        return 0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb; // should be updated after deployment
    }

    struct MorphoData {
        MarketDetail[] aaveMarketsCreated;
        bool isClaimRewardsPausedAave;
        uint256 p2pSupplyAmount;
        uint256 p2pBorrowAmount;
        uint256 poolSupplyAmount;
        uint256 poolBorrowAmount;
        uint256 totalSupplyAmount;
        uint256 totalBorrowAmount;
    }

    struct TokenConfig {
        // address poolTokenAddress;
        // address underlyingToken;
        uint256 decimals;
        uint256 tokenPriceInEth;
        uint256 tokenPriceInUsd;
    }

    struct AaveMarketDetail {
        address[] rewardsList;
        uint256[] aEmissionPerSecond;
        uint256[] sEmissionPerSecond;
        uint256[] vEmissionPerSecond;
        uint256 availableLiquidity;
        uint256 liquidityRate;
        // uint256 ltv;
        // uint256 liquidationThreshold;
        // uint256 liquidationBonus;
        uint256 totalSupplies;
        uint256 totalStableBorrows;
        uint256 totalVariableBorrows;
    }

    struct MarketDetail {
        TokenConfig config;
        // uint256 avgSupplyRatePerYear; //in wad
        // uint256 avgBorrowRatePerYear; //in wad
        // uint256 p2pSupplyRate;
        // uint256 p2pBorrowRate;
        // uint256 poolSupplyRate;
        // uint256 poolBorrowRate;
        // uint256 totalP2PSupply;
        // uint256 totalPoolSupply;
        // uint256 totalP2PBorrows;
        // uint256 totalPoolBorrows;
        // uint256 p2pSupplyIndex;
        // uint256 p2pBorrowIndex;
        // uint256 poolSupplyIndex; //exchange rate of cTokens for compound
        // uint256 poolBorrowIndex;

        Market market;
        AaveMarketDetail aaveData;
    }

    struct Flags {
        bool isCreated;
        bool isPaused;
        bool isPartiallyPaused;
        bool isP2PDisabled;
        bool isUnderlyingBorrowEnabled;
    }

    struct UserMarketData {
        MarketDetail marketData;
        // uint256 borrowRatePerYear;
        // uint256 supplyRatePerYear;
        uint256 totalSupplies;
        uint256 totalBorrows;
        uint256 p2pBorrows;
        uint256 p2pSupplies;
        uint256 poolBorrows;
        uint256 poolSupplies;
        // uint256 maxWithdrawable;
        // uint256 maxBorrowable;
    }

    struct UserData {
        uint256 borrowable;
        uint256 debt; //calculated by updating interest accrue indices for all markets
        uint256 maxDebt; //calculated by updating interest accrue indices for all markets
        // bool isLiquidatable;
        // uint256 liquidationThreshold;
        UserMarketData[] marketData;
        uint256 ethPriceInUsd;
        uint256 suppliedValue;
    }

    struct TokenPrice {
        uint256 priceInEth;
        uint256 priceInUsd;
    }

    IMorphoGetter internal morphoGetter = IMorphoGetter(0x507fA343d0A90786d86C7cd885f5C49263A91FF4);
    IMorpho internal aaveMorpho = IMorpho(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);
    AaveAddressProvider addrProvider = AaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    IAave internal protocolData = IAave(getAaveProtocolDataProvider());
    IAave internal incentiveData = IAave(getAaveIncentivesController());

    function getTokensPrices(AaveAddressProvider aaveAddressProvider, address[] memory tokens)
        internal
        view
        returns (TokenPrice[] memory tokenPrices, uint256 ethPrice)
    {
        uint256[] memory _tokenPrices = AavePriceOracle(aaveAddressProvider.getPriceOracle()).getAssetsPrices(tokens);
        ethPrice = uint256(ChainLinkInterface(getChainlinkEthFeed()).latestAnswer());
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(_tokenPrices[i], wmul(_tokenPrices[i], uint256(ethPrice) * 10**10));
        }
    }

    function getLiquidatyData(MarketDetail memory marketData_, address asset)
        internal
        view
        returns (MarketDetail memory)
    {
        (, address sToken_, address vToken_) = protocolData.getReserveTokensAddresses(asset);

        marketData_.aaveData.rewardsList = incentiveData.getRewardsList();
        marketData_.aaveData.aEmissionPerSecond = new uint256[](marketData_.aaveData.rewardsList.length);
        marketData_.aaveData.sEmissionPerSecond = new uint256[](marketData_.aaveData.rewardsList.length);
        marketData_.aaveData.vEmissionPerSecond = new uint256[](marketData_.aaveData.rewardsList.length);

        for (uint256 i = 0; i < marketData_.aaveData.rewardsList.length; i++) {
            (, marketData_.aaveData.aEmissionPerSecond[i], , ) = incentiveData.getRewardsData(
                asset,
                marketData_.aaveData.rewardsList[i]
            );
            (, marketData_.aaveData.sEmissionPerSecond[i], , ) = incentiveData.getRewardsData(
                sToken_,
                marketData_.aaveData.rewardsList[i]
            );
            (, marketData_.aaveData.vEmissionPerSecond[i], , ) = incentiveData.getRewardsData(
                vToken_,
                marketData_.aaveData.rewardsList[i]
            );
        }

        (
            marketData_.aaveData.availableLiquidity,
            marketData_.aaveData.totalStableBorrows,
            marketData_.aaveData.totalVariableBorrows,
            marketData_.aaveData.liquidityRate,
            ,
            ,
            ,
            ,
            ,

        ) = protocolData.getReserveData(asset);
        return marketData_;
    }

    function getAaveHelperData(MarketDetail memory marketData_, address poolTokenAddress_)
        internal
        view
        returns (MarketDetail memory)
    {
        marketData_.aaveData.totalSupplies = IAToken(poolTokenAddress_).totalSupply();
        return marketData_;
    }

    function getAaveMarketData(
        MarketDetail memory marketData_,
        address underlying,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (MarketDetail memory) {
        marketData_.market = morphoGetter.market(underlying);
        // marketData_.config.poolTokenAddress = marketData_.market.aToken;
        marketData_.config.tokenPriceInEth = priceInEth;
        marketData_.config.tokenPriceInUsd = priceInUsd;

        marketData_ = getLiquidatyData(marketData_, marketData_.market.aToken);
        marketData_ = getAaveHelperData(marketData_, marketData_.market.aToken);

        return marketData_;
    }

    function getMarketData(
        address underlying,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (MarketDetail memory marketData_) {
        marketData_ = getAaveMarketData(marketData_, underlying, priceInEth, priceInUsd);

        //////////////////////////////////////////////////////
        // (
        //     marketData_.avgSupplyRatePerYear,
        //     marketData_.avgBorrowRatePerYear,
        //     marketData_.totalP2PSupply,
        //     marketData_.totalP2PBorrows,
        //     marketData_.totalPoolSupply,
        //     marketData_.totalPoolBorrows
        // ) = morphoGetter.getMainMarketData(underlying);

        // (
        //     marketData_.p2pSupplyRate,
        //     marketData_.p2pBorrowRate,
        //     marketData_.poolSupplyRate,
        //     marketData_.poolBorrowRate
        // ) = morphoGetter.getRatesPerYear(underlying);

        // (
        //     marketData_.p2pSupplyIndex,
        //     marketData_.p2pBorrowIndex,
        //     marketData_.poolSupplyIndex,
        //     marketData_.poolBorrowIndex,
        //     marketData_.lastUpdateTimestamp,
        //     marketData_.p2pSupplyDelta,
        //     marketData_.p2pBorrowDelta
        // ) = morphoGetter.getAdvancedMarketData(underlying);
        ///////////////////////////////////////////////////////
    }

    function getUserMarketData(
        address user,
        address underlying,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (UserMarketData memory userMarketData_) {
        userMarketData_.marketData = getMarketData(underlying, priceInEth, priceInUsd);

        userMarketData_.p2pBorrows = morphoGetter.scaledP2PBorrowBalance(underlying, user);
        userMarketData_.poolBorrows = morphoGetter.scaledPoolBorrowBalance(underlying, user);
        userMarketData_.totalBorrows = morphoGetter.borrowBalance(underlying, user);

        userMarketData_.p2pSupplies = morphoGetter.scaledP2PSupplyBalance(underlying, user);
        userMarketData_.poolSupplies = morphoGetter.scaledPoolSupplyBalance(underlying, user);
        userMarketData_.totalSupplies = morphoGetter.supplyBalance(underlying, user);

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // userMarketData_.borrowRatePerYear = morphoGetter.getCurrentUserBorrowRatePerYear(underlying, user);
        // userMarketData_.supplyRatePerYear = morphoGetter.getCurrentUserSupplyRatePerYear(underlying, user);

        // (userMarketData_.maxWithdrawable, userMarketData_.maxBorrowable) = morphoGetter.getUserMaxCapacitiesForAsset(
        //     user,
        //     underlying
        // );
        //////////////////////////////////////////////////////////////////////////////////////////////////
    }

    // function getUserMarkets(address user) internal view returns (address[] memory userMarkets_) {
    //     // address[] memory totalMarkets = morphoGetter.marketsCreated();
    //     // for (uint256 i = 0; i < totalMarkets.length; i++) {
    //     //     (MarketSideIndexes256 memory supply, MarketSideIndexes256 memory borrow)
    //     //     = morphoGetter.updatedIndexes(totalMarkets[i]);
    //     // }
    //     userMarkets_ = morphoGetter.marketsCreated();
    // }

    function getUserData(address user, address[] memory underlyingList)
        internal
        view
        returns (UserData memory userData_)
    {
        uint256 length_ = underlyingList.length;

        UserMarketData[] memory marketData_ = new UserMarketData[](length_);
        (TokenPrice[] memory tokenPrices, uint256 ethPrice) = getTokensPrices(addrProvider, underlyingList);

        ///////////////////////////////////////////
        for (uint256 i = 0; i < length_; i++) {
            marketData_[i] = getUserMarketData(
                user,
                underlyingList[i],
                tokenPrices[i].priceInEth,
                tokenPrices[i].priceInUsd
            );
        }
        ///////////////////////////////////////////

        userData_.marketData = marketData_;
        LiquidityData memory data = morphoGetter.liquidityData(user);
        userData_.borrowable = data.borrowable;
        userData_.maxDebt = data.maxDebt;
        userData_.debt = data.debt;

        userData_.ethPriceInUsd = ethPrice;
    }

    function getMorphoData() internal view returns (MorphoData memory morphoData_) {
        address[] memory tokens_ = morphoGetter.marketsCreated();

        MarketDetail[] memory aaveMarket_ = new MarketDetail[](tokens_.length);
        uint256 length_ = tokens_.length;

        (TokenPrice[] memory tokenPrices, ) = getTokensPrices(addrProvider, tokens_);

        for (uint256 i = 0; i < length_; i++) {
            aaveMarket_[i] = getMarketData(tokens_[i], tokenPrices[i].priceInEth, tokenPrices[i].priceInUsd);
        }

        morphoData_.aaveMarketsCreated = aaveMarket_;

        morphoData_.isClaimRewardsPausedAave = morphoGetter.isClaimRewardsPaused();
        // (morphoData_.p2pSupplyAmount, morphoData_.poolSupplyAmount, morphoData_.totalSupplyAmount) = morphoGetter
        //     .getTotalSupply();
        // (morphoData_.p2pBorrowAmount, morphoData_.poolBorrowAmount, morphoData_.totalBorrowAmount) = morphoGetter
        //     .getTotalBorrow();
    }
}
