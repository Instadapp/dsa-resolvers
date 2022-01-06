// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./interfaces.sol";
import "./helpers.sol";

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
        //

        data.credits = IStakingRewardsWithPlatformToken(imUsdVault).balanceOf(_account);
        data.balance = ISavingsContractV2(imUsdToken).creditsToUnderlying(data.credits);
        data.exchangeRate = ISavingsContractV2(imUsdToken).exchangeRate();

        // Get total locked amount
        (data.rewardsEarned, data.platformRewards) = getRewards(_account);
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

contract InstaPMstableResolver is Resolver {
    string public constant name = "mStable-Polygon-Resolver-v1";
}
