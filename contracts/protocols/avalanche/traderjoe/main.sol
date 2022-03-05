//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./helpers.sol";

contract JoeResolver is TraderJoeHelper {
    function getPosition(address owner, address[] memory jTokens) public returns (UserData memory) {
        return getTraderjoeData(owner, jTokens);
    }

    function getPositionAll(address owner) public returns (UserData memory) {
        return getPosition(owner, getAllJTokens());
    }
}
