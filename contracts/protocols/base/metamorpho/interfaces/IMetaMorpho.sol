// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IMorpho, Id, MarketParams} from "./IMorpho.sol";

struct MarketConfig {
    /// @notice The maximum amount of assets that can be allocated to the market.
    uint192 cap;
    /// @notice Whether the market is in the withdraw queue.
    bool enabled;
    /// @notice The timestamp at which the market can be instantly removed from the withdraw queue.
    uint56 removableAt;
}

/// @dev Either `assets` or `shares` should be zero.
struct MarketAllocation {
    /// @notice The market to allocate.
    MarketParams marketParams;
    /// @notice The amount of assets to allocate.
    uint256 assets;
}

/// @dev This interface is used for factorizing IMetaMorphoStaticTyping and IMetaMorpho.
/// @dev Consider using the IMetaMorpho interface instead of this one.
interface IMetaMorphoBase {
    function MORPHO() external view returns (IMorpho);

    function curator() external view returns (address);
    function isAllocator(address target) external view returns (bool);
    function guardian() external view returns (address);

    function fee() external view returns (uint96);
    function feeRecipient() external view returns (address);
    function skimRecipient() external view returns (address);
    function timelock() external view returns (uint256);
    function supplyQueue(uint256) external view returns (Id);
    function supplyQueueLength() external view returns (uint256);
    function withdrawQueue(uint256) external view returns (Id);
    function withdrawQueueLength() external view returns (uint256);

    function lastTotalAssets() external view returns (uint256);

    function submitTimelock(uint256 newTimelock) external;
    function acceptTimelock() external;
    function revokePendingTimelock() external;

    function submitCap(MarketParams memory marketParams, uint256 supplyCap) external;
    function acceptCap(Id id) external;
    function revokePendingCap(Id id) external;

    function submitMarketRemoval(Id id) external;
    function revokePendingMarketRemoval(Id id) external;

    function submitGuardian(address newGuardian) external;
    function acceptGuardian() external;
    function revokePendingGuardian() external;

    function skim(address) external;

    function setIsAllocator(address newAllocator, bool newIsAllocator) external;
    function setCurator(address newCurator) external;
    function setFee(uint256 newFee) external;
    function setFeeRecipient(address newFeeRecipient) external;
    function setSkimRecipient(address) external;

    function setSupplyQueue(Id[] calldata newSupplyQueue) external;
    function updateWithdrawQueue(uint256[] calldata indexes) external;
    function reallocate(MarketAllocation[] calldata allocations) external;
}

/// @dev This interface is inherited by MetaMorpho so that function signatures are checked by the compiler.
/// @dev Consider using the IMetaMorpho interface instead of this one.
interface IMetaMorphoStaticTyping is IMetaMorphoBase {
    function config(Id) external view returns (uint192 cap, bool enabled, uint56 removableAt);
    function pendingGuardian() external view returns (address guardian, uint56 validAt);
    function pendingCap(Id) external view returns (uint192 value, uint56 validAt);
    function pendingTimelock() external view returns (uint192 value, uint56 validAt);
}

/// @title IMetaMorpho
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @dev Use this interface for MetaMorpho to have access to all the functions with the appropriate function signatures.
interface IMetaMorpho is IMetaMorphoBase {
    function config(Id) external view returns (MarketConfig memory);

    // From IERC4626
    function totalAssets() external view returns (uint256);
}
