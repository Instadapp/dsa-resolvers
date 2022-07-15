// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import "./helpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EulerResolver is EulerHelper {
    struct MarketsInfoAllSubAcc {
        MarketsInfoSubacc[] marketsInfo;
    }

    function getPosition(address user, address[] memory tokens)
        public
        view
        returns (AccountStatus[] memory accStatuses, MarketsInfoAllSubAcc[] memory marketsInfoAllSubAcc)
    {
        uint256 length = 256;
        Query[] memory qs = new Query[](length);
        accStatuses = new AccountStatus[](length);
        marketsInfoAllSubAcc = new MarketsInfoAllSubAcc[](length);

        address[] memory allSubAcc = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            address subAccount = getSubAccount(user, i);
            allSubAcc[i] = subAccount;
            qs[i] = Query({ eulerContract: EULER_MAINNET, account: subAccount, markets: tokens });
        }

        Response[] memory response = new Response[](length);
        response = eulerView.doQueryBatch(qs);

        bool[] memory activeSubAcc = getActiveSubaccounts(response);

        for (uint256 j = 0; j < length; j++) {
            if (activeSubAcc[j]) {
                (MarketsInfoSubacc[] memory marketsInfo, AccountStatus memory accStatus) = getSubaccInfo(response[j]);

                accStatuses[j] = accStatus;
                marketsInfoAllSubAcc[j] = MarketsInfoAllSubAcc({ marketsInfo: marketsInfo });
            }
        }
    }
}

contract InstaEulerResolver is EulerResolver {
    string public constant name = "Euler-Resolver-v1.0";
}
