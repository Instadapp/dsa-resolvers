// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Helpers } from "./helpers.sol";
import { TokenInterface, VaultInterface, UserPosition } from "./interfaces.sol";

contract CompoundBlueEarnResolver is Helpers {
    function getUserPosition(address user, address[] memory vaultAddress) public view returns (UserPosition[] memory) {
        UserPosition[] memory _userPosition = new UserPosition[](vaultAddress.length);
        for (uint256 i = 0; i < vaultAddress.length; i++) {
            VaultInterface vaultToken = VaultInterface(vaultAddress[i]);

            address _underlyingAddress = vaultToken.asset();
            TokenInterface underlyingToken = TokenInterface(_underlyingAddress);

            _userPosition[i].vaultTokenBalance = vaultToken.balanceOf(user);
            _userPosition[i].underlyingTokenBalance = underlyingToken.balanceOf(user);
            _userPosition[i].vaultDetails = getVaultDetails(vaultAddress[i]);
        }

        return _userPosition;
    }
}
