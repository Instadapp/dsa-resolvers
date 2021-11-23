pragma solidity ^0.7.6;
pragma abicoder v2;

import {Helpers} from "./helpers.sol";

abstract contract UniverseFinanceResolver is Helpers {

    /**
     * @notice get all Universe Working Vaults
     * @return address list
     */
    function getAllVault() external view returns(address[] memory) {
        return _officialVaults();
    }

    /**
     * @notice get universe vault detail info
     * @param universeVault the Universe Vault Address
     * @return [token0Address, token1Address, vaultMaxToken0Amount, vaultMaxToken1Amount, maxSingleDepositFofToken0,
     maxSingleDepositFofToken1, totalToken0Amount, totalTotal1Amount, utilizationOfToken0, utilizationOfToken1]
     */
    function getVaultDetail(address universeVault) external view returns(VaultData memory) {
        return _vaultDetail(universeVault);
    }

    /**
     * @notice get user share info
     * @param universeVault the Universe Vault Address
     * @param user the user address
     * @return shareToken0Amount and shareToken1Amount
     */
    function getUserShareAmount(address universeVault, address user) external view returns(uint256, uint256) {
        return _userShareAmount(universeVault, user);
    }

    /**
    * @notice get user share info list
    * @param universeVaults the Universe Vault Address arrays
    * @param user the user address
    */
    function getUserShareAmountList(address[] memory universeVaults, address user) external view returns(uint256[2][] memory data) {
        uint len = universeVaults.length;
        if(len > 0){
            data = new uint256[2][](len);
            for(uint i; i < len; i++){
                (uint256 share0, uint256 share1) = _userShareAmount(universeVaults[i], user);
                data[i] = [share0, share1];
            }
        }
    }

    /**
     * @notice get user can withdraw amount
     * @param universeVault the Universe Vault Address
     * @param user the user address
     * @return token0Amount  token1Amount
     */
    function getUserWithdrawAmount(address universeVault, address user) external view returns(uint256, uint256) {
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
    ) external view returns(uint256, uint256) {
        return _depositAmount(universeVault, amount0, amount1);
    }

}

contract ResolverV2UniverseFinance is UniverseFinanceResolver {
    string public constant name = "UniverseFinance-v1";
}
