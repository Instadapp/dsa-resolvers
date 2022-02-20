//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import { DSMath } from "./dsmath.sol";

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
        return; //Rinkeby address
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
        AaveV3TokenData aaveTokenData;
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
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 eModeCategory;
        uint256 debtCeiling;
        uint256 debtCeilingDecimals;
        uint256 liquidationFee;
        bool isolationBorrowEnabled;
        bool usageAsCollateralEnabled;
        bool borrowEnabled;
        bool stableBorrowEnabled;
        bool isActive;
        bool isFrozen;
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
            tokenPrices[i] = TokenPrice(_tokenPrices[i], wmul(_tokenPrices[i], uint256(ethPrice) * 10**10));
        }
    }

    function getEmodePrices(address[] memory tokens, address priceOracleAddr)
        internal
        view
        returns (uint256[] memory tokenPrices, uint256 ethPrice)
    {
        tokenPrices = new uint256[](tokens.length);
        (, int256 EthPrice, , , ) = (AggregatorV3Interface(getChainLinkFeed()).latestRoundData());
        ethPrice = uint256(EthPrice);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 priceBase = IPriceOracle(priceOracleAddr).getAssetPrice(tokens[i]);
            tokenPrices[i] = priceBase;
        }
    }

    function getPendingRewards(
        IAaveProtocolDataProvider aaveData,
        address[] memory _tokens,
        address user
    ) internal view returns (uint256 rewards) {
        uint256 arrLength = 2 * _tokens.length;
        address[] memory _atokens = new address[](arrLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            (_atokens[2 * i], , _atokens[2 * i + 1]) = aaveData.getReserveTokensAddresses(_tokens[i]);
        }
        rewards = IAaveIncentivesController(getAaveIncentivesAddress()).getRewardsBalance(_atokens, user);
    }

    function getUserData(
        IAaveProtocolDataProvider aaveData,
        address user,
        address[] memory tokens
    ) internal view returns (AaveV3UserData memory userData) {
        (
            userData.totalCollateralBase,
            userData.totalBorrowsBase,
            userData.availableBorrowsBase,
            userData.currentLiquidationThreshold,
            userData.ltv,
            userData.healthFactor
        ) = IPool(IPoolAddressesProvider(getPoolAddressProvider()).getPool()).getUserAccountData(user);

        BaseCurrency memory baseCurr;
        IAaveOracle aaveOracle = IAaveOracle(getAaveOracle());
        baseCurr.baseUnit = aaveOracle.BASE_CURRENCY_UNIT();
        baseCurr.baseAddress = (aaveOracle.BASE_CURRENCY());
        address usd = address(0x0000000000000000000000000000000000000);
        if (aaveOracle.BASE_CURRENCY() == usd) {
            baseCurr.symbol = "USD";
        } else {
            baseCurr.symbol = IERC20Detailed(aaveOracle.BASE_CURRENCY()).symbol();
        }
        userData.base = baseCurr;

        userData.eModeId = IPool(IPoolAddressesProvider(getPoolAddressProvider()).getPool()).getUserEMode(user);

        userData.pendingRewards = getPendingRewards(aaveData, tokens, user);
    }

    function collateralData(IAaveProtocolDataProvider aaveData, address token)
        internal
        view
        returns (AaveV3TokenData memory aaveTokenData)
    {
        (
            aaveTokenData.decimals,
            aaveTokenData.ltv,
            aaveTokenData.threshold,
            ,
            aaveTokenData.reserveFactor,
            aaveTokenData.usageAsCollateralEnabled,
            aaveTokenData.borrowEnabled,
            aaveTokenData.stableBorrowEnabled,
            aaveTokenData.isActive,
            aaveTokenData.isFrozen
        ) = aaveData.getReserveConfigurationData(token);

        (
            ,
            ,
            aaveTokenData.availableLiquidity,
            aaveTokenData.totalStableDebt,
            aaveTokenData.totalVariableDebt,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = aaveData.getReserveData(token);

        (aaveTokenData.borrowCap, aaveTokenData.supplyCap) = aaveData.getReserveCaps(token);
        (aaveTokenData.eModeCategory) = aaveData.getReserveEModeCategory(token);
        (aaveTokenData.debtCeiling) = aaveData.getDebtCeiling(token);
        (aaveTokenData.debtCeilingDecimals) = aaveData.getDebtCeilingDecimals();
        (aaveTokenData.liquidationFee) = aaveData.getLiquidationProtocolFee(token);
        (aaveTokenData.isPaused) = aaveData.getPaused(token);
        (aaveTokenData.isolationBorrowEnabled) = (aaveData.getDebtCeiling(token) == 0) ? false : true;

        //incentives info --> collateralEmission, debtEmission
        (address aToken, , address debtToken) = aaveData.getReserveTokensAddresses(token);
        (, aaveTokenData.collateralEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(aToken);
        (, aaveTokenData.debtEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(debtToken);
    }

    function getUserTokenData(
        IAaveProtocolDataProvider aaveData,
        address user,
        address token
    ) internal view returns (AaveV3UserTokenData memory tokenData) {
        uint256 basePrice = IPriceOracle(IPoolAddressesProvider(getPoolAddressProvider()).getPriceOracle())
            .getAssetPrice(token);
        // AaveTokenData aaveTokenData;

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

        (, , , , , , tokenData.variableBorrowRate, tokenData.stableBorrowRate, , , , ) = aaveData.getReserveData(token);
        tokenData.aaveTokenData = collateralData(aaveData, token);
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
