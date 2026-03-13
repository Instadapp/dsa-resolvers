// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IMetaMorpho, VaultDetails } from "./interfaces.sol";

contract Helpers {
    function getVaultDetails(address vaultAddress) internal view returns (VaultDetails memory vault) {
        IMetaMorpho vaultToken = IMetaMorpho(vaultAddress);

        vault.name = vaultToken.name();
        vault.symbol = vaultToken.symbol();
        vault.decimals = vaultToken.decimals();
        vault.asset = vaultToken.asset();
        vault.totalAssets = vaultToken.totalAssets();
        vault.totalSupply = vaultToken.totalSupply();
        vault.owner = vaultToken.owner();
        vault.curator = vaultToken.curator();
        vault.guardian = vaultToken.guardian();
        vault.fee = vaultToken.fee();
        vault.feeRecipient = vaultToken.feeRecipient();
    }
}
