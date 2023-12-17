// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract AaveHelpers is DSMath {
    /**
     * @dev Return Avax address
     */
    function getAvaxAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // avax Address
    }

    /**
     * @dev Return Wavax address
     */
    function getWavaxAddr() internal pure returns (address) {
        return 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // WAVAX Address
    }

    /**
     * @dev get Aave Provider Address
     */
    function getAaveAddressProvider() internal pure returns (address) {
        return 0xb6A86025F0FE1862B372cb0ca18CE3EDe02A318f; // Mainnet
    }

    /**
     * @dev get Aave Protocol Data Provider
     */
    function getAaveProtocolDataProvider() internal pure returns (address) {
        return 0x65285E9dfab318f57051ab2b139ccCf232945451; // Mainnet
    }

    /**
     * @dev get Chainlink ETH price feed Address
     */
    function getChainlinkEthFeed() internal pure returns (address) {
        return 0x976B3D034E162d8bD72D6b9C989d545b839003b0; //mainnet
    }

    /**
     * @dev Aave Incentives address
     */
    function getAaveIncentivesAddress() internal pure returns (address) {
        return 0x01D83Fe6A10D2f2B7AF17034343746188272cAc9; // polygon mainnet
    }

    struct AaveUserTokenData {
        uint256 tokenPriceInEth;
        uint256 tokenPriceInUsd;
        uint256 supplyBalance;
        uint256 stableBorrowBalance;
        uint256 variableBorrowBalance;
        uint256 supplyRate;
        uint256 stableBorrowRate;
        uint256 userStableBorrowRate;
        uint256 variableBorrowRate;
        bool isCollateral;
        AaveTokenData aaveTokenData;
    }

    struct AaveUserData {
        uint256 totalCollateralETH;
        uint256 totalBorrowsETH;
        uint256 availableBorrowsETH;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
        uint256 ethPriceInUsd;
        uint256 pendingRewards;
    }

    struct AaveTokenData {
        uint256 ltv;
        uint256 threshold;
        uint256 reserveFactor;
        bool usageAsCollEnabled;
        bool borrowEnabled;
        bool stableBorrowEnabled;
        bool isActive;
        bool isFrozen;
        uint256 totalSupply;
        uint256 availableLiquidity;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 collateralEmission;
        uint256 debtEmission;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
    }

    struct TokenPrice {
        uint256 priceInEth;
        uint256 priceInUsd;
    }

    function getTokensPrices(AaveAddressProvider aaveAddressProvider, address[] memory tokens)
        internal
        view
        returns (TokenPrice[] memory tokenPrices, uint256 ethPrice)
    {
        uint256[] memory _tokenPrices = AavePriceOracle(aaveAddressProvider.getPriceOracle()).getAssetsPrices(tokens);
        ethPrice = uint256(ChainLinkInterface(getChainlinkEthFeed()).latestAnswer());
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(wdiv(_tokenPrices[i], uint256(ethPrice)), _tokenPrices[i] * 1e10);
        }
    }

    function collateralData(AaveProtocolDataProvider aaveData, address token)
        internal
        view
        returns (AaveTokenData memory aaveTokenData)
    {
        (
            ,
            aaveTokenData.ltv,
            aaveTokenData.threshold,
            ,
            aaveTokenData.reserveFactor,
            aaveTokenData.usageAsCollEnabled,
            aaveTokenData.borrowEnabled,
            aaveTokenData.stableBorrowEnabled,
            aaveTokenData.isActive,
            aaveTokenData.isFrozen
        ) = aaveData.getReserveConfigurationData(token);

        (
            aaveTokenData.aTokenAddress,
            aaveTokenData.stableDebtTokenAddress,
            aaveTokenData.variableDebtTokenAddress
        ) = aaveData.getReserveTokensAddresses(token);

        AaveIncentivesInterface.AssetData memory _data;
        AaveIncentivesInterface incentives = AaveIncentivesInterface(getAaveIncentivesAddress());

        _data = incentives.assets(aaveTokenData.aTokenAddress);
        aaveTokenData.collateralEmission = _data.emissionPerSecond;
        _data = incentives.assets(aaveTokenData.variableDebtTokenAddress);
        aaveTokenData.debtEmission = _data.emissionPerSecond;
        aaveTokenData.totalSupply = TokenInterface(aaveTokenData.aTokenAddress).totalSupply();
    }

    function getTokenData(
        AaveProtocolDataProvider aaveData,
        address user,
        address token,
        uint256 tokenPriceInEth,
        uint256 tokenPriceInUsd
    ) internal view returns (AaveUserTokenData memory tokenData) {
        AaveTokenData memory aaveTokenData = collateralData(aaveData, token);

        (
            tokenData.supplyBalance,
            tokenData.stableBorrowBalance,
            tokenData.variableBorrowBalance,
            ,
            ,
            tokenData.userStableBorrowRate,
            ,
            ,
            tokenData.isCollateral
        ) = aaveData.getUserReserveData(token, user);

        (
            aaveTokenData.availableLiquidity,
            aaveTokenData.totalStableDebt,
            aaveTokenData.totalVariableDebt,
            tokenData.supplyRate,
            tokenData.variableBorrowRate,
            tokenData.stableBorrowRate,
            ,
            ,
            ,

        ) = aaveData.getReserveData(token);

        tokenData.tokenPriceInEth = tokenPriceInEth;
        tokenData.tokenPriceInUsd = tokenPriceInUsd;
        tokenData.aaveTokenData = aaveTokenData;
    }

    function getPendingRewards(address[] memory _tokens, address user) internal view returns (uint256 rewards) {
        uint256 arrLength = 2 * _tokens.length;
        address[] memory _atokens = new address[](arrLength);
        AaveProtocolDataProvider aaveData = AaveProtocolDataProvider(getAaveProtocolDataProvider());
        for (uint256 i = 0; i < _tokens.length; i++) {
            (_atokens[2 * i], , _atokens[2 * i + 1]) = aaveData.getReserveTokensAddresses(_tokens[i]);
        }
        rewards = AaveIncentivesInterface(getAaveIncentivesAddress()).getRewardsBalance(_atokens, user);
    }

    function getUserData(
        AaveLendingPool aave,
        address user,
        uint256 ethPriceInUsd,
        address[] memory tokens
    ) internal view returns (AaveUserData memory userData) {
        (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = aave.getUserAccountData(user);

        uint256 pendingRewards = getPendingRewards(tokens, user);

        userData = AaveUserData(
            totalCollateralETH,
            totalDebtETH,
            availableBorrowsETH,
            currentLiquidationThreshold,
            ltv,
            healthFactor,
            ethPriceInUsd,
            pendingRewards
        );
    }

    function getConfig(address user, AaveLendingPool aave)
        public
        view
        returns (AaveLendingPool.UserConfigurationMap memory data)
    {
        data = aave.getUserConfiguration(user);
    }

    function getList(AaveLendingPool aave) public view returns (address[] memory data) {
        data = aave.getReservesList();
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
}
