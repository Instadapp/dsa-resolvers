// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// @title IERC20
/// @author Lista DAO
/// @dev Empty because we only call library functions. It prevents calling transfer (transferFrom) instead of
/// safeTransfer (safeTransferFrom).
interface IERC20 {}
