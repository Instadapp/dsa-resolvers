// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface YearnV2Interface {
    function emergencyShutdown() external view returns (bool);

    function pricePerShare() external view returns (uint256);

    function availableDepositLimit() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint256);
}

interface YearnRegistryInterface {
    function isRegistered(address) external view returns (bool);

    function latestVault(address) external view returns (address);

    function numVaults(address) external view returns (uint256);

    function vaults(address, uint256) external view returns (address);
}

interface TokenInterface {
    function balanceOf(address) external view returns (uint256);
}
