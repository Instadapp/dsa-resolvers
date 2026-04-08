// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// @title ErrorsLib
/// @author Lista DAO
/// @notice Library exposing error messages.
library ErrorsLib {
  /// @notice Thrown when the LLTV to enable exceeds the maximum LLTV.
  string internal constant MAX_LLTV_EXCEEDED = "max LLTV exceeded";

  /// @notice Thrown when the fee to set exceeds the maximum fee.
  string internal constant MAX_FEE_EXCEEDED = "max fee exceeded";

  /// @notice Thrown when the value is already set.
  string internal constant ALREADY_SET = "already set";

  /// @notice Thrown when the value is not set.
  string internal constant NOT_SET = "not set";

  /// @notice Thrown when the IRM is not enabled at market creation.
  string internal constant IRM_NOT_ENABLED = "IRM not enabled";

  /// @notice Thrown when the LLTV is not enabled at market creation.
  string internal constant LLTV_NOT_ENABLED = "LLTV not enabled";

  /// @notice Thrown when the market is already created.
  string internal constant MARKET_ALREADY_CREATED = "market already created";

  /// @notice Thrown when a token to transfer doesn't have code.
  string internal constant NO_CODE = "no code";

  /// @notice Thrown when the market is not created.
  string internal constant MARKET_NOT_CREATED = "market not created";

  /// @notice Thrown when not exactly one of the input amount is zero.
  string internal constant INCONSISTENT_INPUT = "inconsistent input";

  /// @notice Thrown when zero assets is passed as input.
  string internal constant ZERO_ASSETS = "zero assets";

  /// @notice Thrown when a zero address is passed as input.
  string internal constant ZERO_ADDRESS = "zero address";

  /// @notice Thrown when the caller is not authorized to conduct an action.
  string internal constant UNAUTHORIZED = "unauthorized";

  /// @notice Thrown when the caller is not provider.
  string internal constant NOT_PROVIDER = "not provider";

  /// @notice Thrown when the collateral is insufficient to `borrow` or `withdrawCollateral`.
  string internal constant INSUFFICIENT_COLLATERAL = "insufficient collateral";

  /// @notice Thrown when the liquidity is insufficient to `withdraw` or `borrow`.
  string internal constant INSUFFICIENT_LIQUIDITY = "insufficient liquidity";

  /// @notice Thrown when the position to liquidate is healthy.
  string internal constant HEALTHY_POSITION = "position is healthy";

  /// @notice Thrown when the position to liquidate is healthy.
  string internal constant UNHEALTHY_POSITION = "position is unhealthy";

  /// @notice Thrown when the authorization signature is invalid.
  string internal constant INVALID_SIGNATURE = "invalid signature";

  /// @notice Thrown when the authorization signature is expired.
  string internal constant SIGNATURE_EXPIRED = "signature expired";

  /// @notice Thrown when the nonce is invalid.
  string internal constant INVALID_NONCE = "invalid nonce";

  /// @notice Thrown when a token transfer reverted.
  string internal constant TRANSFER_REVERTED = "transfer reverted";

  /// @notice Thrown when a token transfer returned false.
  string internal constant TRANSFER_RETURNED_FALSE = "transfer returned false";

  /// @notice Thrown when a token transferFrom reverted.
  string internal constant TRANSFER_FROM_REVERTED = "transferFrom reverted";

  /// @notice Thrown when a token transferFrom returned false
  string internal constant TRANSFER_FROM_RETURNED_FALSE = "transferFrom returned false";

  /// @notice Thrown when the maximum uint128 is exceeded.
  string internal constant MAX_UINT128_EXCEEDED = "max uint128 exceeded";

  /// @notice Thrown when account is not in the liquidation whitelist.
  string internal constant NOT_LIQUIDATION_WHITELIST = "not liquidation whitelist";

  /// @notice Thrown when the caller is not in the whitelist.
  string internal constant NOT_WHITELIST = "not whitelist";

  /// @notice Thrown when the remaining supply is too low.
  string internal constant REMAIN_SUPPLY_TOO_LOW = "remain supply too low";

  /// @notice Thrown when the remaining borrow is too low.
  string internal constant REMAIN_BORROW_TOO_LOW = "remain borrow too low";

  string internal constant TOKEN_BLACKLISTED = "token blacklisted";

  /// @notice Thrown when broker's loan token or collateral token is invalid.
  string internal constant INVALID_BROKER = "invalid broker";

  string internal constant BLACKLISTED = "blacklisted";

  /// @notice Thrown when the caller is not a broker.
  string internal constant NOT_BROKER = "not broker";

  string internal constant BROKER_POSITION = "broker position cannot be liquidated directly";

  string internal constant EXCEED_MPC_CAP = "exceed mpc cap";

  string internal constant EXCEED_BORROW_SHARES = "exceed borrow shares";
}
