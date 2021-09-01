// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    /**
     * @dev Count the number of positions in Yearn for a given owner.
     */
    function countPositions(address[] memory wantAddresses) internal view returns (uint256) {
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
     * @dev Returns the current positions in Yearn for a given owner.
     */
    function getPositions(address owner, address[] memory wantAddresses) public view returns (VaultData[] memory) {
        YearnRegistryInterface registry = getRegistry();
        uint256 arraySize = countPositions(wantAddresses);

        VaultData[] memory vaultData = new VaultData[](arraySize);
        for (uint256 i = 0; i < wantAddresses.length; i++) {
            if (!registry.isRegistered(wantAddresses[i])) {
                continue;
            }
            uint256 numVaults = registry.numVaults(wantAddresses[i]);
            for (uint256 vaultIndex = 0; vaultIndex < numVaults; vaultIndex++) {
                YearnV2Interface vault = YearnV2Interface(registry.vaults(wantAddresses[i], vaultIndex));
                address latest = registry.latestVault(wantAddresses[i]);
                vaultData[i] = VaultData(
                    latest,
                    address(vault),
                    wantAddresses[i],
                    vault.pricePerShare(),
                    vault.availableDepositLimit(),
                    vault.totalAssets(),
                    vault.balanceOf(owner),
                    TokenInterface(wantAddresses[i]).balanceOf(owner),
                    latest != address(vault),
                    vault.emergencyShutdown()
                );
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
            address latest = registry.latestVault(wantAddresses[i]);
            vaultData[i] = VaultData(
                latest,
                address(vault),
                wantAddresses[i],
                vault.pricePerShare(),
                vault.availableDepositLimit(),
                vault.totalAssets(),
                vault.balanceOf(owner),
                TokenInterface(wantAddresses[i]).balanceOf(owner),
                latest != address(vault),
                vault.emergencyShutdown()
            );
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
     * @dev Get the total number of assets in the vault (aka shares)
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
        return _pricePerShare * _balanceOfOwner;
    }

    /**
     * @dev Check if a given want is used in one of the Yearn vaults
     */
    function isWantSupported(address want) public view returns (bool) {
        YearnRegistryInterface registry = getRegistry();
        return registry.isRegistered(want);
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
