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

    /// @notice Returns the amount of fCash that would received if lending deposit amount.
    /// @param currencyId id number of the currency
    /// @param depositAmountExternal amount to deposit in the token's native precision. For aTokens use
    /// what is returned by the balanceOf selector (not scaledBalanceOf).
    /// @param maturity the maturity of the fCash to lend
    /// @param minLendRate the minimum lending rate (slippage protection)
    /// @param blockTime the block time for when the trade will be calculated
    /// @param useUnderlying true if specifying the underlying token, false if specifying the asset token
    /// @return fCashAmount the amount of fCash that the lender will receive
    /// @return marketIndex the corresponding market index for the lending
    /// @return encodedTrade the encoded bytes32 object to pass to batch trade
    function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    )
        external
        view
        returns (
            uint88 fCashAmount,
            uint8 marketIndex,
            bytes32 encodedTrade
        )
    {
        return
            notional.getfCashLendFromDeposit(
                currencyId,
                depositAmountExternal,
                maturity,
                minLendRate,
                blockTime,
                useUnderlying
            );
    }

    /// @notice Returns the amount of fCash that would received if lending deposit amount.
    /// @param currencyId id number of the currency
    /// @param borrowedAmountExternal amount to borrow in the token's native precision. For aTokens use
    /// what is returned by the balanceOf selector (not scaledBalanceOf).
    /// @param maturity the maturity of the fCash to lend
    /// @param maxBorrowRate the maximum borrow rate (slippage protection). If zero then no slippage will be applied
    /// @param blockTime the block time for when the trade will be calculated
    /// @param useUnderlying true if specifying the underlying token, false if specifying the asset token
    /// @return fCashDebt the amount of fCash that the borrower will owe, this will be stored as a negative
    /// balance in Notional
    /// @return marketIndex the corresponding market index for the lending
    /// @return encodedTrade the encoded bytes32 object to pass to batch trade
    function getfCashBorrowFromPrincipal(
        uint16 currencyId,
        uint256 borrowedAmountExternal,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime,
        bool useUnderlying
    )
        external
        view
        returns (
            uint88 fCashDebt,
            uint8 marketIndex,
            bytes32 encodedTrade
        )
    {
        return
            notional.getfCashBorrowFromPrincipal(
                currencyId,
                borrowedAmountExternal,
                maturity,
                maxBorrowRate,
                blockTime,
                useUnderlying
            );
    }

    /// @notice Returns the amount of underlying cash and asset cash required to lend fCash. When specifying a
    /// trade, deposit either underlying or asset tokens (not both). Asset tokens tend to be more gas efficient.
    /// @param currencyId id number of the currency
    /// @param fCashAmount amount of fCash (in underlying) that will be received at maturity. Always 8 decimal precision.
    /// @param maturity the maturity of the fCash to lend
    /// @param minLendRate the minimum lending rate (slippage protection)
    /// @param blockTime the block time for when the trade will be calculated
    /// @return depositAmountUnderlying the amount of underlying tokens the lender must deposit
    /// @return depositAmountAsset the amount of asset tokens the lender must deposit
    /// @return marketIndex the corresponding market index for the lending
    /// @return encodedTrade the encoded bytes32 object to pass to batch trade
    function getDepositFromfCashLend(
        uint16 currencyId,
        uint256 fCashAmount,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime
    )
        external
        view
        returns (
            uint256 depositAmountUnderlying,
            uint256 depositAmountAsset,
            uint8 marketIndex,
            bytes32 encodedTrade
        )
    {
        return notional.getDepositFromfCashLend(currencyId, fCashAmount, maturity, minLendRate, blockTime);
    }

    /// @notice Returns the amount of underlying cash and asset cash required to borrow fCash. When specifying a
    /// trade, choose to receive either underlying or asset tokens (not both). Asset tokens tend to be more gas efficient.
    /// @param currencyId id number of the currency
    /// @param fCashBorrow amount of fCash (in underlying) that will be received at maturity. Always 8 decimal precision.
    /// @param maturity the maturity of the fCash to lend
    /// @param maxBorrowRate the maximum borrow rate (slippage protection)
    /// @param blockTime the block time for when the trade will be calculated
    /// @return borrowAmountUnderlying the amount of underlying tokens the borrower will receive
    /// @return borrowAmountAsset the amount of asset tokens the borrower will receive
    /// @return marketIndex the corresponding market index for the lending
    /// @return encodedTrade the encoded bytes32 object to pass to batch trade
    function getPrincipalFromfCashBorrow(
        uint16 currencyId,
        uint256 fCashBorrow,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime
    )
        external
        view
        returns (
            uint256 borrowAmountUnderlying,
            uint256 borrowAmountAsset,
            uint8 marketIndex,
            bytes32 encodedTrade
        )
    {
        return notional.getPrincipalFromfCashBorrow(currencyId, fCashBorrow, maturity, maxBorrowRate, blockTime);
    }

    /// @notice Converts an internal cash balance to an external token denomination
    /// @param currencyId the currency id of the cash balance
    /// @param cashBalanceInternal the signed cash balance that is stored in Notional
    /// @param convertToUnderlying true if the value should be converted to underlying
    /// @return the cash balance converted to the external token denomination
    function convertCashBalanceToExternal(
        uint16 currencyId,
        int256 cashBalanceInternal,
        bool convertToUnderlying
    ) external view returns (int256) {
        return notional.convertCashBalanceToExternal(currencyId, cashBalanceInternal, convertToUnderlying);
    }
}

contract InstaNotionalResolver is Resolver {
    string public constant name = "Notional-Resolver-v1";
}
