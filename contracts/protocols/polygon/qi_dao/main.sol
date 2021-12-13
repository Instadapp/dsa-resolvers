pragma solidity ^0.8.0;

import "./helpers.sol";
import "./interfaces.sol";
import "hardhat/console.sol";

contract Resolver is QiDaoHelpers {
    function getVaultCollateral(address vault, uint256 vaultID) public view returns (uint256) {
        erc20StablecoinInterface vaultContract = erc20StablecoinInterface(vault);
        return vaultContract.vaultCollateral(vaultID);
    }

    function getVaultDebt(address vault, uint256 vaultID) public view returns (uint256) {
        erc20StablecoinInterface vaultContract = erc20StablecoinInterface(vault);
        return vaultContract.vaultDebt(vaultID);
    }

    function getVaultByOwnerIndex(
        address vaultErc721,
        address owner,
        uint256 idx
    ) public view returns (uint256) {
        erc20StablecoinInterface vaultContract = erc20StablecoinInterface(vaultErc721);
        return vaultContract.tokenOfOwnerByIndex(owner, idx);
    }

    struct VaultInfo {
        uint256 vaultId;
        uint256 vaultCollateral;
        uint256 vaultDebt;
    }

    function getAllVaultsByOwner(
        address vault,
        address erc721Address,
        address owner
    ) public view returns (VaultInfo[] memory) {
        erc20StablecoinInterface vaultContract = erc20StablecoinInterface(vault);
        erc20StablecoinInterface erc721VaultContract = erc20StablecoinInterface(erc721Address);
        uint256 totalVaults = erc721VaultContract.balanceOf(owner);
        VaultInfo[] memory vaults = new VaultInfo[](totalVaults);
        for (uint256 vIdx = 0; vIdx < totalVaults; vIdx++) {
            uint256 vaultId = erc721VaultContract.tokenOfOwnerByIndex(owner, vIdx);
            uint256 vaultCollateral = getVaultCollateral(vault, vaultId);
            uint256 vaultDebt = getVaultDebt(vault, vaultId);
            vaults[0] = VaultInfo(vaultId, vaultCollateral, vaultDebt);
        }
        return vaults;
    }
}

contract InstaQiDaoResolverPolygon is Resolver {
    string public constant name = "QiDao-Resolver-v1.0";
}
