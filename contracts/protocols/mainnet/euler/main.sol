// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import "./helpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

/**
 *@title Euler Resolver
 *@dev get user position, account status, entered market list, token details and prices.
 */
contract EulerResolver is EulerHelper {
    function getPosition(address user, address[] memory tokens)
        public
        view
        returns (Response[] memory response, AccountStatus[] memory accStatus)
    {
        Query[] memory qs = new Query[](256);
        accStatus = new AccountStatus[](256);

        for (uint256 i = 0; i < 256; i++) {
            address subAccount = getSubAccount(user, i);

            qs[i] = Query({ eulerContract: EULER_MAINNET, account: subAccount, markets: tokens });

            accStatus[i] = getAccountStatus(subAccount);
        }

        response = new Response[](256);
        response = eulerView.doQueryBatch(qs);
    }
}

contract InstaEulerResolver is EulerResolver {
    string public constant name = "Euler-Resolver-v1.0";
}
