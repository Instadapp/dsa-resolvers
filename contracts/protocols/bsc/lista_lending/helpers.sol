// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { IMoolah, Id, MarketParams, Position, Market } from "./interfaces/IMoolah.sol";
import { MoolahBalancesLib } from "./libraries/periphery/MoolahBalancesLib.sol";
import { IIrm } from "./interfaces/IIrm.sol";
import { MathLib } from "./libraries/MathLib.sol";
import { MarketParamsLib } from "./libraries/MarketParamsLib.sol";
import { SharesMathLib } from "./libraries/SharesMathLib.sol";
import { IOracle } from "./interfaces/IOracle.sol";
import { ORACLE_PRICE_SCALE } from "./libraries/ConstantsLib.sol";

struct UserData {
    uint256 suppliedAssets;
    uint256 borrowedAssets;
    uint256 collateralAssets;
    uint256 healthFactor;
}

struct MarketData {
    Id id;
    address loanToken;
    address collateralToken;
    address oracle;
    address irm;
    uint256 lltv;
    uint256 totalSupplyAssets;
    uint256 totalSupplyShares;
    uint256 totalBorrowAssets;
    uint256 totalBorrowShares;
    uint256 lastUpdate;
    uint256 fee;
}

contract ListaLendingHelpers {
    using MathLib for uint256;
    using MoolahBalancesLib for IMoolah;
    using MarketParamsLib for MarketParams;
    using SharesMathLib for uint256;

    IMoolah internal constant MOOLAH = IMoolah(0x8F73b65B4caAf64FBA2aF91cC5D4a2A1318E5D8C);

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
        userData.suppliedAssets = supplyAssetsUser(marketParams, user);
        userData.borrowedAssets = borrowAssetsUser(marketParams, user);
        userData.collateralAssets = collateralAssetsUser(id, user);
        userData.healthFactor = userHealthFactor(marketParams, id, user);
    }

    /**
     * @notice Calculates the total supply balance of a given user in a specific market after having accrued interest.
     * @param marketParams The parameters of the market.
     * @param user The address of the user whose supply balance is being calculated.
     * @return suppliedAssets The calculated total supply balance.
     */
    function supplyAssetsUser(
        MarketParams memory marketParams,
        address user
    ) public view returns (uint256 suppliedAssets) {
        suppliedAssets = MOOLAH.expectedSupplyAssets(marketParams, user);
    }

    /**
     * @notice Calculates the total borrow balance of a given user in a specific market.
     * @param marketParams The parameters of the market.
     * @param user The address of the user whose borrow balance is being calculated.
     * @return borrowedAssets The calculated total borrow balance.
     */
    function borrowAssetsUser(
        MarketParams memory marketParams,
        address user
    ) public view returns (uint256 borrowedAssets) {
        borrowedAssets = MOOLAH.expectedBorrowAssets(marketParams, user);
    }

    /**
     * @notice Calculates the total collateral balance of a given user in a specific market.
     * @dev It uses extSloads to load only one storage slot of the Position struct and save gas.
     * @param marketId The identifier of the market.
     * @param user The address of the user whose collateral balance is being calculated.
     * @return collateralAssets The calculated total collateral balance.
     */
    function collateralAssetsUser(Id marketId, address user) public view returns (uint256 collateralAssets) {
        // bytes32[] memory slots = new bytes32[](1);
        // slots[0] = MoolahBalancesLib.positionBorrowSharesAndCollateralSlot(marketId, user);
        // bytes32[] memory values = MOOLAH.extSloads(slots);
        // totalCollateralAssets = uint256(values[0] >> 128);
        Position memory p = MOOLAH.position(marketId, user);
        collateralAssets = p.collateral;
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
        uint256 collateralPrice = MOOLAH.getPrice(marketParams);
        uint256 collateral = collateralAssetsUser(id, user);
        uint256 borrowed = MOOLAH.expectedBorrowAssets(marketParams, user);

        uint256 maxBorrow = collateral.mulDivDown(collateralPrice, ORACLE_PRICE_SCALE).wMulDown(marketParams.lltv);

        if (borrowed == 0) return type(uint256).max;
        healthFactor = maxBorrow.wDivDown(borrowed);
    }
}
