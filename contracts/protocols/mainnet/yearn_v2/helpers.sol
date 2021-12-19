// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { DSMath } from "../../../utils/dsmath.sol";
import "./interfaces.sol";

contract Helpers is DSMath {
    /**
     * @dev get Yearn Registry
     */
    function getRegistry() public pure returns (YearnRegistryInterface) {
        return YearnRegistryInterface(0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804);
    }

    struct VaultData {
        address vaultLatestVersion;
        address vault;
        address want;
        uint256 pricePerShare;
        uint256 availableDepositLimit;
        uint256 totalAssets;
        uint256 balanceOf;
        uint256 wantBalanceOf;
        uint256 expectedShareValue;
        uint256 decimals;
        bool isDeprecated;
        bool emergencyShutdown;
    }
}
