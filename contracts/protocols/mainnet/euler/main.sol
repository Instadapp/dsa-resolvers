// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import "./helpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EulerResolver is EulerHelper {
    struct MarketsInfoAllSubAcc {
        MarketsInfoSubacc[] marketsInfo;
    }

    function getAllSubAccounts(address user)
        public
        pure
        returns (address[] memory subAccounts, uint256[] memory subAccountIds)
    {
        uint256 length = 256;
        subAccounts = new address[](length);
        subAccountIds = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address subAccount = getSubAccount(user, i);
            subAccounts[i] = subAccount;
            subAccountIds[i] = i;
        }
    }

    function getAllActiveSubAccounts(address user, address[] memory tokens)
        public
        view
        returns (uint256[] memory activeSubAccIds, address[] memory activeSubAcc)
    {
        (address[] memory subAccounts, ) = getAllSubAccounts(user);
        (bool[] memory activeSubAccBool, uint256 count) = getActiveSubAccounts(subAccounts, tokens);

        activeSubAccIds = new uint256[](count);
        activeSubAcc = new address[](count);
        uint256 j = 0;

        for (uint256 i = 0; i < subAccounts.length; i++) {
            if (activeSubAccBool[i] == true) {
                activeSubAccIds[j] = i;
                activeSubAcc[j] = subAccounts[i];
                j++;
            }
        }
    }

    function getPositions(
        address user,
        uint256[] memory subAccountIds,
        address[] memory tokens //0xabc00,(0,1,2,4,6)
    ) public view returns (AccountStatus[] memory accStatuses, MarketsInfoAllSubAcc[] memory marketsInfoAllSubAcc) {
        uint256 length = subAccountIds.length;
        Query[] memory qs = new Query[](length);
        marketsInfoAllSubAcc = new MarketsInfoAllSubAcc[](length);

        for (uint256 i = 0; i < length; i++) {
            address subAccount = getSubAccount(user, i);
            qs[i] = Query({ eulerContract: EULER_MAINNET, account: subAccount, markets: tokens });
        }

        Response[] memory response = new Response[](length);
        response = eulerView.doQueryBatch(qs);

        for (uint256 j = 0; j < length; j++) {
            (MarketsInfoSubacc[] memory marketsInfo, AccountStatus memory accStatus) = getSubaccInfo(response[j]);
            accStatuses[j] = accStatus;
            marketsInfoAllSubAcc[j] = MarketsInfoAllSubAcc({ marketsInfo: marketsInfo });
        }
    }

    function getPosition(address user, address[] memory tokens)
        public
        view
        returns (
            address[] memory subAccounts,
            bool[] memory activeSubAcc,
            AccountStatus[] memory accStatuses,
            MarketsInfoAllSubAcc[] memory marketsInfoAllSubAcc
        )
    {
        uint256 length = 256;
        uint256 count;

        (subAccounts, ) = getAllSubAccounts(user);
        (activeSubAcc, count) = getActiveSubAccounts(subAccounts, tokens);

        Query[] memory qs = new Query[](count);
        accStatuses = new AccountStatus[](count);
        marketsInfoAllSubAcc = new MarketsInfoAllSubAcc[](count);
        Response[] memory response = new Response[](count);

        for (uint256 i = 0; i < length; i++) {
            if (activeSubAcc[i]) {
                qs[i] = Query({ eulerContract: EULER_MAINNET, account: subAccounts[i], markets: tokens });
            }
        }

        response = eulerView.doQueryBatch(qs);

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
