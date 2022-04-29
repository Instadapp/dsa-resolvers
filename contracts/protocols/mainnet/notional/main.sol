// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    /// @notice Returns all account details in a single view
    /// @param account account address
    function getAccount(address account)
        external
        view
        returns (
            AccountContext memory accountContext,
            AccountBalance[] memory accountBalances,
            PortfolioAsset[] memory portfolio
        )
    {
        return notional.getAccount(account);
    }

    /// @notice Returns free collateral of an account along with an array of the individual net available
    /// asset cash amounts
    /// @param account account address
    function getFreeCollateral(address account) external view returns (int256, int256[] memory) {
        return notional.getFreeCollateral(account);
    }

    /// @notice Returns a currency and its corresponding asset rate and ETH exchange rates.
    /// @dev Note that this does not recalculate cToken interest rates, it only retrieves the latest stored rate.
    /// @param currencyId currency ID
    function getCurrencyAndRates(uint16 currencyId)
        external
        view
        returns (
            Token memory assetToken,
            Token memory underlyingToken,
            ETHRate memory ethRate,
            AssetRateParameters memory assetRate
        )
    {
        return notional.getCurrencyAndRates(currencyId);
    }

    /// @notice Returns the asset settlement rate for a given maturity
    /// @param currencyId currency ID
    /// @param maturity fCash maturity
    function getSettlementRate(uint16 currencyId, uint40 maturity) external view returns (AssetRateParameters memory) {
        return notional.getSettlementRate(currencyId, maturity);
    }

    /// @notice Returns all currently active markets for a currency
    /// @param currencyId currency ID
    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory) {
        return notional.getActiveMarkets(currencyId);
    }

    /// @notice Returns the claimable incentives for all nToken balances
    /// @param account The address of the account which holds the tokens
    /// @param blockTime The block time when incentives will be minted
    /// @return Incentives an account is eligible to claim
    function nTokenGetClaimableIncentives(address account, uint256 blockTime) external view returns (uint256) {
        return notional.nTokenGetClaimableIncentives(account, blockTime);
    }

    /// @notice Returns the nTokens that will be minted when some amount of asset tokens are deposited
    /// @param currencyId currency ID
    /// @param amountToDepositExternalPrecision amount of cash to deposit in external precision
    function calculateNTokensToMint(uint16 currencyId, uint88 amountToDepositExternalPrecision)
        external
        view
        returns (uint256)
    {
        return notional.calculateNTokensToMint(currencyId, amountToDepositExternalPrecision);
    }

    /// @notice Returns the fCash amount to send when given a cash amount
    /// @dev Use this version for lending
    /// @param currencyId currency ID
    /// @param cashUnderlying cash deposit amount of the underlying in external precision
    /// @param marketIndex market index used for the calculation
    /// @param blockTime block time used for the calculation
    /// @param maturity fCash maturity used for the calculate
    /// @param defaultAnnualizedSlippage default slippage amount
    function getLendfCashAmount(
        uint16 currencyId,
        int256 cashUnderlying,
        uint8 marketIndex,
        uint256 blockTime,
        uint256 maturity,
        int128 defaultAnnualizedSlippage
    )
        external
        view
        returns (
            int256,
            int256,
            bytes32
        )
    {
        int256 netCashToAccount = getNetCashToAccount(currencyId, cashUnderlying);

        if (netCashToAccount == 0) return (0, 0, bytes32(0));

        // prettier-ignore
        (
            /* int256 fCashAmount */, 
            int256 exchangeRatePostSlippage,
            int256 annualizedRate
        ) = calculatefCashAndExchangeRate(
            currencyId,
            netCashToAccount,
            marketIndex,
            blockTime,
            maturity,
            defaultAnnualizedSlippage
        );

        // Calculate annualized slippage rate
        if (annualizedRate < 0) annualizedRate = 0;

        // If slippage rate is zero then interest rates are so low that slippage may take the lending
        // below zero.This will only occur if interest rates are below the slippage amount, currently
        // set to 50 basis points(0.50 % annualized)
        require(annualizedRate != 0, "Insufficient liquidity");

        // When lending the cash amount required for the reported fCash may undershoot what is required.
        // We use the exchange rate post slippage to get a lower fCash amount to ensure that the deposited
        // cash will be able to get sufficient fCash. If the rate does not slip then the account will end
        // up lending slightly less cash at a better rate.
        int256 fCashAmount = (netCashToAccount * exchangeRatePostSlippage) / RATE_PRECISION;

        return (fCashAmount, annualizedRate, encodeLendTrade(marketIndex, fCashAmount, annualizedRate));
    }

    /// @notice Returns the fCash amount to send when given a cash amount
    /// @dev Use this version for borrowing
    /// @param currencyId currency ID
    /// @param cashUnderlying cash deposit amount of the underlying in external precision
    /// @param marketIndex market index used for the calculation
    /// @param blockTime block time used for the calculation
    /// @param maturity fCash maturity used for the calculate
    /// @param defaultAnnualizedSlippage default slippage amount
    function getBorrowfCashAmount(
        uint16 currencyId,
        int256 cashUnderlying,
        uint8 marketIndex,
        uint256 blockTime,
        uint256 maturity,
        int128 defaultAnnualizedSlippage
    )
        external
        view
        returns (
            int256,
            int256,
            bytes32
        )
    {
        int256 netCashToAccount = getNetCashToAccount(currencyId, cashUnderlying);

        if (netCashToAccount == 0) return (0, 0, bytes32(0));

        // prettier-ignore
        (
            int256 fCashAmount, 
            int256 exchangeRatePostSlippage, 
            int256 annualizedRate
        ) = calculatefCashAndExchangeRate(
            currencyId,
            netCashToAccount,
            marketIndex,
            blockTime,
            maturity,
            defaultAnnualizedSlippage
        );

        fCashAmount = (fCashAmount * exchangeRatePostSlippage) / RATE_PRECISION;

        // Return positive borrow amount
        if (fCashAmount <= 0) fCashAmount *= -1;

        return (fCashAmount, annualizedRate, encodeBorrowTrade(marketIndex, fCashAmount, annualizedRate));
    }
}

contract InstaNotionalResolver is Resolver {
    string public constant name = "Notional-Resolver-v1";
}
