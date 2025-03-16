// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct UserPosition{
    uint256 vaultTokenBalance;
    uint256 underlyingTokenBalance;
    VaultDetails vaultDetails;
}

struct VaultDetails{
    string name;
    string symbol;
    uint256 decimals;
    address asset;
    uint256 totalAssets;
    uint256 totalSupply;
    address owner;
    address curator;
    address guardian;
    uint256 fee;
    address feeRecipient;
}

interface VaultInterface {
    function decimals() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function nonces(address) external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewMint(uint256 shares) external view returns (uint256);
    function previewWithdraw(uint256 assets) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function maxDeposit(address) external view returns (uint256);
    function maxMint(address) external view returns (uint256);
    function maxWithdraw(address owner) external view returns (uint256);
    function maxRedeem(address owner) external view returns (uint256);
}

interface IMetaMorpho is VaultInterface {
    function owner() external view returns (address);
    function curator() external view returns (address);
    function guardian() external view returns (address);
    function fee() external view returns (uint256);
    function feeRecipient() external view returns (address);
}

interface TokenInterface {
    function balanceOf(address) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}
