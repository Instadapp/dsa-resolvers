//SPDX-License-Identifier: MIT

contract JoeResolver is TraderJoeHelper {
    function getPosition(address owner, address[] memory jTokens) public returns (UserData memory) {
        return getTraderjoeData(owner, jTokens);
    }
}
