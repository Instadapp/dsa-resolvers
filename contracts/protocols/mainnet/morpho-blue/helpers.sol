// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./interfaces/IMorpho.sol";
import "./interfaces/IIrm.sol";
import {MathLib} from "./libraries/MathLib.sol";
import {MorphoBalancesLib} from "./libraries/periphery/MorphoBalancesLib.sol";
import {MarketParamsLib} from "./libraries/MarketParamsLib.sol";
import {SharesMathLib} from "./libraries/SharesMathLib.sol";
import {MorphoLib} from "./libraries/periphery/MorphoLib.sol";
import {MorphoStorageLib} from "./libraries/periphery/MorphoStorageLib.sol";
import "./interfaces/IOracle.sol";
import "./libraries/ConstantsLib.sol";
// import {SafeERC20} from "./libraries/SafeERC20.sol";


contract Helpers {
    using MathLib for uint256;
    using MorphoLib for IMorpho;
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;
    // using SafeERC20 for ERC20;
    using SharesMathLib for uint256;

    IMorpho public immutable morpho = IMorpho(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // TODO: Update

    // TODO: Ask how should input be? ID or marketparams?
    function getMarketConfig(MarketParams memory marketParams) public view returns(MarketData memory marketData) {
        marketData.id = marketParams.id(); // TODO: Ask, id? its not in the struct
        marketData.market = morpho.market(marketData.id);

        marketData.totalSuppliedAsset = marketTotalSupply(marketParams);
        marketData.totalBorrowedAsset = marketTotalBorrow(marketParams);
        marketData.supplyAPR = supplyAPR(marketParams, marketData.market);
        marketData.borrowAPR = borrowAPR(marketParams, marketData.market);

        marketData.lastUpdate = morpho.lastUpdate(marketData.id);
        marketData.fee = morpho.fee(marketData.id);
    }

    function getUserConfig(address user, MarketParams memory marketParams) public view returns(UserData memory userData) {
        Id id = marketParams.id();

        userData.totalSuppliedAssets = supplyAssetsUser(marketParams, user);
        userData.totalBorrowedAssets = borrowAssetsUser(marketParams, user);
        userData.totalCollateralAssets = collateralAssetsUser(id, user);
        userData.healthFactor = userHealthFactor(marketParams, id, user);
        userData.position = morpho.position(id, user);
    }
    
    /**
     * @notice Calculates the supply APR (Annual Percentage Rate) for a given market.
     * @param marketParams The parameters of the market.
     * @param market The market for which the supply APR is being calculated.
     * @return supplyRate The calculated supply APR.
     */
    function supplyAPR(MarketParams memory marketParams, Market memory market)
        public
        view
        returns (uint256 supplyRate)
    {
        (uint256 totalSupplyAssets,, uint256 totalBorrowAssets,) = morpho.expectedMarketBalances(marketParams);

        // Get the borrow rate
        uint256 borrowRate = IIrm(marketParams.irm).borrowRateView(marketParams, market);

        // Get the supply rate
        uint256 utilization = totalBorrowAssets == 0 ? 0 : totalBorrowAssets.wDivUp(totalSupplyAssets);

        supplyRate = borrowRate.wMulDown(1 ether - market.fee).wMulDown(utilization);
    }

    /**
     * @notice Calculates the borrow APR (Annual Percentage Rate) for a given market.
     * @param marketParams The parameters of the market.
     * @param market The market for which the borrow APR is being calculated.
     * @return borrowRate The calculated borrow APR.
     */
    function borrowAPR(MarketParams memory marketParams, Market memory market)
        public
        view
        returns (uint256 borrowRate)
    {
        borrowRate = IIrm(marketParams.irm).borrowRateView(marketParams, market);
    }

    /**
     * @notice Calculates the total supply of assets in a specific market after having accrued interest.
     * @param marketParams The parameters of the market.
     * @return totalSupplyAssets The calculated total supply of assets.
     */
    function marketTotalSupply(MarketParams memory marketParams) public view returns (uint256 totalSupplyAssets) {
        totalSupplyAssets = morpho.expectedTotalSupplyAssets(marketParams);
    }

    /**
     * @notice Calculates the total borrow of assets in a specific market after having accrued interest.
     * @param marketParams The parameters of the market.
     * @return totalBorrowAssets The calculated total borrow of assets.
     */
    function marketTotalBorrow(MarketParams memory marketParams) public view returns (uint256 totalBorrowAssets) {
        totalBorrowAssets = morpho.expectedTotalBorrowAssets(marketParams);
    }

    /**
     * @notice Calculates the total supply balance of a given user in a specific market after having accrued interest.
     * @param marketParams The parameters of the market.
     * @param user The address of the user whose supply balance is being calculated.
     * @return totalSupplyAssets The calculated total supply balance.
     */
    function supplyAssetsUser(MarketParams memory marketParams, address user)
        public
        view
        returns (uint256 totalSupplyAssets)
    {
        totalSupplyAssets = morpho.expectedSupplyAssets(marketParams, user);
    }

    /**
     * @notice Calculates the total borrow balance of a given user in a specific market.
     * @param marketParams The parameters of the market.
     * @param user The address of the user whose borrow balance is being calculated.
     * @return totalBorrowAssets The calculated total borrow balance.
     */
    function borrowAssetsUser(MarketParams memory marketParams, address user)
        public
        view
        returns (uint256 totalBorrowAssets)
    {
        totalBorrowAssets = morpho.expectedBorrowAssets(marketParams, user);
    }

    /**
     * @notice Calculates the total collateral balance of a given user in a specific market.
     * @dev It uses extSloads to load only one storage slot of the Position struct and save gas.
     * @param marketId The identifier of the market.
     * @param user The address of the user whose collateral balance is being calculated.
     * @return totalCollateralAssets The calculated total collateral balance.
     */
    function collateralAssetsUser(Id marketId, address user) public view returns (uint256 totalCollateralAssets) {
        bytes32[] memory slots = new bytes32[](1);
        slots[0] = MorphoStorageLib.positionBorrowSharesAndCollateralSlot(marketId, user);
        bytes32[] memory values = morpho.extSloads(slots);
        totalCollateralAssets = uint256(values[0] >> 128);
    }

    /**
     * @notice Calculates the health factor of a user in a specific market.
     * @param marketParams The parameters of the market.
     * @param id The identifier of the market.
     * @param user The address of the user whose health factor is being calculated.
     * @return healthFactor The calculated health factor.
     */
    function userHealthFactor(MarketParams memory marketParams, Id id, address user)
        public
        view
        returns (uint256 healthFactor)
    {
        uint256 collateralPrice = IOracle(marketParams.oracle).price();
        uint256 collateral = morpho.collateral(id, user);
        uint256 borrowed = morpho.expectedBorrowAssets(marketParams, user);

        uint256 maxBorrow = collateral.mulDivDown(collateralPrice, ORACLE_PRICE_SCALE).wMulDown(marketParams.lltv);

        if (borrowed == 0) return type(uint256).max;
        healthFactor = maxBorrow.wDivDown(borrowed);
    }

    /**
     * @dev Return ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return Weth address
     */
    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet WETH Address
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // Kovan WETH Address
    }
}