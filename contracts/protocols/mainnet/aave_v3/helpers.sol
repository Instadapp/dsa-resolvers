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
        return 0xc778417E063141139Fce010982780140Aa0cD5Ab; //Rinkeby WETH Address
    }

    function getUiDataProvider() internal pure returns (address) {
        return 0x507CdaD90F8AE7D4BBa5e05F2a1012f7f4b07053; //Rinkeby UiPoolDataProvider Address
    }

    /**
     *@dev Returns Pool AddressProvider Address
     */
    function getPoolAddressProvider() internal pure returns (address) {
        return 0xA55125A90d75a95EC00130E8E8C197dB5641Eb19; //Rinkeby PoolAddressesProvider address
    }

    /**
     *@dev Returns Pool DataProvider Address
     */
    function getPoolDataProvider() internal pure returns (address) {
        return 0x256bBbeDbA70a1240a1EB64210abB1b063267408; //Rinkeby PoolDataProvider address
    }

    /**
     *@dev Returns Aave Data Provider Address
     */
    function getAaveDataProvider() internal pure returns (address) {
        return 0x256bBbeDbA70a1240a1EB64210abB1b063267408; //Rinkeby address
    }

    function getAaveIncentivesAddress() internal pure returns (address) {
        return 0x074eE9683639930D305184586B364c8C19ED3d4d; //Rinkeby IncentivesProxyAddress
    }

    /**
     *@dev Returns AaveOracle Address
     */
    function getAaveOracle() internal pure returns (address) {
        return 0xc1ee6d09C2A682490cb728aF0E87859E329e1705; //Rinkeby address
    }

    /**
     *@dev Returns StableDebtToken Address
     */
    function getStableDebtToken() internal pure returns (address) {
        return 0xE0987FC9EDfcdcA3CB9618510AaF1D565f4960A6; //Rinkeby address
    }

    function getChainLinkFeed() internal pure returns (address) {
        return 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    }

    struct BaseCurrency {
        uint256 baseUnit;
        address baseAddress;
        uint256 baseInUSD;
        string symbol;
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
        // uint256 price; //price of token in base currency
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
        uint256 decimals;
        uint256 ltv;
        uint256 threshold;
        uint256 reserveFactor;
        uint256 totalSupply;
        uint256 availableLiquidity;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        TokenPrice tokenPrice;
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
        public
        view
        returns (uint256[] memory tokenPrices)
    {
        tokenPrices = IPriceOracle(priceOracleAddr).getAssetsPrices(tokens);
        // tokenPrices = new uint256[](tokens.length);
        // for (uint256 i = 0; i < tokens.length; i++) {
        //     tokenPrices[i] = IPriceOracle(priceOracleAddr).getAssetPrice(tokens[i]);
        // }
    }

    function getPendingRewards(address user, address[] memory _tokens) public view returns (uint256 rewards) {
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

    function userCollateralData(address token, TokenPrice memory assetPrice)
        internal
        view
        returns (AaveV3TokenData memory aaveTokenData)
    {
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
        aaveTokenData.tokenPrice = assetPrice;

        //-------------INCENTIVE DETAILS---------------

        // (address aToken, , address debtToken) = aaveData.getReserveTokensAddresses(token);
        // (, aaveTokenData.collateralEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(aToken);
        // (, aaveTokenData.debtEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(debtToken);
    }

    function getUserTokenData(address user, address token)
        internal
        view
        returns (AaveV3UserTokenData memory tokenData)
    {
        // uint256 basePrice = IPriceOracle(IPoolAddressesProvider(getPoolAddressProvider()).getPriceOracle())
        //     .getAssetPrice(token);
        // tokenData.price = basePrice;
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
        {
            (, bytes memory data) = getUiDataProvider().staticcall(
                abi.encodeWithSignature("getReservesData(address)", IPoolAddressesProvider(getPoolAddressProvider()))
            );
            baseCurr.baseInUSD = getPrices(data);
        }
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
