pragma solidity ^0.8.0;
pragma abicoder v2;

import { Helpers } from "./helpers.sol";

abstract contract UniverseFinanceResolver is Helpers {
    /**
     * @notice get universe vault detail info
     * @param universeVault the Universe Vault Address
     */
    function getVaultDetail(address universeVault) external view returns (VaultData memory) {
        return _vaultDetail(universeVault);
    }

    /**
     * @notice get user share info
     * @param universeVault the Universe Vault Address
     * @param user the user address
     */
    function getUserShareAmount(address universeVault, address user) external view returns (uint256, uint256) {
        return _userShareAmount(universeVault, user);
    }

    /**
     * @notice get user can withdraw amount
     * @param universeVault the Universe Vault Address
     * @param user the user address
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
     */
    function getUserDepositAmount(
        address universeVault,
        uint256 amount0,
        uint256 amount1
    ) external view returns (uint256, uint256) {
        return _depositAmount(universeVault, amount0, amount1);
    }
}

contract ResolverV2UniverseFinance is UniverseFinanceResolver {
    string public constant name = "UniverseFinance-v1";
}
