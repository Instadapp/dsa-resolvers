//SPDX-License-Identifier: MIT
import "./helpers.sol";

contract JoeResolver is TraderJoeHelper {
    function getPosition(address owner, address[] memory jTokens) public returns (UserData memory) {
        return getTraderjoeData(owner, jTokens);
    }
}
