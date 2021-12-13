// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface erc20StablecoinInterface {
    function vaultCollateral(uint256 vaultID) external view returns (uint256);

    function vaultDebt(uint256 vaultID) external view returns (uint256);

    function vaultOwner(uint256 vaultID) external view returns (address);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}
