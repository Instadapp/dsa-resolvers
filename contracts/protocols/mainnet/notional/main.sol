// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
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

    function getFreeCollateral(address account) external view returns (int256, int256[] memory) {
        return notional.getFreeCollateral(account);
    }

    /// @notice Returns a currency and its corresponding asset rate and ETH exchange rates.
    /// @dev Note that this does not recalculate cToken interest rates, it only retrieves the latest stored rate.
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

    function getSettlementRate(uint16 currencyId, uint40 maturity) external view returns (AssetRateParameters memory) {
        return notional.getSettlementRate(currencyId, maturity);
    }

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory) {
        return notional.getActiveMarkets(currencyId);
    }

    function nTokenGetClaimableIncentives(address account, uint256 blockTime) external view returns (uint256) {
        return notional.nTokenGetClaimableIncentives(account, blockTime);
    }

    function calculateNTokensToMint(uint16 currencyId, uint88 amountToDepositExternalPrecision)
        external
        view
        returns (uint256)
    {
        return notional.calculateNTokensToMint(currencyId, amountToDepositExternalPrecision);
    }

    function getLendfCashAmount(
        uint16 currencyId,
        uint256 marketIndex,
        uint256 blockTime,
        uint256 maturity,
        int128 defaultAnnualizedSlippage
    ) external view returns (int256) {
        // prettier-ignore
        (
            /* Token memory assetToken */,
            /* Token memory underlyingToken */,
            /* ETHRate memory ethRate */,
            AssetRateParameters memory assetRate
        ) = notional.getCurrencyAndRates(currencyId);

        // prettier-ignore
        (            
            /* AccountContext memory accountContext */,
            AccountBalance[] memory accountBalances,
            /* PortfolioAsset[] memory portfolio */
        ) = notional.getAccount(address(this));

        int256 netCashToAccount = accountBalances[currencyId].cashBalance * assetRate.rate;

        require(
            netCashToAccount >= type(int88).min && netCashToAccount <= type(int88).max,
            "netCashToAccount overflow"
        );

        int256 fCashAmount = notional.getfCashAmountGivenCashAmount(
            currencyId,
            int88(netCashToAccount),
            marketIndex,
            blockTime
        );

        // exchangeRate = abs(fCashAmount * RATE_PRECISION / netCashToAccount)
        int256 exchangeRate = (fCashAmount * RATE_PRECISION) / netCashToAccount;
        if (exchangeRate < 0) exchangeRate *= -1;

        int256 exchangeSlippageFactor = interestToExchangeRate(defaultAnnualizedSlippage, blockTime, maturity);

        // Exchange rates are non-linear so we apply slippage using the exponent identity:
        // exchangeRatePostSlippage = e^((r + delta) * t)
        // exchangeRate = e^(r * t)
        // slippageFactor = e^(delta * t)
        // exchangeRatePostSlippage = exchangeRate * slippageFactor
        int256 exchangeRatePostSlippage = (exchangeRate * exchangeSlippageFactor) / RATE_PRECISION;

        int256 slippageRate = exchangeToInterestRate(exchangeRatePostSlippage, blockTime, maturity);

        // If slippage rate is zero then interest rates are so low that slippage may take the lending
        // below zero.This will only occur if interest rates are below the slippage amount, currently
        // set to 50 basis points(0.50 % annualized)
        require(slippageRate != 0, "Insufficient liquidity");

        // When lending the cash amount required for the reported fCash may undershoot what is required.
        // We use the exchange rate post slippage to get a lower fCash amount to ensure that the deposited
        // cash will be able to get sufficient fCash. If the rate does not slip then the account will end
        // up lending slightly less cash at a better rate.
        return (netCashToAccount * exchangeRatePostSlippage) / RATE_PRECISION;
    }

    function getBorrowfCashAmount(
        uint16 currencyId,
        uint256 marketIndex,
        uint256 blockTime,
        uint256 maturity,
        int128 defaultAnnualizedSlippage
    ) external view returns (int256) {
        // prettier-ignore
        (
            /* Token memory assetToken */,
            /* Token memory underlyingToken */,
            /* ETHRate memory ethRate */,
            AssetRateParameters memory assetRate
        ) = notional.getCurrencyAndRates(currencyId);

        // prettier-ignore
        (            
            /* AccountContext memory accountContext */,
            AccountBalance[] memory accountBalances,
            /* PortfolioAsset[] memory portfolio */
        ) = notional.getAccount(address(this));

        int256 netCashToAccount = accountBalances[currencyId].cashBalance * assetRate.rate;

        require(
            netCashToAccount >= type(int88).min && netCashToAccount <= type(int88).max,
            "netCashToAccount overflow"
        );

        int256 fCashAmount = notional.getfCashAmountGivenCashAmount(
            currencyId,
            int88(netCashToAccount),
            marketIndex,
            blockTime
        );

        // exchangeRate = abs(fCashAmount * RATE_PRECISION / netCashToAccount)
        int256 exchangeRate = (fCashAmount * RATE_PRECISION) / netCashToAccount;
        if (exchangeRate < 0) exchangeRate *= -1;

        int256 exchangeSlippageFactor = interestToExchangeRate(defaultAnnualizedSlippage, blockTime, maturity);

        // Exchange rates are non-linear so we apply slippage using the exponent identity:
        // exchangeRatePostSlippage = e^((r + delta) * t)
        // exchangeRate = e^(r * t)
        // slippageFactor = e^(delta * t)
        // exchangeRatePostSlippage = exchangeRate * slippageFactor
        int256 exchangeRatePostSlippage = (exchangeRate * exchangeSlippageFactor) / RATE_PRECISION;

        return (fCashAmount * exchangeRatePostSlippage) / RATE_PRECISION;
    }
}

contract InstaNotionalResolver is Resolver {
    string public constant name = "Notional-Resolver-v1";
}
