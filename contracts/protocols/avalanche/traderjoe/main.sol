//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./helpers.sol";

contract JoeResolver is TraderJoeHelper {
    function getPosition(address owner, address[] memory jTokens) public returns (UserData memory) {
        return getTraderjoeData(owner, jTokens);
    }

    function getPositionAll(address owner) public returns (UserData memory) {
        JToken[] memory joeTokens = Joetroller(getJoetroller()).getAllMarkets();
        address[] memory jTokens = new address[](joeTokens.length);
        for (uint256 i = 0; i < joeTokens.length; i++) {
            jTokens[i] = address(joeTokens[i]);
        }
        return getPosition(owner, jTokens);
    }
}
