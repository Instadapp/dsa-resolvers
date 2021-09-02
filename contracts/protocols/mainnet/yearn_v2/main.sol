// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    /**
     * @dev Count the number of positions in Yearn for a given owner.
     */
    function _countPositions(address[] memory wantAddresses) internal view returns (uint256) {
        YearnRegistryInterface registry = getRegistry();
        uint256 arraySize = 0;
        for (uint256 i = 0; i < wantAddresses.length; i++) {
            if (!registry.isRegistered(wantAddresses[i])) {
                continue;
            }
            uint256 numVaults = registry.numVaults(wantAddresses[i]);
            arraySize += numVaults;
        }
        return arraySize;
    }

    /**
     * @dev Prepare the vaultData for a specific vault, want and owner
     */
    function _prepareVaultData(
        YearnRegistryInterface registry,
        YearnV2Interface vault,
        address want,
        address owner
    ) internal view returns (VaultData memory vaultData) {
        address latest = registry.latestVault(want);
        uint256 pricePerShare = vault.pricePerShare();
        uint256 balanceOfWant = TokenInterface(want).balanceOf(owner);
        uint256 decimals = vault.decimals();
        return
            VaultData(
                latest,
                address(vault),
                want,
                pricePerShare,
                vault.availableDepositLimit(),
                vault.totalAssets(),
                vault.balanceOf(owner),
                balanceOfWant,
                (pricePerShare * balanceOfWant) / (10**decimals),
                decimals,
                latest != address(vault),
                vault.emergencyShutdown()
            );
    }

    /**
     * @dev Returns the current positions in Yearn for a given owner.
     */
    function getPositions(address owner, address[] memory wantAddresses) public view returns (VaultData[] memory) {
        YearnRegistryInterface registry = getRegistry();
        uint256 arraySize = _countPositions(wantAddresses);

        VaultData[] memory vaultData = new VaultData[](arraySize);
        for (uint256 i = 0; i < wantAddresses.length; i++) {
            if (!registry.isRegistered(wantAddresses[i])) {
                continue;
            }
            uint256 numVaults = registry.numVaults(wantAddresses[i]);
            for (uint256 vaultIndex = 0; vaultIndex < numVaults; vaultIndex++) {
                YearnV2Interface vault = YearnV2Interface(registry.vaults(wantAddresses[i], vaultIndex));
                vaultData[i] = _prepareVaultData(registry, vault, wantAddresses[i], owner);
            }
        }

        return vaultData;
    }

    /**
     * @dev Returns the current positions in lastest vaults for a given owner.
     */
    function getPositionsForLatest(address owner, address[] memory wantAddresses)
        public
        view
        returns (VaultData[] memory)
    {
        YearnRegistryInterface registry = getRegistry();
        VaultData[] memory vaultData = new VaultData[](wantAddresses.length);

        for (uint256 i = 0; i < wantAddresses.length; i++) {
            if (!registry.isRegistered(wantAddresses[i])) {
                continue;
            }
            YearnV2Interface vault = YearnV2Interface(registry.latestVault(wantAddresses[i]));
            vaultData[i] = _prepareVaultData(registry, vault, wantAddresses[i], owner);
        }

        return vaultData;
    }

    /**
     * @dev Returns the vault status (emergency shutdown or not)
     */
    function isEmergencyShutdown(YearnV2Interface vault) public view returns (bool) {
        return vault.emergencyShutdown();
    }

    /**
     * @dev Returns the number of want token for 1 share
     */
    function getPricePerShare(YearnV2Interface vault) public view returns (uint256) {
        return vault.pricePerShare();
    }

    /**
     * @dev Get the total assets of this vault could accept
     */
    function getAvailableDepositLimit(YearnV2Interface vault) public view returns (uint256) {
        return vault.availableDepositLimit();
    }

    /**
     * @dev Get the total quantity of all assets under control of this vault
     */
    function getTotalAssets(YearnV2Interface vault) public view returns (uint256) {
        return vault.totalAssets();
    }

    /**
     * @dev Get the total number of assets in the vault (aka shares) for this user
     */
    function getBalance(address owner, YearnV2Interface vault) public view returns (uint256) {
        return vault.balanceOf(owner);
    }

    /**
     * @dev
     */
    function getExpectedShareValue(address owner, YearnV2Interface vault) public view returns (uint256) {
        uint256 _pricePerShare = vault.pricePerShare();
        uint256 _balanceOfOwner = vault.balanceOf(owner);
        uint256 _decimals = vault.decimals();
        return (_pricePerShare * _balanceOfOwner) / (10**_decimals);
    }

    /**
     * @dev Check if a given want is used in one of the Yearn vaults
     */
    function isWantSupported(address want) public view returns (bool) {
        YearnRegistryInterface registry = getRegistry();
        return registry.isRegistered(want);
    }

    /**
     * @dev Retrieve the current vault for a given want
     */
    function latestForWant(address want) public view returns (address) {
        YearnRegistryInterface registry = getRegistry();
        return registry.latestVault(want);
    }

    /**
     * @dev Returns the number of vaults for a given want
     */
    function numVaultsForWant(address want) public view returns (uint256 numVaults) {
        YearnRegistryInterface registry = getRegistry();
        if (!registry.isRegistered(want)) {
            return 0;
        }
        return registry.numVaults(want);
    }

    /**
     * @dev List the vaults available for a given want.
     */
    function listVaultsForWant(address want) public view returns (address[] memory vaultAddresses) {
        YearnRegistryInterface registry = getRegistry();
        if (!registry.isRegistered(want)) {
            return vaultAddresses;
        }

        uint256 numVaults = registry.numVaults(want);
        vaultAddresses = new address[](numVaults);
        for (uint256 index = 0; index < numVaults; index++) {
            vaultAddresses[index] = registry.vaults(want, index);
        }
    }
}

contract InstaYearnV2Resolver is Resolver {
    string public constant name = "YearnV2-v1.0";
}
