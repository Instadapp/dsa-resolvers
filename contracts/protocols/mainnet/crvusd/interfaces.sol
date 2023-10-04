// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct PositionData {
    uint256 supply;
    uint256 borrow;
    uint256 N;
    bool existLoan;
    uint256 health;
    UserPrices prices;
    uint256 loanId;
    int256[2] userTickNumber; // calculating for user band range
}

struct UserPrices {
    uint256 upper;
    uint256 lower;
}

struct Coins {
    address coin0; // borrowToken
    address coin1; // collateralToken
    uint8 coin0Decimals;
    uint8 coin1Decimals;
    uint256 coin0Amount;
    uint256 coin1Amount;
}

struct MarketConfig {
    uint256 totalDebt;
    uint256 basePrice; // internal oracle price
    uint256 oraclePrice; // external oracle price
    uint256 A; // amplicitation coefficient
    uint256 loanLen;
    uint256 fractionPerSecond;
    int256 sigma;
    uint256 targetDebtFraction;
    address controller;
    address AMM;
    address monetary;
    uint256 borrowable;
    Coins coins; // factors for total collaterals
    int256 minBand;
    int256 maxBand;
}

interface IControllerFactory {
    function get_controller(address collateral, uint256 index) external view returns (address);
}

interface IController {
    function user_state(address user) external view returns (uint256[4] memory);

    function debt(address user) external view returns (uint256);

    function total_debt() external view returns (uint256);

    function loan_exists(address user) external view returns (bool);

    function user_prices(address user) external view returns (uint256[2] memory);

    function health(address user, bool full) external view returns (uint256);

    function n_loans() external view returns (uint256);

    function loan_ix(address user) external view returns (uint256);

    function amm() external view returns (address);

    function loan_discount() external view returns (uint256);

    function liquidation_discount() external view returns (uint256);

    function amm_price() external view returns (uint256);

    function monetary_policy() external view returns (address);

    function max_borrowable(uint256 collateral, uint256 N) external view returns (uint256);

    function min_collateral(uint256 debt, uint256 N) external view returns (uint256);

    function calculate_debt_n1(
        uint256 collateral,
        uint256 debt,
        uint256 N
    ) external view returns (int256);
}

interface I_LLAMMA {
    function price_oracle() external view returns (uint256);

    function A() external view returns (uint256);

    function coins(uint256 i) external view returns (address);

    function get_base_price() external view returns (uint256);

    function read_user_tick_numbers(address user) external view returns (int256[2] memory);

    function min_band() external view returns (int256);

    function max_band() external view returns (int256);

    function p_oracle_up(int256 bandNumber0) external view returns (uint256);

    function p_oracle_down(int256 bandNumber1) external view returns (uint256);
}

interface IMonetary {
    function rate(address controller) external view returns (uint256);

    function rate() external view returns (uint256);

    function sigma() external view returns (int256);

    function target_debt_fraction() external view returns (uint256);

    function peg_keepers(uint256 arg0) external view returns (address);
}

interface IPegKeeper {
    function debt() external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}
