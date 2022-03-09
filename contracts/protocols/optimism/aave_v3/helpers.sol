//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";
import "hardhat/console.sol";

contract AaveV3Helper is DSMath {
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
        return 0x4200000000000000000000000000000000000006; //Optimism WETH Address
    }

    function getUiDataProvider() internal pure returns (address) {
        return 0xeb4574A23832D913A981b749796BDC81554A79fF; //Optimism UiPoolDataProvider Address
    }

    /**
     *@dev Returns Pool AddressProvider Address
     */
    function getPoolAddressProvider() internal pure returns (address) {
        return 0x7013523049CeC8b06F594edb8c5fb7F232c0Df7C; //Optimism PoolAddressesProvider address
    }

    /**
     *@dev Returns Pool DataProvider Address
     */
    function getPoolDataProvider() internal pure returns (address) {
        return 0x44C7324E9d84D6534DD6f292Cc08f1816e45Ff6e; //Optimism PoolDataProvider address
    }

    /**
     *@dev Returns Aave Data Provider Address
     */
    function getAaveDataProvider() internal pure returns (address) {
        return 0x44C7324E9d84D6534DD6f292Cc08f1816e45Ff6e; //Optimism address
    }

    function getAaveIncentivesAddress() internal pure returns (address) {
        return 0x5366898b1b520A04EA813525930B36A444aE83d8; //Optimism IncentivesProxyAddress
    }

    /**
     *@dev Returns AaveOracle Address
     */
    function getAaveOracle() internal pure returns (address) {
        return 0x1A5740D6e64b60Eb3635c0F1B66bc39Da821daaa; //Optimism address
    }

    /**
     *@dev Returns StableDebtToken Address
     */
    function getStableDebtToken() internal pure returns (address) {
        return 0x9bFA5264ceddb62F998397ee70c73d48Cba3aD03; //Optimism address
    }

    function getChainLinkFeed() internal pure returns (address) {
        return 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
    }

    struct BaseCurrency {
        uint256 baseUnit;
        address baseAddress;
        // uint256 baseInUSD;
        string symbol;
    }

    struct ReserveAddresses {
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
    }

    struct EmodeData {
        // uint256[] price;
        EModeCategory data;
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
        // uint256 stableDebtEmission;
        // uint256 varDebtEmission;
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
        uint256 eModeCategory;
        uint256 debtCeiling;
        uint256 debtCeilingDecimals;
        uint256 liquidationFee;
        // uint256 isolationModeTotalDebt;
        bool isolationBorrowEnabled;
        bool isPaused;
    }

    struct TokenPrice {
        uint256 priceInEth;
        uint256 priceInUsd;
    }

    IPoolAddressesProvider internal provider = IPoolAddressesProvider(getPoolAddressProvider());
    IAaveOracle internal aaveOracle = IAaveOracle(getAaveOracle());
    IAaveProtocolDataProvider internal aaveData = IAaveProtocolDataProvider(provider.getPoolDataProvider());
    IPool internal pool = IPool(provider.getPool());

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
        // tokenPrices = new uint256[](tokens.length);
        // for (uint256 i = 0; i < tokens.length; i++) {
        //     tokenPrices[i] = IPriceOracle(priceOracleAddr).getAssetPrice(tokens[i]);
        // }
    }

    function getPendingRewards(address user, address[] memory _tokens) internal view returns (uint256 rewards) {
        uint256 arrLength = 2 * _tokens.length;
        address[] memory _atokens = new address[](arrLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            (_atokens[2 * i], , _atokens[2 * i + 1]) = aaveData.getReserveTokensAddresses(_tokens[i]);
        }
        rewards = IAaveIncentivesController(getAaveIncentivesAddress()).getRewardsBalance(_atokens, user);
    }

    function getIsolationDebt(address token) internal view returns (uint256 isolationDebt) {
        isolationDebt = uint256(pool.getReserveData(token).isolationModeTotalDebt);
    }

    function getUserData(address user) internal view returns (AaveV3UserData memory userData) {
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
        // userData.pendingRewards = getPendingRewards(tokens, user);
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
        ) = aaveData.getReserveConfigurationData(token);
    }

    function getV3Token(address token) internal view returns (AaveV3Token memory tokenData) {
        (
            (tokenData.borrowCap, tokenData.supplyCap),
            tokenData.eModeCategory,
            tokenData.debtCeiling,
            tokenData.debtCeilingDecimals,
            tokenData.liquidationFee,
            tokenData.isPaused
        ) = (
            aaveData.getReserveCaps(token),
            aaveData.getReserveEModeCategory(token),
            aaveData.getDebtCeiling(token),
            aaveData.getDebtCeilingDecimals(),
            aaveData.getLiquidationProtocolFee(token),
            aaveData.getPaused(token)
        );
        {
            (tokenData.isolationBorrowEnabled) = (aaveData.getDebtCeiling(token) == 0) ? false : true;
        }
        // (tokenData.isolationModeTotalDebt) = getIsolationDebt(token);
    }

    function getEmodeCategoryData(uint8 id, address[] memory tokens)
        external
        view
        returns (EmodeData memory eModeData)
    {
        EModeCategory memory data_ = pool.getEModeCategoryData(id);
        {
            eModeData.data = data_;
            // eModeData.price = getEmodePrices(data_.priceSource, tokens);
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
        (decimals, ltv, threshold, , reserveFactor, , , , , ) = aaveData.getReserveConfigurationData(token);
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
        (, , availableLiquidity, totalStableDebt, totalVariableDebt, , , , , , , ) = aaveData.getReserveData(token);
    }

    function userCollateralData(address token) internal view returns (AaveV3TokenData memory aaveTokenData) {
        aaveTokenData.asset = token;
        aaveTokenData.symbol = IERC20Detailed(token).symbol();
        (
            aaveTokenData.decimals,
            aaveTokenData.ltv,
            aaveTokenData.threshold,
            aaveTokenData.reserveFactor
        ) = reserveConfig(token);

        {
            (
                aaveTokenData.availableLiquidity,
                aaveTokenData.totalStableDebt,
                aaveTokenData.totalVariableDebt
            ) = resData(token);
        }

        aaveTokenData.token = getV3Token(token);
        // aaveTokenData.tokenPrice = assetPrice;
        (
            aaveTokenData.reserves.aTokenAddress,
            aaveTokenData.reserves.stableDebtTokenAddress,
            aaveTokenData.reserves.variableDebtTokenAddress
        ) = aaveData.getReserveTokensAddresses(token);

        //-------------INCENTIVE DETAILS---------------

        // (, aaveTokenData.collateralEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(
        //     aaveTokenData.reserves.aTokenAddress
        // );
        // (, aaveTokenData.varDebtEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(
        //     aaveTokenData.reserves.variableDebtTokenAddress
        // );
        // (, aaveTokenData.stableDebtEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(
        //     aaveTokenData.reserves.stableDebtTokenAddress
        // );
    }

    function getUserTokenData(address user, address token)
        internal
        view
        returns (AaveV3UserTokenData memory tokenData)
    {
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
        ) = aaveData.getUserReserveData(token, user);

        {
            tokenData.flag = getFlags(token);
            (, , , , , , tokenData.variableBorrowRate, tokenData.stableBorrowRate, , , , ) = aaveData.getReserveData(
                token
            );
        }
    }

    function getEthPrice() public view returns (uint256 ethPrice) {
        ethPrice = uint256(AggregatorV3Interface(getChainLinkFeed()).latestAnswer());
    }

    function getPrices(bytes memory data) internal view returns (uint256) {
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
