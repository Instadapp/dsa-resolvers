// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import "./helpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EulerResolver is EulerHelper {
    function getAllActiveSubAccounts(address user, address[] memory tokens)
        public
        view
        returns (SubAccount[] memory activeSubAccounts)
    {
        SubAccount[] memory subAccounts = getAllSubAccounts(user);
        (bool[] memory activeSubAccBool, uint256 count) = getActiveSubAccounts(subAccounts, tokens);

        activeSubAccounts = new SubAccount[](count);
        uint256 j = 0;

        for (uint256 i = 0; i < subAccounts.length; i++) {
            if (activeSubAccBool[i] == true) {
                activeSubAccounts[j].id = i;
                activeSubAccounts[j].subAccountAddress = subAccounts[i].subAccountAddress;
                j++;
            }
        }
    }

    function getPositionOfActiveSubAccounts(
        address user,
        uint256[] memory activeSubAccountIds,
        address[] memory tokens
    ) public view returns (Position[] memory positions) {
        uint256 length = activeSubAccountIds.length;
        address[] memory subAccountAddresses = new address[](length);

        Query[] memory qs = new Query[](length);

        for (uint256 i = 0; i < length; i++) {
            subAccountAddresses[i] = getSubAccountAddress(user, activeSubAccountIds[i]);
            qs[i] = Query({ eulerContract: EULER_MAINNET, account: subAccountAddresses[i], markets: tokens });
        }

        Response[] memory response = new Response[](length);
        response = eulerView.doQueryBatch(qs);

        for (uint256 j = 0; j < length; j++) {
            (MarketsInfoSubacc[] memory marketsInfo, AccountStatus memory accountStatus) = getSubAccountInfo(
                response[j]
            );

            positions[j] = Position({
                id: activeSubAccountIds[j],
                subAccountAddress: subAccountAddresses[j],
                accountStatus: accountStatus,
                marketsInfoSubAcc: marketsInfo
            });
        }
    }

    function getPositionsOfUser(address user, address[] memory tokens)
        public
        view
        returns (Position[] memory activePositions)
    {
        uint256 length = 256;

        SubAccount[] memory subAccounts = getAllSubAccounts(user);
        (bool[] memory activeSubAcc, uint256 count) = getActiveSubAccounts(subAccounts, tokens);

        Query[] memory qs = new Query[](count);
        Response[] memory response = new Response[](count);

        SubAccount[] memory activeSubAccounts = new SubAccount[](count);
        uint256 k;

        for (uint256 i = 0; i < length; i++) {
            if (activeSubAcc[i]) {
                qs[i] = Query({
                    eulerContract: EULER_MAINNET,
                    account: subAccounts[i].subAccountAddress,
                    markets: tokens
                });

                activeSubAccounts[k] = SubAccount({
                    id: subAccounts[i].id,
                    subAccountAddress: subAccounts[i].subAccountAddress
                });

                k++;
            }
        }

        response = eulerView.doQueryBatch(qs);

        activePositions = new Position[](count);

        for (uint256 j = 0; j < count; j++) {
            (MarketsInfoSubacc[] memory marketsInfo, AccountStatus memory accountStatus) = getSubAccountInfo(
                response[j]
            );

            activePositions[j] = Position({
                id: activeSubAccounts[j].id,
                subAccountAddress: activeSubAccounts[j].subAccountAddress,
                accountStatus: accountStatus,
                marketsInfoSubAcc: marketsInfo
            });
        }
    }
}

contract InstaEulerResolver is EulerResolver {
    string public constant name = "Euler-Resolver-v1.0";
}
