// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";

contract Resolver {
    address internal constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct AllowanceRequest {
        address token;
        address user;
        address target;
    }

    struct AllowanceData {
        address token;
        address user;
        address target;
        uint256 allowance;
        uint256 balance;
    }

    function getAllowances(AllowanceRequest[] memory requests) public view returns (AllowanceData[] memory) {
        AllowanceData[] memory allowances = new AllowanceData[](requests.length);
        for (uint256 i = 0; i < requests.length; i++) {
            AllowanceRequest memory req = requests[i];
            uint256 allowance = 0;
            uint256 balance;
            if (req.token == ETH_ADDR) {
                balance = req.user.balance;
            } else {
                TokenInterface token = TokenInterface(req.token);
                allowance = token.allowance(req.user, req.target);
                balance = token.balanceOf(req.user);
            }
            allowances[i] = AllowanceData(req.token, req.user, req.target, allowance, balance);
        }
        return allowances;
    }
}

contract InstaAllowanceResolver is Resolver {
    string public constant name = "Allowance-Resolver-v1.0";
}
