// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract Helpers is DSMath {
    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function getCometRewardsAddress() internal pure returns (address) {
        return 0x1B0e765F6224C21223AeA2af16c1C46E38885a40;
    }

    function getConfiguratorAddress() internal pure returns (address) {
        return 0xcFC1fA6b7ca982176529899D99af6473aD80DF4F;
    }

    //
    struct BaseAssetInfo {
        address token;
        address priceFeed;
        uint256 price;
        uint8 decimals;
        uint64 mantissa;
        uint64 indexScale;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
    }
    //
    struct Scales {
        //liquidation factor, borrow factor scale
        uint64 factorScale;
        //scale for USD prices
        uint64 priceScale;
        //scale for rewards APR
        uint64 trackingIndexScale;
    }
    //
    struct Token {
        uint8 offset;
        address token;
        string symbol;
        uint256 decimals;
    }
    //
    struct AssetData {
        Token token;
        address priceFeed;
        uint256 price;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 totalCollateral;
        uint128 supplyCap;
        uint128 totalCollateral;
    }

    struct AccountFlags {
        bool isLiquidatable;
        bool isBorrowCollaterized;
    }

    //
    struct MarketFlags {
        bool isAbsorbPaused;
        bool isBuyPaused;
        bool isSupplyPaused;
        bool isTransferPaused;
        bool isWithdrawPaused;
    }

    struct UserCollateralData {
        Token token;
        uint256 suppliedBalance;
    }
    //
    struct RewardsConfig {
        address token;
        uint64 rescaleFactor;
        bool shouldUpScale;
        uint104 baseMinForRewards;
    }

    struct UserRewardsData {
        address rewardToken;
        uint256 amountOwed;
        uint256 amountClaimed;
    }

    struct UserData {
        int104 baseBalance;
        //the base balance of supplies with interest, 0 for borrowing case or no supplies
        uint256 suppliedBalance;
        //the borrow base balance including interest, for non-negative base asset balance value is 0
        uint256 borrowedBalance;
        uint16 assetsIn;
        uint64 accountTrackingIndex;
        uint64 interestAccrued;
        uint256 userNonce;
        int256 borrowableAmount;
        uint256 rewardsAccrued;
        UserRewardsData rewards;
        AccountFlags flags;
    }
    //
    struct MarketConfig {
        uint8 assetCount;
        uint64 supplyRate;
        uint64 borrowRate;
        //for rewards APR calculation
        uint64 baseTrackingSupplySpeed;
        uint64 baseTrackingBorrowSpeed;
        //total protocol reserves
        int256 reserves;
        uint64 storeFrontPriceFactor;
        uint104 baseBorrowMin;
        //amount of reserves allowed before absorbed collateral is no longer sold by the protocol
        uint104 targetReserves;
        uint104 totoalSupplyBase;
        uint104 totalBorrowBase;
        uint256 utilization;
        BaseAssetInfo baseToken;
        Scales scales;
        RewardsConfig rewardConfig;
        AssetData[] assets;
    }

    ICometRewards internal cometRewards = ICometRewards(getCometRewardsAddress());
    ICometConfig internal cometConfig = ICometConfig(getConfiguratorAddress());

    function getBaseTokenInfo(IComet _comet) internal view returns (BaseAssetInfo memory baseAssetInfo) {
        baseAssetInfo.token = _comet.baseToken();
        baseAssetInfo.priceFeed = _comet.baseTokenPriceFeed();
        baseAssetInfo.price = _comet.getPrice(baseAssetInfo.priceFeed);
        baseAssetInfo.decimals = _comet.decimals();
        baseAssetInfo.mantissa = _comet.baseScale();
        baseAssetInfo.indexScale = _comet.baseIndexScale();

        TotalsBasic memory indices = _comet.totalsBasic();
        baseAssetInfo.trackingSupplyIndex = indices.trackingSupplyIndex;
        baseAssetInfo.trackingBorrowIndex = indices.trackingBorrowIndex;
    }

    function getScales(IComet _comet) internal view returns (Scales memory scales) {
        scales.factorScale = _comet.factorScale();
        scales.priceScale = _comet.priceScale();
        scales.trackingIndexScale = _comet.trackingIndexScale();
    }

    function getMarketFlags(IComet _comet) internal view returns (MarketFlags memory flags) {
        flags.isAbsorbPaused = _comet.isAbsorbPaused();
        flags.isBuyPaused = _comet.isBuyPaused();
        flags.isSupplyPaused = _comet.isSupplyPaused();
        flags.isWithdrawPaused = _comet.isWithdrawPaused();
        flags.isTransferPaused = _comet.isWithdrawPaused();
    }

    function getRewardsConfig(address cometMarket) internal view returns (RewardsConfig memory rewards) {
        ICometRewards _cometRewards = ICometRewards(getCometRewardsAddress());
        RewardConfig memory _rewards = _cometRewards.rewardConfig(cometMarket);
        rewards.token = _rewards.token;
        rewards.rescaleFactor = _rewards.rescaleFactor;
        rewards.shouldUpScale = _rewards.shouldUpscale;
        rewards.baseMinForRewards = IComet(cometMarket).baseMinForRewards();
    }

    function getMarketAssets(IComet _comet, uint8 length) internal view returns (AssetData[] memory assets) {
        assets = AssetData[](length);
        AssetInfo memory asset;
        AssetData memory _asset;
        Token memory _token;
        for (uint8 i = 0; i < length; i++) {
            asset = _comet.getAssetInfo(i);

            TokenInterface token = TokenInterface(asset.asset);
            _token.offset = asset.offset;
            _token.token = asset.asset;
            _token.symbol = token.symbol();
            _token.decimals = token.decimals();

            _asset.token = _token;
            _asset.priceFeed = asset.priceFeed;
            _asset.price = _comet.getPrice(asset.priceFeed);
            _asset.scale = asset.scale;
            _asset.borrowCollateralFactor = asset.borrowCollateralFactor;
            _asset.liquidateCollateralFactor = asset.liquidateCollateralFactor;
            _asset.liquidationFactor = asset.liquidationFactor;
            _asset.supplyCap = asset.supplyCap;
            _asset.totalCollateral = _comet.totalsCollateral(asset.asset).totalSupplyAsset;

            assets[i] = _asset;
        }
    }

    function getMarketConfig(address cometMarket) internal view returns (MarketConfig memory market) {
        IComet _comet = IComet(cometMarket);
        uint64 utilization = _comet.getUtilization();
        market.utilization = utilization;
        market.assetCount = _comet.numAssets();
        market.supplyRate = _comet.getSupplyRate(utilization);
        market.borrowRate = _comet.getBorrowRate(utilization);
        market.baseTrackingSupplySpeed = _comet.baseTrackingSupplySpeed();
        market.baseTrackingBorrowSpeed = _comet.baseTrackingBorrowSpeed();
        market.reserves = _comet.getReserves();
        market.storeFrontPriceFactor = _comet.storeFrontPriceFactor();
        market.baseBorrowMin = _comet.baseBorrowMin();
        market.targetReserves = _comet.targetReserves();
        market.totalSupplyBase = _comet.totalSupply();
        market.totalBorrowBase = _comet.totalBorrow();

        market.baseAssetInfo = getBaseTokenInfo(_comet);
        market.scales = getScales(_comet);
        market.rewardConfig = getRewardInfo(cometMarket);
        market.assets = getMarketAssets(_comet, market.assetCount);
    }

    function currentValue(
        int104 principalValue,
        uint64 baseSupplyIndex,
        uint64 baseBorrowIndex
    ) internal view returns (int104) {
        if (principalValue >= 0) {
            return int104((uint104(principalValue_) * baseSupplyIndex_) / uint64(BASE_INDEX_SCALE));
        } else {
            return -int104((uint104(principalValue_) * baseBorrowIndex_) / uint64(BASE_INDEX_SCALE));
        }
    }

    function isAssetIn(uint16 assetsIn, uint8 assetOffset) internal pure returns (bool) {
        return (assetsIn & (uint16(1) << assetOffset) != 0);
    }

    function getBorrowableAmount(
        UserBasic memory _userBasic,
        TotalsBasic memory _totalsBasic,
        IComet _comet,
        uint8 _numAssets
    ) internal view returns (int256) {
        uint16 _assetsIn = _userBasic.assetsIn;
        uint64 supplyIndex = _totalsBasic().baseSupplyIndex;
        uint64 borrowIndex = _totalsBasic().baseBorrowIndex;
        address baseTokenPriceFeed = _comet.baseTokenPriceFeed();

        int256 amount_ = int256(
            (currentValue(_userBasic.principal, supplyIndex, borrowIndex) *
                int256(_comet.getPrice(baseTokenPriceFeed))) / int256(1e8)
        );

        for (uint8 i = 0; i < numAssets; i++) {
            if (isAssetIn(assetsIn, i)) {
                AssetInfo memory asset = _comet.getAssetInfo(i);
                uint256 newAmount = (uint256(_comet.userCollateral(account, asset.asset).balance) *
                    _comet.getPrice(asset.priceFeed)) / 1e8;
                amount_ += int256((newAmount * asset.borrowCollateralFactor) / 1e18);
            }
        }

        return amount_;
    }

    //     uint256 rewardsAccrued;
    //     UserRewardsData rewards;
    //     UserCollateralData[] collaterals;
    //     AccountFlags flags;
    function getUserData(address account, address competMarket) internal view returns (UserData memory userData) {
        IComet _comet = IComet(cometMarket);
        userData.baseBalance = _comet.baseBalanceOf(account);
        userData.suppliedBalance = _comet.balanceOf(account);
        userData.borrowedBalance = _comet.borrowBalanceOf(account);
        UserBasic memory accountDataInBase = _comet.userBasic(account);
        userData.assetsIn = accountDataInBase.assetsIn;
        userData.accountTrackingIndex = accountDataInBase.baseTrackingIndex;
        userData.interestAccrued = accountDataInBase.baseTrackingAccrued;
        userData.userNonce = _comet.userNonce(account);
        userData.borrowableAmount = getBorrowableAmount(
            _comet.userBasic(account),
            _comet.totalsBasic(),
            _comet,
            _comet.numAssets()
        );
    }
}
