// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// import "./interfaces/IMorpho.sol";
// import "./interfaces/IIrm.sol";
import {MathLib} from "./libraries/MathLib.sol";
import {MorphoBalancesLib} from "./libraries/periphery/MorphoBalancesLib.sol";
import {MarketParamsLib} from "./libraries/MarketParamsLib.sol";
import {SharesMathLib} from "./libraries/SharesMathLib.sol";
import {MorphoLib} from "./libraries/periphery/MorphoLib.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract Helpers {
    using MathLib for uint256;
    using MorphoLib for IMorpho;
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;
    using SafeERC20 for ERC20;
    using SharesMathLib for uint256;

    IMorpho public immutable morpho = IMorpho(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // TODO: Update

    struct MarketData {
        Id id;
        Market market;
        uint256 totalSuppliedAsset;
        uint256 totalBorrowedAsset;
        uint256 supplyAPR;
        uint256 borrowAPR;
        uint256 lastUpdate;
        uint256 fee;
    }

    struct UserData {
        uint256 totalSuppliedAssets;
        uint256 totalBorrowedAssets;
        uint256 totalCollateralAssets;
        uint256 healthFactor;
    }

    // TODO: Ask how should input be? ID or marketparams?
    function getMarketConfig(MarketParams memory marketParams) public view {
        MarketData memory marketData;

        marketData.id = marketParams.id(); // TODO: Ask, id? its not in the struct
        marketData.market = morpho.market(id);

        marketData.totalSuppliedAsset = marketTotalSupply(marketParams);
        marketData.totalBorrowedAsset = marketTotalBorrow(marketParams);
        marketData.supplyAPR = supplyAPR(marketParams, market);
        marketData.borrowAPR = borrowAPR(marketParams, market);

        marketData.lastUpdate = morpho.lastUpdate(id);
        marketData.fee = morpho.fee(id);
    }

    function getUserConfig(address user, MarketParams memory marketParams) public view {
        UserData memory userData;

        userData.totalSuppliedAssets = supplyAssetsUser(marketParams, user);
        userData.totalBorrowedAssets = borrowAssetsUser(marketParams, user);
        userData.totalCollateralAssets = collateralAssetsUser(id, user);
        userData.healthFactor = userHealthFactor(marketParams, id, user);
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
}