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
        uint256 rewardsUnclaimed;
        uint256 rewardsLocked;
    }

    address internal constant mUsdToken = 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;
    address internal constant imUsdToken = 0x30647a72Dc82d7Fbb1123EA74716aB8A317Eac19;
    address internal constant imUsdVault = 0x78BefCa7de27d07DC6e71da295Cc2946681A6c7B;

    /**
     * @dev Retrieves Reward data from Vault
     * @notice This Data can be used to calculate rewards that are vested
     * @param _account address of the account to retrieve Reward data from
     * @return Reward[] array of Reward data
     */
    function getVestingData(address _account) internal view returns (Reward[] memory) {
        uint64 rewardCount = IBoostedSavingsVault(imUsdVault).userData(_account).rewardCount;

        Reward[] memory rewards = new Reward[](rewardCount);

        for (uint256 i = 0; i < rewardCount; i++) {
            rewards[i] = IBoostedSavingsVault(imUsdVault).userRewards(_account, i);
        }

        return rewards;
    }

    /**
     * @dev Retrieves Reward amounts
     * @notice Rewards are split up in 3 amounts
     * @param _account address of the account to retrieve Reward data from
     * @return earned       => immidiatly available
     * @return unclaimed    => earned + amounts that came out of vesting
     * @return locked       => locked in vesting
     */
    function getRewards(address _account)
        public
        view
        returns (
            uint256 earned,
            uint256 unclaimed,
            uint256 locked
        )
    {
        // Get rewards data first
        Reward[] memory rewards = getVestingData(_account);

        earned = IBoostedSavingsVault(imUsdVault).earned(_account);

        (unclaimed, , ) = IBoostedSavingsVault(imUsdVault).unclaimedRewards(_account);
        uint256 time = block.timestamp;

        for (uint256 i = 0; i < rewards.length; i++) {
            if (rewards[i].start > time) {
                locked += rewards[i].rate * (rewards[i].finish - rewards[i].start);
            } else if (rewards[i].finish > time) {
                locked += rewards[i].rate * (rewards[i].finish - time);
            }
        }
    }

    /**
     * @dev Retrieves the Vault Data
     * @param _account The account to retrieve the balance for
     * @return data as VaultData, aggregate information about the Vault for a given account
     */
    function getVaultData(address _account) external view returns (VaultData memory data) {
        data.credits = IBoostedSavingsVault(imUsdVault).rawBalanceOf(_account);
        data.balance = ISavingsContractV2(imUsdToken).creditsToUnderlying(data.credits);
        data.exchangeRate = ISavingsContractV2(imUsdToken).exchangeRate();

        // Get total locked amount
        (data.rewardsEarned, data.rewardsUnclaimed, data.rewardsLocked) = getRewards(_account);
    }
}
