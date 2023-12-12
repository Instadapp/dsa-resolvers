// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Id, IMorpho, MarketParams, Position, Market } from "./interfaces/IMorpho.sol";
import { IIrm } from "./interfaces/IIrm.sol";
import { MathLib } from "./libraries/MathLib.sol";
import { MorphoBalancesLib } from "./libraries/periphery/MorphoBalancesLib.sol";
import { MarketParamsLib } from "./libraries/MarketParamsLib.sol";
import { SharesMathLib } from "./libraries/SharesMathLib.sol";
import { MorphoLib } from "./libraries/periphery/MorphoLib.sol";
import { MorphoStorageLib } from "./libraries/periphery/MorphoStorageLib.sol";
import { IOracle } from "./interfaces/IOracle.sol";
import { ORACLE_PRICE_SCALE } from "./libraries/ConstantsLib.sol";

contract Helpers {
    using MathLib for uint256;
    using MorphoLib for IMorpho;
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;
    using SharesMathLib for uint256;

    struct MarketData {
        Id id;
        Market market;
        uint256 totalSuppliedAsset;
        uint256 totalSuppliedShares;
        uint256 totalBorrowedAsset;
        uint256 totalBorrowedShares;
        uint256 supplyAPY;
        uint256 borrowAPY;
        uint256 lastUpdate;
        uint256 fee;
    }

    struct UserData {
        uint256 totalSuppliedAssets;
        uint256 totalBorrowedAssets;
        uint256 totalCollateralAssets;
        uint256 healthFactor;
        Position position;
    }

    IMorpho public immutable morpho = IMorpho(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // TODO: Update

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
    }

    /**
     * @dev Return detailed market configs
     * @param marketParams The parameters of the market.
     */
    function getMarketConfig(MarketParams memory marketParams) public view returns (MarketData memory marketData) {
        marketData.id = marketParams.id();
        marketData.market = morpho.market(marketData.id);

        // Expected market balances of a market after having accrued interest.
        (
            marketData.totalSuppliedAsset,
            marketData.totalSuppliedShares,
            marketData.totalBorrowedAsset,
            marketData.totalBorrowedShares
        ) = morpho.expectedMarketBalances(marketParams);

        (marketData.supplyAPY, marketData.borrowAPY) = getSupplyAndBorrowAPY(
            marketParams,
            marketData.market,
            marketData.totalSuppliedAsset,
            marketData.totalBorrowedAsset
        );

        marketData.lastUpdate = morpho.lastUpdate(marketData.id);
        marketData.fee = morpho.fee(marketData.id);
    }

    /**
     * @dev Return detailed user position
     * @param id The identifier of the market.
     * @param marketParams The parameters of the market.
     * @param user The address of the user whose position is being calculated.
     */
    function getUserConfig(
        Id id,
        MarketParams memory marketParams,
        address user
    ) public view returns (UserData memory userData) {
        userData.totalSuppliedAssets = supplyAssetsUser(marketParams, user);
        userData.totalBorrowedAssets = borrowAssetsUser(marketParams, user);
        userData.totalCollateralAssets = collateralAssetsUser(id, user);
        userData.healthFactor = userHealthFactor(marketParams, id, user);
        userData.position = morpho.position(id, user);
    }

    /**
     * @notice Calculates the supply APY (Annual Percentage Yield) and
     * borrow APY (Annual Percentage Yield) for a given market.
     * @param marketParams The parameters of the market.
     * @param market The market for which the supply APY is being calculated.
     * @return supplyRate and borrowRate The calculated supply and borrow APY.
     */
    function getSupplyAndBorrowAPY(
        MarketParams memory marketParams,
        Market memory market,
        uint256 totalSupplyAssets,
        uint256 totalBorrowAssets
    ) public view returns (uint256 supplyRate, uint256 borrowRate) {
        // (uint256 totalSupplyAssets, , uint256 totalBorrowAssets, ) = morpho.expectedMarketBalances(marketParams);

        // Get the borrow rate
        borrowRate = IIrm(marketParams.irm).borrowRateView(marketParams, market).wTaylorCompounded(1);

        // Get the supply rate
        uint256 utilization = totalBorrowAssets == 0 ? 0 : totalBorrowAssets.wDivUp(totalSupplyAssets);

        supplyRate = borrowRate.wMulDown(1 ether - market.fee).wMulDown(utilization);
    }

    /**
     * @notice Calculates the total supply balance of a given user in a specific market after having accrued interest.
     * @param marketParams The parameters of the market.
     * @param user The address of the user whose supply balance is being calculated.
     * @return totalSupplyAssets The calculated total supply balance.
     */
    function supplyAssetsUser(
        MarketParams memory marketParams,
        address user
    ) public view returns (uint256 totalSupplyAssets) {
        totalSupplyAssets = morpho.expectedSupplyAssets(marketParams, user);
    }

    /**
     * @notice Calculates the total borrow balance of a given user in a specific market.
     * @param marketParams The parameters of the market.
     * @param user The address of the user whose borrow balance is being calculated.
     * @return totalBorrowAssets The calculated total borrow balance.
     */
    function borrowAssetsUser(
        MarketParams memory marketParams,
        address user
    ) public view returns (uint256 totalBorrowAssets) {
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
    function userHealthFactor(
        MarketParams memory marketParams,
        Id id,
        address user
    ) public view returns (uint256 healthFactor) {
        uint256 collateralPrice = IOracle(marketParams.oracle).price();
        uint256 collateral = morpho.collateral(id, user);
        uint256 borrowed = morpho.expectedBorrowAssets(marketParams, user);

        uint256 maxBorrow = collateral.mulDivDown(collateralPrice, ORACLE_PRICE_SCALE).wMulDown(marketParams.lltv);

        if (borrowed == 0) return type(uint256).max;
        healthFactor = maxBorrow.wDivDown(borrowed);
    }
}
