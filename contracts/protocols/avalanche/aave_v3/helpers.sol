//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract AaveV3Helper is DSMath {
    // ----------------------- USING LATEST ADDRESSES -----------------------------

    /**
     *@dev Returns avax address
     */
    function getAvaxAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     *@dev Returns WAVAX address
     */
    function getWavaxAddr() internal pure returns (address) {
        return 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; //Avalanche WAVAX Address
    }

    /**
     *@dev Returns Aave Data Provider Address
     */
    function getAaveDataProvider() internal pure returns (address) {
        return 0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654; //Avalanche address
    }

    function getAaveIncentivesAddress() internal pure returns (address) {
        return 0xF88807B552aa22C4Dd7b00FD1645A63b2fca9F7b; //Avalanche IncentivesProxyAddress
    }

    /**
     *@dev Returns AaveOracle Address
     */
    function getAaveOracle() internal pure returns (address) {
        return 0xEBd36016B3eD09D4693Ed4251c67Bd858c3c7C9C; //Avalanche address
    }

    function getUiIncetivesProvider() internal pure returns (address) {
        return 0xC81CCebEA6A14bA007b96C0a1600D0bA0Df383a8;
    }

    function getChainLinkFeed() internal pure returns (address) {
        return 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
    }

    function getRewardsController() internal pure returns (address) {
        return 0x929EC64c34a17401F460460D4B9390518E5B473e;
    }

    struct BaseCurrency {
        uint256 baseUnit;
        address baseAddress;
        // uint256 baseInUSD;
        string symbol;
    }

    struct Token {
        address tokenAddress;
        string symbol;
        uint256 decimals;
    }

    struct EmodeData {
        // uint256[] price;
        EModeCategory data;
    }

    struct ReserveAddresses {
        Token aToken;
        Token stableDebtToken;
        Token variableDebtToken;
    }

    struct AaveV3UserTokenData {
        uint256 supplyBalance;
        uint256 stableBorrowBalance;
        uint256 variableBorrowBalance;
        uint256 supplyRate;
        uint256 stableBorrowRate;
        uint256 userStableBorrowRate;
        uint256 variableBorrowRate;
        bool isCollateral;
        uint256 price; //price of token in base currency
        Flags flag;
    }

    struct AaveV3UserData {
        uint256 totalCollateralBase;
        uint256 totalBorrowsBase;
        uint256 availableBorrowsBase;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
        uint256 eModeId;
        BaseCurrency base;
        // uint256 pendingRewards;
    }

    struct AaveV3TokenData {
        address asset;
        string symbol;
        uint256 decimals;
        uint256 ltv;
        uint256 threshold;
        uint256 reserveFactor;
        uint256 totalSupply;
        uint256 availableLiquidity;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        ReserveAddresses reserves;
        // TokenPrice tokenPrice;
        AaveV3Token token;
        // uint256 collateralEmission;
        // uint256 debtEmission;
    }

    struct Flags {
        bool usageAsCollateralEnabled;
        bool borrowEnabled;
        bool stableBorrowEnabled;
        bool isActive;
        bool isFrozen;
    }

    struct AaveV3Token {
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 debtCeiling;
        uint256 debtCeilingDecimals;
        uint256 liquidationFee;
        // uint256 isolationModeTotalDebt;
        bool isolationBorrowEnabled;
        bool isPaused;
    }

    //Rewards details
    struct ReserveIncentiveData {
        address underlyingAsset;
        IncentivesData aIncentiveData;
        IncentivesData vIncentiveData;
        IncentivesData sIncentiveData;
    }

    struct IncentivesData {
        address token;
        RewardsInfo[] rewardsTokenInfo;
        UserRewards userRewards;
    }

    struct UserRewards {
        address[] rewardsToken;
        uint256[] unbalancedAmounts;
    }

    struct RewardsInfo {
        string rewardTokenSymbol;
        address rewardTokenAddress;
        uint256 emissionPerSecond;
        uint256 rewardTokenDecimals;
        uint256 precision;
    }

    struct TokenPrice {
        uint256 priceInEth;
        uint256 priceInUsd;
    }

    struct PoolSpecificInfo {
        IPoolAddressesProvider provider;
        IPool pool;
        IAaveProtocolDataProvider aaveData;
    }

    IAaveOracle internal aaveOracle = IAaveOracle(getAaveOracle());
    IUiIncentiveDataProviderV3 internal uiIncentives = IUiIncentiveDataProviderV3(getUiIncetivesProvider());
    IRewardsController internal rewardsCntr = IRewardsController(getRewardsController());

    function getUserReward(
        address user,
        address[] memory assets,
        RewardsInfo[] memory _rewards
    ) internal view returns (UserRewards memory unclaimedRewards) {
        if (_rewards.length > 0) {
            (address[] memory reserves, uint256[] memory rewards) = rewardsCntr.getAllUserRewards(assets, user);
            unclaimedRewards = UserRewards(reserves, rewards);
        }
    }

    function getIncentivesInfo(
        address user,
        address poolAddressProvider
    ) internal view returns (ReserveIncentiveData[] memory incentives) {
        PoolSpecificInfo memory poolInfo = getPoolSpecificInfo(poolAddressProvider);

        AggregatedReserveIncentiveData[] memory _aggregateIncentive = uiIncentives.getReservesIncentivesData(
            poolInfo.provider
        );
        incentives = new ReserveIncentiveData[](_aggregateIncentive.length);
        for (uint256 i = 0; i < _aggregateIncentive.length; i++) {
            address[] memory rToken = new address[](1);
            RewardsInfo[] memory _aRewards = getRewardInfo(
                _aggregateIncentive[i].aIncentiveData.rewardsTokenInformation
            );
            RewardsInfo[] memory _sRewards = getRewardInfo(
                _aggregateIncentive[i].sIncentiveData.rewardsTokenInformation
            );
            RewardsInfo[] memory _vRewards = getRewardInfo(
                _aggregateIncentive[i].vIncentiveData.rewardsTokenInformation
            );
            rToken[0] = _aggregateIncentive[i].aIncentiveData.tokenAddress;
            IncentivesData memory _aToken = IncentivesData(
                _aggregateIncentive[i].aIncentiveData.tokenAddress,
                _aRewards,
                getUserReward(user, rToken, _aRewards)
            );
            rToken[0] = _aggregateIncentive[i].sIncentiveData.tokenAddress;
            IncentivesData memory _sToken = IncentivesData(
                _aggregateIncentive[i].sIncentiveData.tokenAddress,
                _sRewards,
                getUserReward(user, rToken, _sRewards)
            );
            rToken[0] = _aggregateIncentive[i].vIncentiveData.tokenAddress;
            IncentivesData memory _vToken = IncentivesData(
                _aggregateIncentive[i].vIncentiveData.tokenAddress,
                _vRewards,
                getUserReward(user, rToken, _vRewards)
            );
            incentives[i] = ReserveIncentiveData(_aggregateIncentive[i].underlyingAsset, _aToken, _vToken, _sToken);
        }
    }

    function getRewardInfo(RewardInfo[] memory rewards) internal pure returns (RewardsInfo[] memory rewardData) {
        rewardData = new RewardsInfo[](rewards.length);
        for (uint256 i = 0; i < rewards.length; i++) {
            rewardData[i] = RewardsInfo(
                rewards[i].rewardTokenSymbol,
                rewards[i].rewardTokenAddress,
                rewards[i].emissionPerSecond,
                uint256(rewards[i].rewardTokenDecimals),
                uint256(rewards[i].precision)
            );
        }
    }

    function getTokensPrices(
        uint256 basePriceInUSD,
        address[] memory tokens
    ) internal view returns (TokenPrice[] memory tokenPrices, uint256 ethPrice) {
        uint256[] memory _tokenPrices = aaveOracle.getAssetsPrices(tokens);
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        ethPrice = uint256(AggregatorV3Interface(getChainLinkFeed()).latestAnswer());

        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(
                (_tokenPrices[i] * basePriceInUSD * 10 ** 10) / ethPrice,
                wmul(_tokenPrices[i] * 10 ** 10, basePriceInUSD * 10 ** 10)
            );
        }
    }

    function getEmodePrices(
        address priceOracleAddr,
        address[] memory tokens
    ) internal view returns (uint256[] memory tokenPrices) {
        tokenPrices = IPriceOracle(priceOracleAddr).getAssetsPrices(tokens);
        // tokenPrices = new uint256[](tokens.length);
        // for (uint256 i = 0; i < tokens.length; i++) {
        //     tokenPrices[i] = IPriceOracle(priceOracleAddr).getAssetPrice(tokens[i]);
        // }
    }

    function getPendingRewards(
        address user,
        address[] memory _tokens,
        address poolAddressProvider
    ) internal view returns (uint256 rewards) {
        PoolSpecificInfo memory poolInfo = getPoolSpecificInfo(poolAddressProvider);

        uint256 arrLength = 2 * _tokens.length;
        address[] memory _atokens = new address[](arrLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            (_atokens[2 * i], , _atokens[2 * i + 1]) = poolInfo.aaveData.getReserveTokensAddresses(_tokens[i]);
        }
        rewards = IAaveIncentivesController(getAaveIncentivesAddress()).getRewardsBalance(_atokens, user);
    }

    function getIsolationDebt(
        address token,
        address poolAddressProvider
    ) internal view returns (uint256 isolationDebt) {
        PoolSpecificInfo memory poolInfo = getPoolSpecificInfo(poolAddressProvider);
        isolationDebt = uint256(poolInfo.pool.getReserveData(token).isolationModeTotalDebt);
    }

    function getUserData(
        address user,
        address poolAddressProvider
    ) internal view returns (AaveV3UserData memory userData) {
        PoolSpecificInfo memory poolInfo = getPoolSpecificInfo(poolAddressProvider);
        (
            userData.totalCollateralBase,
            userData.totalBorrowsBase,
            userData.availableBorrowsBase,
            userData.currentLiquidationThreshold,
            userData.ltv,
            userData.healthFactor
        ) = poolInfo.pool.getUserAccountData(user);

        userData.base = getBaseCurrencyDetails();
        userData.eModeId = poolInfo.pool.getUserEMode(user);
        // userData.pendingRewards = getPendingRewards(tokens, user);
    }

    function getFlags(address token, IAaveProtocolDataProvider aaveData) internal view returns (Flags memory flag) {
        (
            ,
            ,
            ,
            ,
            ,
            flag.usageAsCollateralEnabled,
            flag.borrowEnabled,
            flag.stableBorrowEnabled,
            flag.isActive,
            flag.isFrozen
        ) = aaveData.getReserveConfigurationData(token);
    }

    function getIsolationBorrowStatus(address token, IPool pool) internal view returns (bool iBorrowStatus) {
        ReserveConfigurationMap memory self = (pool.getReserveData(token)).configuration;
        uint256 BORROWABLE_IN_ISOLATION_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF;
        return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
    }

    function getV3Token(
        address token,
        IPool pool,
        IAaveProtocolDataProvider aaveData
    ) internal view returns (AaveV3Token memory tokenData) {
        (
            (tokenData.borrowCap, tokenData.supplyCap),
            tokenData.debtCeiling,
            tokenData.debtCeilingDecimals,
            tokenData.liquidationFee,
            tokenData.isPaused
        ) = (
            aaveData.getReserveCaps(token),
            aaveData.getDebtCeiling(token),
            aaveData.getDebtCeilingDecimals(),
            aaveData.getLiquidationProtocolFee(token),
            aaveData.getPaused(token)
        );
        {
            (tokenData.isolationBorrowEnabled) = getIsolationBorrowStatus(token, pool);
        }
        // (tokenData.isolationModeTotalDebt) = getIsolationDebt(token);
    }

    function getEmodeCategoryData(
        uint8 id,
        address poolAddressProvider
    ) external view returns (EmodeData memory eModeData) {
        PoolSpecificInfo memory poolInfo = getPoolSpecificInfo(poolAddressProvider);
        EModeCollateralConfig memory config_ = poolInfo.pool.getEModeCategoryCollateralConfig(id);
        string memory label = poolInfo.pool.getEModeCategoryLabel(id);
        uint128 isCollateralBitmap = poolInfo.pool.getEModeCategoryCollateralBitmap(id);
        uint128 isBorrowableBitmap = poolInfo.pool.getEModeCategoryBorrowableBitmap(id);

        EModeCategory memory data_ = EModeCategory(
            config_.ltv,
            config_.liquidationThreshold,
            config_.liquidationBonus,
            label,
            isCollateralBitmap,
            isBorrowableBitmap
        );
        {
            eModeData.data = data_;
            // eModeData.price = getEmodePrices(data_.priceSource, tokens);
        }
    }

    function reserveConfig(
        address token,
        IAaveProtocolDataProvider aaveData
    ) internal view returns (uint256 decimals, uint256 ltv, uint256 threshold, uint256 reserveFactor) {
        (decimals, ltv, threshold, , reserveFactor, , , , , ) = aaveData.getReserveConfigurationData(token);
    }

    function resData(
        address token,
        IAaveProtocolDataProvider aaveData
    ) internal view returns (uint256 availableLiquidity, uint256 totalStableDebt, uint256 totalVariableDebt) {
        (, , availableLiquidity, totalStableDebt, totalVariableDebt, , , , , , , ) = aaveData.getReserveData(token);
    }

    function getAaveTokensData(
        address token,
        address poolAddressProvider
    ) internal view returns (ReserveAddresses memory reserve) {
        PoolSpecificInfo memory poolInfo = getPoolSpecificInfo(poolAddressProvider);
        (
            reserve.aToken.tokenAddress,
            reserve.stableDebtToken.tokenAddress,
            reserve.variableDebtToken.tokenAddress
        ) = poolInfo.aaveData.getReserveTokensAddresses(token);
        reserve.aToken.symbol = IERC20Detailed(reserve.aToken.tokenAddress).symbol();
        reserve.variableDebtToken.symbol = IERC20Detailed(reserve.variableDebtToken.tokenAddress).symbol();
        reserve.aToken.decimals = IERC20Detailed(reserve.aToken.tokenAddress).decimals();
        reserve.variableDebtToken.decimals = IERC20Detailed(reserve.variableDebtToken.tokenAddress).decimals();
    }

    function userCollateralData(
        address token,
        address poolAddressProvider
    ) internal view returns (AaveV3TokenData memory aaveTokenData) {
        PoolSpecificInfo memory poolInfo = getPoolSpecificInfo(poolAddressProvider);

        aaveTokenData.asset = token;
        aaveTokenData.symbol = IERC20Detailed(token).symbol();
        (
            aaveTokenData.decimals,
            aaveTokenData.ltv,
            aaveTokenData.threshold,
            aaveTokenData.reserveFactor
        ) = reserveConfig(token, poolInfo.aaveData);

        {
            (
                aaveTokenData.availableLiquidity,
                aaveTokenData.totalStableDebt,
                aaveTokenData.totalVariableDebt
            ) = resData(token, poolInfo.aaveData);
        }

        aaveTokenData.token = getV3Token(token, poolInfo.pool, poolInfo.aaveData);
        // aaveTokenData.tokenPrice = assetPrice;

        aaveTokenData.reserves = getAaveTokensData(token, poolAddressProvider);

        //-------------INCENTIVE DETAILS---------------

        // (, aaveTokenData.collateralEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(
        //     aaveTokenData.reserves.aToken.tokenAddress
        // );
        // (, aaveTokenData.varDebtEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(
        //     aaveTokenData.reserves.variableDebtToken.tokenAddress
        // );
        // (, aaveTokenData.stableDebtEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(
        //     aaveTokenData.reserves.stableDebtToken.tokenAddress
        // );
    }

    function getUserTokenData(
        address user,
        address token,
        address poolAddressProvider
    ) internal view returns (AaveV3UserTokenData memory tokenData) {
        PoolSpecificInfo memory poolInfo = getPoolSpecificInfo(poolAddressProvider);
        uint256 basePrice = IPriceOracle(poolInfo.provider.getPriceOracle()).getAssetPrice(token);
        tokenData.price = basePrice;
        (
            tokenData.supplyBalance,
            tokenData.stableBorrowBalance,
            tokenData.variableBorrowBalance,
            ,
            ,
            tokenData.userStableBorrowRate,
            tokenData.supplyRate,
            ,
            tokenData.isCollateral
        ) = poolInfo.aaveData.getUserReserveData(token, user);

        {
            tokenData.flag = getFlags(token, poolInfo.aaveData);
            (, , , , , , tokenData.variableBorrowRate, tokenData.stableBorrowRate, , , , ) = poolInfo
                .aaveData
                .getReserveData(token);
        }
    }

    function getEthPrice() public view returns (uint256 ethPrice) {
        ethPrice = uint256(AggregatorV3Interface(getChainLinkFeed()).latestAnswer());
    }

    function getPrices(bytes memory data) internal pure returns (uint256) {
        (, BaseCurrencyInfo memory baseCurrency) = abi.decode(data, (AggregatedReserveData[], BaseCurrencyInfo));
        return uint256(baseCurrency.marketReferenceCurrencyPriceInUsd);
    }

    function getBaseCurrencyDetails() internal view returns (BaseCurrency memory baseCurr) {
        if (aaveOracle.BASE_CURRENCY() == address(0)) {
            baseCurr.symbol = "USD";
        } else {
            baseCurr.symbol = IERC20Detailed(aaveOracle.BASE_CURRENCY()).symbol();
        }

        baseCurr.baseUnit = aaveOracle.BASE_CURRENCY_UNIT();
        baseCurr.baseAddress = aaveOracle.BASE_CURRENCY();
        //TODO
        // {
        //     (, bytes memory data) = getUiDataProvider().staticcall(
        //         abi.encodeWithSignature("getReservesData(address)", IPoolAddressesProvider(getPoolAddressProvider()))
        //     );
        //     baseCurr.baseInUSD = getPrices(data);
        // }
    }

    function getList(address poolAddressProvider) public view returns (address[] memory data) {
        PoolSpecificInfo memory poolInfo = getPoolSpecificInfo(poolAddressProvider);
        data = poolInfo.pool.getReservesList();
    }

    function isUsingAsCollateralOrBorrowing(uint256 self, uint256 reserveIndex) public pure returns (bool) {
        require(reserveIndex < 128, "can't be more than 128");
        return (self >> (reserveIndex * 2)) & 3 != 0;
    }

    function isUsingAsCollateral(uint256 self, uint256 reserveIndex) public pure returns (bool) {
        require(reserveIndex < 128, "can't be more than 128");
        return (self >> (reserveIndex * 2 + 1)) & 1 != 0;
    }

    function isBorrowing(uint256 self, uint256 reserveIndex) public pure returns (bool) {
        require(reserveIndex < 128, "can't be more than 128");
        return (self >> (reserveIndex * 2)) & 1 != 0;
    }

    function getConfig(
        address user,
        address poolAddressProvider
    ) public view returns (UserConfigurationMap memory data) {
        PoolSpecificInfo memory poolInfo = getPoolSpecificInfo(poolAddressProvider);
        data = poolInfo.pool.getUserConfiguration(user);
    }

    function getPoolSpecificInfo(address poolAddressProvider) internal view returns (PoolSpecificInfo memory poolInfo) {
        poolInfo.provider = IPoolAddressesProvider(poolAddressProvider);
        poolInfo.pool = IPool(poolInfo.provider.getPool());
        poolInfo.aaveData = IAaveProtocolDataProvider(poolInfo.provider.getPoolDataProvider());
    }
}
