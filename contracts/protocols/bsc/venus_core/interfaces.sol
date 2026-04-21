// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IComptroller {
    function getAllMarkets() external view returns (address[] memory);

    function getAssetsIn(address account) external view returns (address[] memory);

    function checkMembership(address account, address vToken) external view returns (bool);

    // returns (isListed, collateralFactorMantissa, isVenus, liquidationThresholdMantissa, liquidationIncentiveMantissa, poolId, isBorrowAllowed)
    function markets(address vToken)
        external
        view
        returns (bool, uint256, bool, uint256, uint256, uint96, bool);

    // returns (error, liquidity, shortfall) — based on liquidation threshold
    function getAccountLiquidity(address account)
        external
        view
        returns (uint256, uint256, uint256);

    // returns (error, liquidity, shortfall) — based on collateral factor
    function getBorrowingPower(address account)
        external
        view
        returns (uint256, uint256, uint256);

    function oracle() external view returns (address);

    function closeFactorMantissa() external view returns (uint256);

    function venusSupplySpeeds(address vToken) external view returns (uint256);

    function venusBorrowSpeeds(address vToken) external view returns (uint256);

    function venusAccrued(address holder) external view returns (uint256);

    function actionPaused(address market, uint8 action) external view returns (bool);
}

interface IVToken {
    function balanceOf(address owner) external view returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);

    function totalBorrows() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function getCash() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function comptroller() external view returns (address);

    // returns (error, vTokenBalance, borrowBalance, exchangeRateMantissa)
    function getAccountSnapshot(address account)
        external
        view
        returns (uint256, uint256, uint256, uint256);
}

interface IPriceOracle {
    // price mantissa scaled by 1e(36 - underlyingDecimals)
    function getUnderlyingPrice(address vToken) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}
