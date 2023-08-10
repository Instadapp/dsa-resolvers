// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";

contract Resolver {
    struct VaultData {
        bool isToken;
        string name;
        string symbol;
        uint256 decimals;
        address asset;
        uint256 totalAssets;
    }

    function getVaultDetails(address vaultAddress) public view returns (VaultData memory) {
        VaultData memory _vaultData;
        VaultInterface vaultToken = VaultInterface(vaultAddress);
        bool isToken = true;

        try vaultToken.symbol() {} catch {
            isToken = false;
        }

        try vaultToken.name() {} catch {
            isToken = false;
        }

        try vaultToken.decimals() {} catch {
            isToken = false;
        }

        _vaultData = VaultData(
            isToken,
            vaultToken.name(),
            vaultToken.symbol(),
            vaultToken.decimals(),
            vaultToken.asset(),
            vaultToken.totalAssets()
        );

        return _vaultData;
    }

    function getPosition(address owner, address vaultAddress) public view returns (uint256, uint256) {
        uint256 _underlyingBalance;
        uint256 _vaultBalance;

        VaultInterface vaultToken = VaultInterface(vaultAddress);

        address _underlyingAddress = vaultToken.asset();
        TokenInterface underlyingToken = TokenInterface(_underlyingAddress);

        _underlyingBalance = underlyingToken.balanceOf(owner);
        _vaultBalance = vaultToken.balanceOf(owner);

        return (_underlyingBalance, _vaultBalance);
    }

    function getAllowances(address owner, address vaultAddress) public view returns (uint256) {
        uint256 _tokenAllowance;

        VaultInterface vaultToken = VaultInterface(vaultAddress);
        _tokenAllowance = vaultToken.allowance(owner, vaultAddress);
        return _tokenAllowance;
    }
}

contract InstaERC4626Resolver is Resolver {
    string public constant name = "ERC4626-Resolver-v1.1";
}
