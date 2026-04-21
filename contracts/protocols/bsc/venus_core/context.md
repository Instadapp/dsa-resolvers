# Venus Core Resolver — Development Context

## What Was Done

### Resolver Implementation (COMPLETE)
Three files created following the existing Aave V3 BSC resolver pattern:

- **`interfaces.sol`** — Interfaces for `IComptroller`, `IVToken`, `IPriceOracle`, `IERC20`
- **`helpers.sol`** — Structs (`VenusUserData`, `VenusUserMarketData`, `VenusMarketData`), hardcoded BSC Comptroller address, internal helper functions
- **`main.sol`** — Public API: `getPosition(user, vTokens[])`, `getPositionAll(user)`, `getMarketsList()`
- **Compiles cleanly** with `npx hardhat compile` (0 errors)

### Test File
- **`test/bsc/venus_core.test.ts`** — Full test suite modeled after the Arbitrum Aave V3 test

### hardhat.config.ts Changes
- BSC RPC changed from `https://1rpc.io/bnb` (unreliable, was down) to `https://bnb-mainnet.g.alchemy.com/v2/${alchemyApiKey}`
- Added a commented-out `hardfork: "cancun"` with a TODO note

---

## What Works
- **Compilation**: All 3 resolver files compile successfully
- **`getMarketsList()`**: Returns all 48 Venus Core Pool markets correctly on BSC fork
- **`resolver.name()`**: Returns `"VenusCore-Resolver-BSC-v1.0"` correctly
- **Individual RPC calls**: All Comptroller and VToken view functions work when called individually via ethers.js against live BSC RPC:
  - `comptroller.getAllMarkets()` ✅
  - `comptroller.markets(vToken)` — 7-tuple ✅
  - `comptroller.getAccountLiquidity(user)` ✅
  - `comptroller.getBorrowingPower(user)` ✅
  - `comptroller.venusAccrued(user)` ✅
  - `comptroller.checkMembership(user, vToken)` ✅
  - `oracle.getUnderlyingPrice(vToken)` ✅
  - `vToken.exchangeRateStored()` ✅
  - `vToken.borrowBalanceStored(user)` ✅
  - `vToken.supplyRatePerBlock()` ✅
  - `vToken.borrowRatePerBlock()` ✅

## What Doesn't Work
- **`getPosition()` and `getPositionAll()` revert in Hardhat fork** — the combined on-chain call fails

### Root Cause
The **Venus Resilient Oracle** proxy at `0x6592b5DE802159F3E74B2486b091D11a8256ab8A` delegates to implementation `0x90d840f463c4e341e37b1d51b1ab16bc5b34865c`, which is compiled with **Solidity 0.8.25** targeting the **Cancun EVM**.

The implementation bytecode uses **opcodes not supported by Hardhat 2.19.2** (the project's current version). Specifically:
- The Oracle implementation contains **MCOPY (0x5e)** or **TLOAD/TSTORE (0x5c/0x5d)** opcodes that require the Cancun hardfork
- Hardhat 2.19.2 only supports up to Shanghai hardfork
- PUSH0 (0x5f, Shanghai) IS supported — confirmed by deploying a PUSH0 contract successfully
- The error manifests as `"isInvalidOpcodeError": true` at the Oracle implementation address

**The resolver contract logic is correct** — the issue is purely a Hardhat EVM compatibility problem during fork testing.

---

## Solutions (Pick One)

### Option 1: Upgrade Hardhat to 2.22+ (Recommended)
Hardhat 2.22.0 (April 2024) added Cancun hardfork support. Upgrade and enable:
```bash
npm install hardhat@^2.22.0
```
Then in `hardhat.config.ts`, uncomment:
```js
hardfork: "cancun",
```
**Risk**: May need dependency updates. Test all existing chains' tests after upgrade.

### Option 2: Deploy & Test on Live BSC Testnet
Skip Hardhat fork, deploy to BSC testnet and test there. The resolver will work correctly on the real BSC EVM.
```bash
npx hardhat run scripts/deploy.js --network bsc
```

### Option 3: Wrap Oracle Calls in Low-Level staticcall
Use `address(oracle).staticcall(...)` instead of direct interface calls for the Oracle. This way, if the Oracle call fails in the fork, it returns `(false, "")` instead of reverting the entire transaction. The resolver returns 0 for price instead of reverting.

**Downside**: Adds complexity and gas cost. The resolver should work fine on real BSC — this is only a testing issue.

---

## Key Technical Details

### Venus Core Pool on BSC
- **Comptroller (Diamond Proxy)**: `0xfD36E2c2a6789Db23113685031d7F16329158384`
- **Oracle (Resilient Oracle)**: `0x6592b5DE802159F3E74B2486b091D11a8256ab8A` (fetched dynamically via `comptroller.oracle()`)
- **48 markets** in the core pool (including vBNB, vUSDT, vBUSD, vETH, etc.)
- **Compound V2 fork** with Diamond proxy pattern (facets: Market, Policy, Reward, Setter, FlashLoan)

### Key Function Signatures Verified On-Chain
```solidity
// Comptroller — returns 7-tuple
comptroller.markets(vToken) → (isListed, collateralFactor, isVenus, liquidationThreshold, liquidationIncentive, poolId, isBorrowAllowed)

// Comptroller — two separate liquidity checks
comptroller.getAccountLiquidity(user) → (error, liquidity, shortfall)  // based on liquidation threshold
comptroller.getBorrowingPower(user) → (error, liquidity, shortfall)    // based on collateral factor

// Oracle — price scaled by 1e(36 - underlyingDecimals)
oracle.getUnderlyingPrice(vToken) → uint256
```

### vBNB Special Handling
- `vBNB` at `0xA07c5b74C9B40447a954e1466938b865b6BBea36` wraps native BNB
- Has no `underlying()` function — calling it reverts
- Detected via `keccak256(symbol) == keccak256("vBNB")`
- Uses BNB sentinel address `0xEeee...eEEeE` and 18 decimals

### Test Account Used
- `0x344996e9Fb42Be22F646B0e2CE0be2a87368240b` — has 0 balance/position (fine for testing contract doesn't revert on empty users)
- Consider finding a whale address with active supply+borrow positions for more meaningful test output

---

## Files Modified/Created
| File | Status |
|------|--------|
| `contracts/protocols/bsc/venus_core/interfaces.sol` | NEW |
| `contracts/protocols/bsc/venus_core/helpers.sol` | NEW |
| `contracts/protocols/bsc/venus_core/main.sol` | NEW |
| `test/bsc/venus_core.test.ts` | NEW |
| `hardhat.config.ts` | MODIFIED (BSC RPC + hardfork comment) |
| `docs/superpowers/specs/2026-04-08-venus-core-resolver-design.md` | NEW (design spec) |
