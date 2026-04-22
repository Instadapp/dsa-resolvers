// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface TokenInterface {
    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}
