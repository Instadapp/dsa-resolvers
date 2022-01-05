// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./interfaces.sol";
import "./helpers.sol";

import "hardhat/console.sol";

contract Resolver is Helpers {
    //
    /***************************************
                    CORE
    ****************************************/
    //
    /**
     * @dev Estimates deposits
     * @notice With mUSD is 1:1, bAssets are calculated
     * @param _input The input token to estimate
     * @param _amount Amount of bAssets (or mUSD) to be deposited
     * @return estimation of output
     */
    function estimateDeposit(address _input, uint256 _amount) public view returns (uint256) {
        //
        if (_input == mUsdToken) {
            // Check if mUSD
            // mUSD is 1:1, doesn't need to be minted
            return _amount;
        } else if (IMasset(mUsdToken).bAssetIndexes(_input) != 0) {
            // Check if bAsset
            // Estimate mint
            return IMasset(mUsdToken).getMintOutput(_input, _amount);
        } else {
            // Supplied token is neither mUSD nor bAsset, use function to supply a feeder pool address
            revert("Token is not a bAsset or mUSD");
        }
    }

    /**
     * @dev Estimates deposits via Feeder Pool
     * @notice Estimates the minted mUSD amount via Feeder Pool
     * @param _input The input token to estimate
     * @param _amount Amount of bAssets (or mUSD) to be deposited
     * @param _path address of the Feeder Pool
     * @return estimation of output
     */
    function estimateDeposit(
        address _input,
        uint256 _amount,
        address _path
    ) public view returns (uint256) {
        return IFeederPool(_path).getSwapOutput(_input, mUsdToken, _amount);
    }

    /**
     * @dev Estimates withdrawals to mUSD or bAsset
     * @notice Estimates the output, with mUSD is 1:1, bAssets are calculated
     * @param _output The output token to estimate
     * @param _amount Amount of bAssets (or mUSD) to be withdrawn
     * @return estimation of output
     */
    function estimateWithdrawal(address _output, uint256 _amount) public view returns (uint256) {
        //
        if (_output == mUsdToken) {
            // Check if mUSD
            // mUSD is 1:1, doesn't need to be minted
            return _amount;
        } else if (IMasset(mUsdToken).bAssetIndexes(_output) != 0) {
            // Check if bAsset
            // Estimate mint
            return IMasset(mUsdToken).getRedeemOutput(_output, _amount);
        } else {
            // Supplied token is neither mUSD nor bAsset, use function to supply a feeder pool address
            revert("Token is not a bAsset or mUSD");
        }
    }

    /**
     * @dev Estimates withdrawals via Feeder Pool
     * @notice Estimates the output via Feeder Pool
     * @param _output The output token to estimate
     * @param _amount Amount to be withdrawn
     * @param _path address of the Feeder Pool
     * @return estimation of output
     */
    function estimateWithdrawal(
        address _output,
        uint256 _amount,
        address _path
    ) public view returns (uint256) {
        return IFeederPool(_path).getSwapOutput(mUsdToken, _output, _amount);
    }

    // function getUserData(address _account) external view returns (UserData[] memory data) {
    function getVestingData(address _account) public view returns (Reward[] memory) {
        //
        uint64 rewardCount = IBoostedSavingsVault(imUsdVault).userData(_account).rewardCount;

        Reward[] memory rewards = new Reward[](rewardCount);

        for (uint256 i = 0; i < rewardCount; i++) {
            rewards[i] = IBoostedSavingsVault(imUsdVault).userRewards(_account, i);
        }

        return rewards;
    }

    function getVestingAmounts(address _account)
        public
        view
        returns (
            uint256 earned,
            uint256 unclaimed,
            uint256 locked
        )
    {
        //
        // Get rewards data first
        Reward[] memory rewards = getVestingData(_account);

        earned = IBoostedSavingsVault(imUsdVault).earned(_account);

        (unclaimed, , ) = IBoostedSavingsVault(imUsdVault).unclaimedRewards(_account);
        locked = 0;
        uint256 time = block.timestamp;

        for (uint256 i = 0; i < rewards.length; i++) {
            if (rewards[i].start > time) {
                locked += rewards[i].rate * (rewards[i].finish - rewards[i].start);
            } else if (rewards[i].finish > time) {
                locked += rewards[i].rate * (rewards[i].finish - time);
                // unclaimed += rewards[i].rate * (time - rewards[i].start);
            } else {
                // unclaimed += rewards[i].rate * (rewards[i].finish - rewards[i].start);
            }
        }
    }

    /**
     * @dev Retrieves the Vault Data
     * @param _account The account to retrieve the balance for
     */
    function getVaultData(address _account) external view returns (VaultData memory data) {
        //
        // uint256 rewards;
        // uint256 earned;
        data.credits = IBoostedSavingsVault(imUsdVault).rawBalanceOf(_account);
        data.balance = ISavingsContractV2(imUsdToken).creditsToUnderlying(data.credits);
        data.exchangeRate = ISavingsContractV2(imUsdToken).exchangeRate();

        // Get total locked amount
        (data.rewardsEarned, data.rewardsUnclaimed, data.rewardsLocked) = getVestingAmounts(_account);
    }

    /**
     * @dev Estimates a swap, given the input and output tokens
     * @notice Estimates the output, mUSD to bAsset, or bAsset to mUSD, or bAsset to bAsset
     * @param _input The input token to estimate
     * @param _output The output token to estimate
     * @param _amount Amount of bAssets (or mUSD) to be swapped
     * @return estimation of output
     */
    function estimateSwap(
        address _input,
        address _output,
        uint256 _amount
    ) public view returns (uint256) {
        //
        require(_input != _output, "Invalid swap");

        if (_input == mUsdToken) {
            // Input is mUSD => redeem to bAsset
            return IMasset(mUsdToken).getRedeemOutput(_output, _amount);
        } else if (_output == mUsdToken) {
            // Input is bAsset and output is mUSD => mint
            return IMasset(mUsdToken).getMintOutput(_input, _amount);
        } else {
            // Input is bAsset and output is bAsset => swap
            return IMasset(mUsdToken).getSwapOutput(_input, _output, _amount);
        }
    }

    /**
     * @dev Estimates a swap, given the input and output tokens
     * @notice Estimates the output using the given Feeder Pool
     * @param _input The input token to estimate
     * @param _output The output token to estimate
     * @param _amount Amount of bAssets (or mUSD) to be swapped
     * @param _path address of the Feeder Pool
     * @return estimation of output
     */

    function estimateSwap(
        address _input,
        address _output,
        uint256 _amount,
        address _path
    ) public view returns (uint256) {
        //
        return IFeederPool(_path).getSwapOutput(_input, _output, _amount);
    }
}

contract InstaMstableResolver is Resolver {
    string public constant name = "mStable-Mainnet-Resolver-v1";
}
