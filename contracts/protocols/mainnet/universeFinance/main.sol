//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { Helpers } from "./helpers.sol";

abstract contract UniverseFinanceResolver is Helpers {
    /**
     * @notice get all Universe Working Vaults
     * @return address list
     */
    function getAllVault() public view returns (address[] memory) {
        return _officialVaults();
    }

    /**
     * @notice get universe vault detail info
     * @param universeVaults the Universe Vault Address
     * @return [token0Address, token1Address, vaultMaxToken0Amount, vaultMaxToken1Amount, maxSingleDepositFofToken0,
     maxSingleDepositFofToken1, totalToken0Amount, totalTotal1Amount, utilizationOfToken0, utilizationOfToken1]
     */
    function getVaultDetail(address[] memory universeVaults) public view returns (VaultData[] memory) {
        return _vaultData(universeVaults);
    }

    /**
     * @notice get user share info
     * @param universeVault the Universe Vault Address
     * @param user the user address
     * @return shareToken0Amount and shareToken1Amount
     */
    function getUserShareAmount(address universeVault, address user) external view returns (uint256, uint256) {
        return _userShareAmount(universeVault, user);
    }

    /**
     * @notice get user share info list
     * @param universeVaults the Universe Vault Address arrays
     * @param user the user address
     */
    function getUserShareAmountList(address[] memory universeVaults, address user)
        external
        view
        returns (uint256[2][] memory data)
    {
        uint256 len = universeVaults.length;
        if (len > 0) {
            data = new uint256[2][](len);
            for (uint256 i; i < len; i++) {
                (uint256 share0, uint256 share1) = _userShareAmount(universeVaults[i], user);
                data[i] = [share0, share1];
            }
        }
    }

    /**
     * @notice get user withdraw amount
     * @param universeVault the Universe Vault Address
     * @param user the user address
     * @return token0Amount  token1Amount
     */
    function getUserWithdrawAmount(address universeVault, address user) external view returns (uint256, uint256) {
        (uint256 share0, uint256 share1) = _userShareAmount(universeVault, user);
        return _withdrawAmount(universeVault, share0, share1);
    }

    /**
     * @notice get user can get share when deposit amount0 and amount1
     * @param universeVault the Universe Vault Address
     * @param amount0 the token0 amount
     * @param amount1 the token1 amount
     * @return shareToken0Amount and shareToken1Amount
     */
    function getUserDepositAmount(
        address universeVault,
        uint256 amount0,
        uint256 amount1
    ) external view returns (uint256, uint256) {
        return _depositAmount(universeVault, amount0, amount1);
    }

    /**
     * @notice get token decimals of a vault
     * @param vault the vault address
     * @return token decimals
     */
    function decimals(address vault) external view returns (uint8, uint8) {
        return _decimals(vault);
    }

    /**
     * @notice get token decimals of a vault
     * @param universeVault the vault's address
     * @param user the user's address
     */
    function position(address[] memory universeVault, address user) public view returns (Position[] memory) {
        Position[] memory userPosition = new Position[](universeVault.length);
        for (uint256 i = 0; i < universeVault.length; i++) {
            userPosition[i] = _position(universeVault[i], user);
        }

        return userPosition;
    }

    /**
     * @notice returns vaults data & users position
     * @param universeVault the vault's address array
     * @param user the user's address
     */
    function positionByVault(address[] memory universeVault, address user)
        external
        view
        returns (Position[] memory userPosition, VaultData[] memory data)
    {
        userPosition = position(universeVault, user);
        data = getVaultDetail(universeVault);
    }

    /**
     * @notice returns vaults data & users position
     * @param user the user's address
     */
    function positionByAddress(address user)
        external
        view
        returns (Position[] memory userPosition, VaultData[] memory data)
    {
        userPosition = position(getAllVault(), user);
        data = getVaultDetail(getAllVault());
    }
}

contract ResolverV2UniverseFinance is UniverseFinanceResolver {
    string public constant name = "UniverseFinance-v1";
}
