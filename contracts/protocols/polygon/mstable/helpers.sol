// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { DSMath } from "../../../utils/dsmath.sol";
import "./interfaces.sol";

contract Helpers is DSMath {
    struct VaultData {
        uint256 credits;
        uint256 balance;
        uint256 exchangeRate;
        uint256 rewardsEarned;
        uint256 platformRewards;
    }

    address internal constant mUsdToken = 0xE840B73E5287865EEc17d250bFb1536704B43B21;
    address internal constant imUsdToken = 0x5290Ad3d83476CA6A2b178Cd9727eE1EF72432af;
    address internal constant imUsdVault = 0x32aBa856Dc5fFd5A56Bcd182b13380e5C855aa29;

    /**
     * @dev Retrieves Reward amounts
     * @notice Rewards are two tokens
     * @param _account address of the account to retrieve Reward data from
     * @return rewards => MTA
     * @return platformRewards => wMATIC
     */

    function getRewards(address _account) public view returns (uint256, uint256) {
        return IStakingRewardsWithPlatformToken(imUsdVault).earned(_account);
    }

    /**
     * @dev Retrieves the Vault Data
     * @param _account The account to retrieve the balance for
     * @return data as VaultData, aggregate information about the Vault for a given account
     */
    function getVaultData(address _account) external view returns (VaultData memory data) {
        data.credits = IStakingRewardsWithPlatformToken(imUsdVault).balanceOf(_account);
        data.balance = ISavingsContractV2(imUsdToken).creditsToUnderlying(data.credits);
        data.exchangeRate = ISavingsContractV2(imUsdToken).exchangeRate();

        // Get total locked amount
        (data.rewardsEarned, data.platformRewards) = getRewards(_account);
    }
}
