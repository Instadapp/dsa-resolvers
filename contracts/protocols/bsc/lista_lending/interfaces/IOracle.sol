// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

struct TokenConfig {
  /// @notice asset address
  address asset;
  /// @notice `oracles` stores the oracles based on their role in the following order:
  /// [main, pivot, fallback],
  /// It can be indexed with the corresponding enum OracleRole value
  address[3] oracles;
  /// @notice `enableFlagsForOracles` stores the enabled state
  /// for each oracle in the same order as `oracles`
  bool[3] enableFlagsForOracles;
  /// @notice `timeDeltaTolerance` stores the tolerance of
  /// the difference between the block timestamp and the price update time
  /// the unit is seconds
  uint256 timeDeltaTolerance;
}

/// @title IOracle
/// @author Lista Dao
/// @notice Interface that oracles used by Lista Dao must implement.
/// @dev It is the user's responsibility to select markets with safe oracles.
interface IOracle {
  function peek(address asset) external view returns (uint256);
  function getTokenConfig(address asset) external view returns (TokenConfig memory);
}
