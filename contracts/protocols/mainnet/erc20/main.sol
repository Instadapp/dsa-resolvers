// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";

contract Resolver {
    struct TokenData {
        bool isToken;
        string name;
        string symbol;
        uint256 decimals;
    }

    function getTokenDetails(address[] memory tknAddress) public view returns (TokenData[] memory) {
        TokenData[] memory tokenDatas = new TokenData[](tknAddress.length);
        for (uint256 i = 0; i < tknAddress.length; i++) {
            if (tknAddress[i] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                tokenDatas[i] = TokenData(true, "ETHER", "ETH", 18);
            } else {
                TokenInterface token = TokenInterface(tknAddress[i]);
                bool isToken = true;

                try token.symbol() {} catch {
                    isToken = false;
                    continue;
                }

                try token.name() {} catch {
                    isToken = false;
                    continue;
                }

                try token.decimals() {} catch {
                    isToken = false;
                    continue;
                }

                tokenDatas[i] = TokenData(true, token.name(), token.symbol(), token.decimals());
            }
        }
        return tokenDatas;
    }

    function getBalances(address owner, address[] memory tknAddress) public view returns (uint256[] memory) {
        uint256[] memory tokensBal = new uint256[](tknAddress.length);
        for (uint256 i = 0; i < tknAddress.length; i++) {
            if (tknAddress[i] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                tokensBal[i] = owner.balance;
            } else {
                TokenInterface token = TokenInterface(tknAddress[i]);
                tokensBal[i] = token.balanceOf(owner);
            }
        }
        return tokensBal;
    }

    function getAllowances(
        address owner,
        address spender,
        address[] memory tknAddress
    ) public view returns (uint256[] memory) {
        uint256[] memory tokenAllowances = new uint256[](tknAddress.length);
        for (uint256 i = 0; i < tknAddress.length; i++) {
            if (tknAddress[i] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                tokenAllowances[i] = 0;
            } else {
                TokenInterface token = TokenInterface(tknAddress[i]);
                tokenAllowances[i] = token.allowance(owner, spender);
            }
        }
        return tokenAllowances;
    }
}

contract InstaERC20Resolver is Resolver {
    string public constant name = "ERC20-Resolver-v1.1";
}
