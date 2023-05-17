//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract SparkHelper is DSMath {
    // ----------------------- USING LATEST ADDRESSES -----------------------------

    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     *@dev Returns WETH address
     */
    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //Mainnet WEth Address
    }

    /**
     *@dev Returns Pool AddressProvider Address
     */
    function getPoolAddressProvider() internal pure returns (address) {
        return 0x02C3eA4e34C0cBd694D2adFa2c690EECbC1793eE; //Mainnet PoolAddressesProvider address
    }

    /**
     *@dev Returns Pool DataProvider Address
     */
    function getPoolDataProvider() internal pure returns (address) {
        return 0xFc21d6d146E6086B8359705C8b28512a983db0cb; //Mainnet PoolDataProvider address
    }

    /**
     *@dev Returns AaveOracle Address
     */
    function getAaveOracle() internal pure returns (address) {
        return 0x54586bE62E3c3580375aE3723C145253060Ca0C2; //Mainnet address
    }

    function getChainLinkFeed() internal pure returns (address) {
        //todo: confirm
        return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    }

    function getUiIncetivesProvider() internal pure returns (address) {
        return 0xA7F8A757C4f7696c015B595F51B2901AC0121B18;
    }

    function getRewardsController() internal pure returns (address) {
        return 0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb;
    }

    struct BaseCurrency {
        uint256 baseUnit;
        address baseAddress;
        string symbol;
    }

    struct Token {
        address tokenAddress;
        string symbol;
        uint256 decimals;
    }

    struct ReserveAddresses {
        Token spToken;
        Token stableDebtToken;
        Token variableDebtToken;
    }

    struct EmodeData {
        EModeCategory data;
    }

    struct SparkUserTokenData {
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

    struct SparkUserData {
        uint256 totalCollateralBase;
        uint256 totalBorrowsBase;
        uint256 availableBorrowsBase;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
        uint256 eModeId;
        BaseCurrency base;
    }

    struct SparkTokenData {
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
        SparkToken token;
    }

    struct Flags {
        bool usageAsCollateralEnabled;
        bool borrowEnabled;
        bool stableBorrowEnabled;
        bool isActive;
        bool isFrozen;
    }

    struct SparkToken {
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 eModeCategory;
        uint256 debtCeiling;
        uint256 debtCeilingDecimals;
        uint256 liquidationFee;
        bool isolationBorrowEnabled;
        bool isPaused;
        bool flashLoanEnabled;
    }

    struct TokenPrice {
        uint256 priceInEth;
        uint256 priceInUsd;
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

    IPoolAddressesProvider internal provider = IPoolAddressesProvider(getPoolAddressProvider());
    IAaveOracle internal aaveOracle = IAaveOracle(getAaveOracle());
    ISparkProtocolDataProvider internal sparkData = ISparkProtocolDataProvider(provider.getPoolDataProvider());
    IPool internal pool = IPool(provider.getPool());
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

    function getIncentivesInfo(address user) internal view returns (ReserveIncentiveData[] memory incentives) {
        AggregatedReserveIncentiveData[] memory _aggregateIncentive = uiIncentives.getReservesIncentivesData(provider);
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
            IncentivesData memory _spToken = IncentivesData(
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
            incentives[i] = ReserveIncentiveData(_aggregateIncentive[i].underlyingAsset, _spToken, _vToken, _sToken);
        }
    }

    function getRewardInfo(RewardInfo[] memory rewards) internal pure returns (RewardsInfo[] memory rewardData) {
        // console.log(rewards.length);
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

    function getTokensPrices(uint256 basePriceInUSD, address[] memory tokens)
        internal
        view
        returns (TokenPrice[] memory tokenPrices, uint256 ethPrice)
    {
        uint256[] memory _tokenPrices = aaveOracle.getAssetsPrices(tokens);
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        ethPrice = uint256(AggregatorV3Interface(getChainLinkFeed()).latestAnswer());

        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(
                (_tokenPrices[i] * basePriceInUSD * 10**10) / ethPrice,
                wmul(_tokenPrices[i] * 10**10, basePriceInUSD * 10**10)
            );
        }
    }

    function getEmodePrices(address priceOracleAddr, address[] memory tokens)
        internal
        view
        returns (uint256[] memory tokenPrices)
    {
        tokenPrices = IPriceOracle(priceOracleAddr).getAssetsPrices(tokens);
    }

    function getIsolationDebt(address token) internal view returns (uint256 isolationDebt) {
        isolationDebt = uint256(pool.getReserveData(token).isolationModeTotalDebt);
    }

    function getUserData(address user) internal view returns (SparkUserData memory userData) {
        (
            userData.totalCollateralBase,
            userData.totalBorrowsBase,
            userData.availableBorrowsBase,
            userData.currentLiquidationThreshold,
            userData.ltv,
            userData.healthFactor
        ) = pool.getUserAccountData(user);

        userData.base = getBaseCurrencyDetails();
        userData.eModeId = pool.getUserEMode(user);
    }

    function getFlags(address token) internal view returns (Flags memory flag) {
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
        ) = sparkData.getReserveConfigurationData(token);
    }

    function getIsolationBorrowStatus(address token) internal view returns (bool iBorrowStatus) {
        ReserveConfigurationMap memory self = (pool.getReserveData(token)).configuration;
        uint256 BORROWABLE_IN_ISOLATION_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF;
        return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
    }

    function getV3Token(address token) internal view returns (SparkToken memory tokenData) {
        (
            (tokenData.borrowCap, tokenData.supplyCap),
            tokenData.eModeCategory,
            tokenData.debtCeiling,
            tokenData.debtCeilingDecimals,
            tokenData.liquidationFee,
            tokenData.isPaused,
            tokenData.flashLoanEnabled
        ) = (
            sparkData.getReserveCaps(token),
            sparkData.getReserveEModeCategory(token),
            sparkData.getDebtCeiling(token),
            sparkData.getDebtCeilingDecimals(),
            sparkData.getLiquidationProtocolFee(token),
            sparkData.getPaused(token),
            sparkData.getFlashLoanEnabled(token)
        );
        {
            (tokenData.isolationBorrowEnabled) = getIsolationBorrowStatus(token);
        }
    }

    function getEthPrice() public view returns (uint256 ethPrice) {
        ethPrice = uint256(AggregatorV3Interface(getChainLinkFeed()).latestAnswer());
    }

    function getEmodeCategoryData(uint8 id) external view returns (EmodeData memory eModeData) {
        EModeCategory memory data_ = pool.getEModeCategoryData(id);
        {
            eModeData.data = data_;
        }
    }

    function reserveConfig(address token)
        internal
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 threshold,
            uint256 reserveFactor
        )
    {
        (decimals, ltv, threshold, , reserveFactor, , , , , ) = sparkData.getReserveConfigurationData(token);
    }

    function resData(address token)
        internal
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt
        )
    {
        (, , availableLiquidity, totalStableDebt, totalVariableDebt, , , , , , , ) = sparkData.getReserveData(token);
    }

    function getSparkTokensData(address token) internal view returns (ReserveAddresses memory reserve) {
        (
            reserve.spToken.tokenAddress,
            reserve.stableDebtToken.tokenAddress,
            reserve.variableDebtToken.tokenAddress
        ) = sparkData.getReserveTokensAddresses(token);
        reserve.spToken.symbol = IERC20Detailed(reserve.spToken.tokenAddress).symbol();
        reserve.stableDebtToken.symbol = IERC20Detailed(reserve.stableDebtToken.tokenAddress).symbol();
        reserve.variableDebtToken.symbol = IERC20Detailed(reserve.variableDebtToken.tokenAddress).symbol();
        reserve.spToken.decimals = IERC20Detailed(reserve.spToken.tokenAddress).decimals();
        reserve.stableDebtToken.decimals = IERC20Detailed(reserve.stableDebtToken.tokenAddress).decimals();
        reserve.variableDebtToken.decimals = IERC20Detailed(reserve.variableDebtToken.tokenAddress).decimals();
    }

    function userCollateralData(address token) internal view returns (SparkTokenData memory sparkTokenData) {
        sparkTokenData.asset = token;
        sparkTokenData.symbol = IERC20Detailed(token).symbol();
        (
            sparkTokenData.decimals,
            sparkTokenData.ltv,
            sparkTokenData.threshold,
            sparkTokenData.reserveFactor
        ) = reserveConfig(token);

        sparkTokenData.totalSupply = sparkData.getATokenTotalSupply(token);

        {
            (
                sparkTokenData.availableLiquidity,
                sparkTokenData.totalStableDebt,
                sparkTokenData.totalVariableDebt
            ) = resData(token);
        }

        sparkTokenData.token = getV3Token(token);

        //-------------INCENTIVE DETAILS---------------

        sparkTokenData.reserves = getSparkTokensData(token);
    }

    function getUserTokenData(address user, address token) internal view returns (SparkUserTokenData memory tokenData) {
        uint256 basePrice = IPriceOracle(IPoolAddressesProvider(getPoolAddressProvider()).getPriceOracle())
            .getAssetPrice(token);
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
        ) = sparkData.getUserReserveData(token, user);

        {
            tokenData.flag = getFlags(token);
            (, , , , , , tokenData.variableBorrowRate, tokenData.stableBorrowRate, , , , ) = sparkData.getReserveData(
                token
            );
        }
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
        //     (, bytes memory data) = getUiDataProvider().staticcall(
        //         abi.encodeWithSignature("getReservesData(address)", IPoolAddressesProvider(getPoolAddressProvider()))
        //     );
        //     baseCurr.baseInUSD = getPrices(data);
        // }
    }

    function getList() public view returns (address[] memory data) {
        data = pool.getReservesList();
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

    function getConfig(address user) public view returns (UserConfigurationMap memory data) {
        data = pool.getUserConfiguration(user);
    }
}
