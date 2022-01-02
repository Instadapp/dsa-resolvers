// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
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
     * @param _amount Amount of bAssets (or mUSD) to be withdrawn
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
     * @dev Retrieves the Vault Balance
     * @param _account The account to retrieve the balance for
     * @return struct vaultBalance (balance, credits, rewardsClaimable)
     */
    function getVaultBalance(address _account) external view returns (VaultBalance memory) {
        //
        VaultBalance memory data;

        data.credits = IERC20(imUsdVault).balanceOf(_account);
        data.balance = ISavingsContractV2(imUsdToken).creditsToUnderlying(data.credits);
        data.exchangeRage = ISavingsContractV2(imUsdToken).exchangeRate();
        data.rewardsClaimable = IBoostedSavingsVault(imUsdVault).earned(_account);

        return data;
    }

    // Calc underlying to Credits
    // Calc Credits to underlying

    // swap estimate

    /***************************************
                    Internal
    ****************************************/
}

contract InstaMstableResolver is Resolver {
    string public constant name = "mStable-Mainnet-Resolver-v1";
}
