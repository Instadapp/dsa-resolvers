//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { DSMath } from "../../../utils/dsmath.sol";
import "./interface.sol";

contract Helpers is DSMath {
    address internal constant universeReslover = 0x7466420dC366DF67b55daeDf19f8d37a346Fa7C8;
    uint8 internal constant vaultVersion = 1;

    function _depositAmount(
        address universeVault,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint256, uint256) {
        return IVaultV3(universeVault).getShares(amount0, amount1);
    }

    function _withdrawAmount(
        address universeVault,
        uint256 share0,
        uint256 share1
    ) internal view returns (uint256, uint256) {
        return IVaultV3(universeVault).getBals(share0, share1);
    }

    function _userShareAmount(address universeVault, address user) internal view returns (uint256, uint256) {
        return IVaultV3(universeVault).getUserShares(user);
    }

    struct VaultData {
        address token0;
        address token1;
        uint256 maxToken0Amt;
        uint256 maxToken1Amt;
        uint256 maxSingeDepositAmt0;
        uint256 maxSingeDepositAmt1;
        uint256 total0;
        uint256 total1;
        uint256 utilizationRate0;
        uint256 utilizationRate1;
        uint256 version;
    }

    struct Position {
        uint256 share0;
        uint256 share1;
        uint256 amount0;
        uint256 amount1;
        uint256 version;
    }

    function _vaultDetail(address universeVault) internal view returns (VaultData memory vaultData) {
        IVaultV3 vault = IVaultV3(universeVault);
        vaultData.token0 = vault.token0();
        vaultData.token1 = vault.token1();
        IVaultV3.MaxShares memory maxShare = vault.maxShares();
        vaultData.maxToken0Amt = maxShare.maxToken0Amt;
        vaultData.maxToken1Amt = maxShare.maxToken1Amt;
        vaultData.maxSingeDepositAmt0 = maxShare.maxSingeDepositAmt0;
        vaultData.maxSingeDepositAmt1 = maxShare.maxSingeDepositAmt1;
        (uint256 total0, uint256 total1, , , uint256 utilizationRate0, uint256 utilizationRate1) = vault
            .getTotalAmounts();
        vaultData.total0 = total0;
        vaultData.total1 = total1;
        vaultData.utilizationRate0 = utilizationRate0;
        vaultData.utilizationRate1 = utilizationRate1;
        vaultData.version = vaultVersion;
    }

    function _officialVaults() internal view returns (address[] memory vaults) {
        return IUniverseResolver(universeReslover).getAllVaultAddress();
    }

    function _vaultData(address[] memory universeVaults) internal view returns (VaultData[] memory) {
        VaultData[] memory data = new VaultData[](universeVaults.length);
        for (uint256 i = 0; i < universeVaults.length; i++) {
            data[i] = _vaultDetail(universeVaults[i]);
        }
        return data;
    }

    function _decimals(address vault) internal view returns (uint8 decimal0, uint8 decimal1) {
        address token0 = IVaultV3(vault).token0();
        address token1 = IVaultV3(vault).token1();
        decimal0 = IERC20(token0).decimals();
        decimal1 = IERC20(token1).decimals();
    }

    function _position(address vault, address user) internal view returns (Position memory userPosition) {
        (userPosition.share0, userPosition.share1) = _userShareAmount(vault, user);
        (userPosition.amount0, userPosition.amount1) = _withdrawAmount(vault, userPosition.share0, userPosition.share1);
        userPosition.version = vaultVersion;
    }
}
