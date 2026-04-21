---
name: venus-core-resolver-usage
description: Use when querying Venus Core Pool data on BSC with the deployed resolver, limited to getMarketsList and getPositionAll.
---

# Venus Core Resolver Usage

## Overview
Use this to read Venus Core Pool market list and full user position from the deployed BSC resolver.

- Resolver: `0xA126B30C6719dD676B140386f45a4A254A88924B`
- Chain: BSC (`56`)

## Supported Functions

### `getMarketsList()`
Returns all Venus Core vToken addresses.

### `getPositionAll(address user)`
Returns:
- user-level data (`liquidity`, `shortfall`, `borrowingLiquidity`, `borrowingShortfall`, `xvsAccrued`)
- per-market user data array
- per-market metadata array

## Quick Usage (ethers v5)

```ts
import { ethers } from "ethers";

const provider = new ethers.providers.JsonRpcProvider(process.env.BSC_RPC_URL);
const resolver = new ethers.Contract(
  "0xA126B30C6719dD676B140386f45a4A254A88924B",
  [
    "function getMarketsList() view returns (address[])",
    "function getPositionAll(address user) view returns ((uint256,uint256,uint256,uint256,uint256,uint256,uint256),(uint256,uint256,uint256,bool,uint256,uint256,uint256)[],(address,address,string,string,uint8,uint8,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,bool,bool,uint96)[])",
  ],
  provider
);

const markets = await resolver.getMarketsList();
const [userData, userMarkets, marketsData] = await resolver.getPositionAll(
  "0xYourUserAddress"
);
```

## Notes
- `supplyRatePerBlock` and `borrowRatePerBlock` are currently returned as `0` in this resolver version.
- For BNB market (`vBNB`), wallet balance/allowance are represented using native BNB handling.
