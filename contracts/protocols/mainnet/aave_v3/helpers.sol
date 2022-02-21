//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

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
        string symbol;
    }

    struct EModeCategoryData {
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        TokenPrice[] price;
        address priceSource;
        string label;
    }

    struct AaveV3UserTokenData {
        uint256 tokenPriceInBase;
        uint256 supplyBalance;
        uint256 stableBorrowBalance;
        uint256 variableBorrowBalance;
        uint256 supplyRate;
        uint256 stableBorrowRate;
        uint256 userStableBorrowRate;
        uint256 variableBorrowRate;
        bool isCollateral;
        uint256 price;
        flags flag;
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
        uint256 pendingRewards;
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
        uint256 collateralEmission;
        uint256 debtEmission;
        AaveV3Token token;
    }

    struct flags {
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
        bool isolationBorrowEnabled;
        bool isPaused;
    }

    struct TokenPrice {
        uint256 priceInEth;
        uint256 priceInUsd;
    }

    function getTokensPrices(address[] memory tokens)
        internal
        view
        returns (TokenPrice[] memory tokenPrices, uint256 ethPrice)
    {
        uint256[] memory _tokenPrices = IAaveOracle(getAaveOracle()).getAssetsPrices(tokens);
        (, int256 EthPrice, , , ) = (AggregatorV3Interface(getChainLinkFeed()).latestRoundData());
        ethPrice = uint256(EthPrice);
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(_tokenPrices[i], wmul(_tokenPrices[i], ethPrice * 10**10));
        }
    }

    function getEmodePrices(address[] memory tokens, address priceOracleAddr)
        internal
        view
        returns (TokenPrice[] memory tokenPrices)
    {
        tokenPrices = new TokenPrice[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 priceBase = IPriceOracle(priceOracleAddr).getAssetPrice(tokens[i]);
            (, int256 EthPrice, , , ) = (AggregatorV3Interface(getChainLinkFeed()).latestRoundData());
            uint256 ethPrice = uint256(EthPrice);
            tokenPrices[i] = TokenPrice(priceBase, wmul(priceBase, ethPrice * 10**10));
        }
    }

    function getPendingRewards(address[] memory _tokens, address user) internal view returns (uint256 rewards) {
        IAaveProtocolDataProvider aaveData = IAaveProtocolDataProvider(
            IPoolAddressesProvider(getPoolAddressProvider()).getPoolDataProvider()
        );
        uint256 arrLength = 2 * _tokens.length;
        address[] memory _atokens = new address[](arrLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            (_atokens[2 * i], , _atokens[2 * i + 1]) = aaveData.getReserveTokensAddresses(_tokens[i]);
        }
        rewards = IAaveIncentivesController(getAaveIncentivesAddress()).getRewardsBalance(_atokens, user);
    }

    function getUserData(address user, address[] memory tokens) internal view returns (AaveV3UserData memory) {
        IAaveProtocolDataProvider aaveData = IAaveProtocolDataProvider(
            IPoolAddressesProvider(getPoolAddressProvider()).getPoolDataProvider()
        );
        AaveV3UserData memory userData;
        {
            (
                userData.totalCollateralBase,
                userData.totalBorrowsBase,
                userData.availableBorrowsBase,
                userData.currentLiquidationThreshold,
                userData.ltv,
                userData.healthFactor
            ) = IPool(IPoolAddressesProvider(getPoolAddressProvider()).getPool()).getUserAccountData(user);
        }

        {
            BaseCurrency memory baseCurr;
            IAaveOracle aaveOracle = IAaveOracle(getAaveOracle());
            baseCurr.baseUnit = aaveOracle.BASE_CURRENCY_UNIT();
            baseCurr.baseAddress = (aaveOracle.BASE_CURRENCY());
            if (aaveOracle.BASE_CURRENCY() == address(0)) {
                baseCurr.symbol = "USD";
            } else {
                baseCurr.symbol = IERC20Detailed(aaveOracle.BASE_CURRENCY()).symbol();
            }
            userData.base = baseCurr;
        }

        {
            userData.eModeId = IPool(IPoolAddressesProvider(getPoolAddressProvider()).getPool()).getUserEMode(user);
            userData.pendingRewards = getPendingRewards(tokens, user);
        }
        return userData;
    }

    function getFlags(address token) internal view returns (flags memory flag) {
        IAaveProtocolDataProvider aaveData = IAaveProtocolDataProvider(
            IPoolAddressesProvider(getPoolAddressProvider()).getPoolDataProvider()
        );
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
        IAaveProtocolDataProvider aaveData = IAaveProtocolDataProvider(
            IPoolAddressesProvider(getPoolAddressProvider()).getPoolDataProvider()
        );
        (tokenData.borrowCap, tokenData.supplyCap) = aaveData.getReserveCaps(token);
        (tokenData.eModeCategory) = aaveData.getReserveEModeCategory(token);
        (tokenData.debtCeiling) = aaveData.getDebtCeiling(token);
        (tokenData.debtCeilingDecimals) = aaveData.getDebtCeilingDecimals();
        (tokenData.liquidationFee) = aaveData.getLiquidationProtocolFee(token);
        (tokenData.isPaused) = aaveData.getPaused(token);
        (tokenData.isolationBorrowEnabled) = (aaveData.getDebtCeiling(token) == 0) ? false : true;
    }

    function getEmodeCategoryData(uint8 id, address[] memory tokens)
        external
        view
        returns (EModeCategoryData memory eModeData)
    {
        IPool pool = IPool(IPoolAddressesProvider(getPoolAddressProvider()).getPool());
        eModeData.ltv = pool.getEModeCategoryData(id).ltv;
        eModeData.liquidationThreshold = pool.getEModeCategoryData(id).liquidationThreshold;
        eModeData.liquidationBonus = pool.getEModeCategoryData(id).liquidationBonus;
        eModeData.priceSource = pool.getEModeCategoryData(id).priceSource;
        eModeData.label = pool.getEModeCategoryData(id).label;
        eModeData.price = getEmodePrices(tokens, eModeData.priceSource);
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
        IAaveProtocolDataProvider aaveData = IAaveProtocolDataProvider(
            IPoolAddressesProvider(getPoolAddressProvider()).getPoolDataProvider()
        );
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
        IAaveProtocolDataProvider aaveData = IAaveProtocolDataProvider(
            IPoolAddressesProvider(getPoolAddressProvider()).getPoolDataProvider()
        );
        (, , availableLiquidity, totalStableDebt, totalVariableDebt, , , , , , , ) = aaveData.getReserveData(token);
    }

    function userCollateralData(address token) internal view returns (AaveV3TokenData memory) {
        IAaveProtocolDataProvider aaveData = IAaveProtocolDataProvider(
            IPoolAddressesProvider(getPoolAddressProvider()).getPoolDataProvider()
        );
        AaveV3TokenData memory aaveTokenData;
        {
            (
                aaveTokenData.decimals,
                aaveTokenData.ltv,
                aaveTokenData.threshold,
                aaveTokenData.reserveFactor
            ) = reserveConfig(token);
        }
        {
            (
                aaveTokenData.availableLiquidity,
                aaveTokenData.totalStableDebt,
                aaveTokenData.totalVariableDebt
            ) = resData(token);
            aaveTokenData.token = getV3Token(token);
        }
        {
            (address aToken, , address debtToken) = aaveData.getReserveTokensAddresses(token);
            (, aaveTokenData.collateralEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(
                aToken
            );
            (, aaveTokenData.debtEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(debtToken);
        }
        return aaveTokenData;
    }

    function getUserTokenData(address user, address token) internal view returns (AaveV3UserTokenData memory) {
        IAaveProtocolDataProvider aaveData = IAaveProtocolDataProvider(
            IPoolAddressesProvider(getPoolAddressProvider()).getPoolDataProvider()
        );
        uint256 basePrice = IPriceOracle(IPoolAddressesProvider(getPoolAddressProvider()).getPriceOracle())
            .getAssetPrice(token);
        AaveV3UserTokenData memory tokenData;
        tokenData.price = basePrice;
        {
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
            tokenData.flag = getFlags(token);
        }

        (, , , , , , tokenData.variableBorrowRate, tokenData.stableBorrowRate, , , , ) = aaveData.getReserveData(token);
        return tokenData;
    }

    function getList() public view returns (address[] memory data) {
        data = IPool(IPoolAddressesProvider(getPoolAddressProvider()).getPool()).getReservesList();
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

    function getConfig(address user, IPool aave) public view returns (IPool.UserConfigurationMap memory data) {
        data = aave.getUserConfiguration(user);
    }
}
