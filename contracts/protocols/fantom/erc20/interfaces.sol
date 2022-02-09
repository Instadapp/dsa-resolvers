// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface TokenInterface {
    function balanceOf(address) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function decimals() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}
