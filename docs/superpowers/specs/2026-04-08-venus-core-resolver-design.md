# Venus Core Resolver (BSC) — Design Spec

## Overview
Resolver for Venus Protocol Core Pool on BNB Chain. Fetches user positions, per-market user data, and market-level data. Follows the existing 3-file pattern (`interfaces.sol`, `helpers.sol`, `main.sol`) under `contracts/protocols/bsc/venus_core/`.

## Scope
- **BSC only** — hardcoded Comptroller address
- **No VAI** — skip VAI-related data
- **View-safe** — use `exchangeRateStored`/`borrowBalanceStored` (not `Current` variants)

## Contracts & Addresses
- Comptroller (Diamond): `0xfD36E2c2a6789Db23113685031d7F16329158384`
- Oracle: fetched dynamically via `comptroller.oracle()`
- vBNB: detected by symbol comparison (`"vBNB"`), underlying = `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`

## File Structure

### `interfaces.sol`
Interfaces for on-chain calls:
- `IComptroller` — getAllMarkets, getAssetsIn, markets, getAccountLiquidity, getBorrowingPower, oracle, closeFactorMantissa, venusSupplySpeeds, venusBorrowSpeeds, venusAccrued, checkMembership, actionPaused
- `IVToken` — balanceOf, borrowBalanceStored, exchangeRateStored, underlying, totalBorrows, totalSupply, totalReserves, reserveFactorMantissa, supplyRatePerBlock, borrowRatePerBlock, getCash, decimals, symbol, name, comptroller, getAccountSnapshot
- `IPriceOracle` — getUnderlyingPrice(vToken)
- `IERC20` — balanceOf, allowance, decimals, symbol

### `helpers.sol`
Constants, structs, and internal helper functions:

**Structs:**
- `VenusUserData` — totalCollateralUSD, totalBorrowsUSD, liquidity, shortfall, xvsAccrued
- `VenusUserMarketData` — supplyBalanceUnderlying, borrowBalance, isCollateral, underlyingPrice, walletBalance, walletAllowance, supplyRate, borrowRate
- `VenusMarketData` — vTokenAddr, underlyingAddr, symbol, underlyingDecimals, vTokenDecimals, collateralFactorMantissa, liquidationThresholdMantissa, liquidationIncentiveMantissa, supplyRatePerBlock, borrowRatePerBlock, totalSupply, totalBorrows, totalReserves, availableCash, exchangeRateStored, reserveFactorMantissa, xvsSupplySpeed, xvsBorrowSpeed, isListed, isBorrowAllowed, poolId

**Helpers:**
- `getComptrollerAddr()` — returns hardcoded Comptroller
- `getBnbAddr()` — returns BNB sentinel
- `getUserData(user)` — calls getAccountLiquidity + venusAccrued
- `getUserMarketData(user, vToken)` — calls borrowBalanceStored, exchangeRateStored, balanceOf, checkMembership, wallet balance/allowance
- `getMarketData(vToken)` — calls markets(), rates, totals, speeds

### `main.sol`
Public API:

```solidity
function getPosition(address user, address[] memory vTokens)
    public view returns (VenusUserData, VenusUserMarketData[], VenusMarketData[])

function getPositionAll(address user)
    public view returns (VenusUserData, VenusUserMarketData[], VenusMarketData[])

function getMarketsList()
    public view returns (address[])
```

Final contract: `InstaVenusCoreResolverBSC` with `name = "VenusCore-Resolver-BSC-v1.0"`

## Design Decisions
1. **vBNB detection**: Compare symbol to `"vBNB"` — no `underlying()` exists for native BNB market
2. **Health factor omitted as field**: Venus returns liquidity/shortfall from `getAccountLiquidity` — consumers derive health from these
3. **Exchange rate**: Use `exchangeRateStored()` to keep view-safe; supply balance in underlying = `balanceOf * exchangeRate / 1e18`
4. **XVS rewards**: Expose `venusAccrued(user)` in user data, `venusSupplySpeeds`/`venusBorrowSpeeds` per market
5. **Wallet data**: Include user's underlying token balance and allowance to vToken for each market
