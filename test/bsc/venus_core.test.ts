import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaVenusCoreResolverBSC, InstaVenusCoreResolverBSC__factory } from "../../typechain";

describe("Venus Core", () => {
  // An active Venus user on BSC with supply & borrow positions
  const account = "0x344996e9Fb42Be22F646B0e2CE0be2a87368240b";

  // Known vToken addresses on BSC Core Pool
  const vBNB = "0xA07c5b74C9B40447a954e1466938b865b6BBea36";
  const vUSDT = "0xfD5840Cd36d94D7229439859C0112a4185BC0255";

  describe("Venus Core Resolver", () => {
    let signer: SignerWithAddress;
    let resolver: InstaVenusCoreResolverBSC;

    before(async () => {
      [signer] = await ethers.getSigners();
      const deployer = new InstaVenusCoreResolverBSC__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("should return the resolver name", async () => {
      const name = await resolver.name();
      expect(name).to.eq("VenusCore-Resolver-BSC-v1.0");
      console.log(`Resolver name: ${name}`);
    });

    it("should return all markets list", async () => {
      const markets = await resolver.getMarketsList();
      console.log(`\nTotal markets: ${markets.length}`);
      console.log("Markets:");
      for (const m of markets) {
        console.log(`  - ${m}`);
      }
      expect(markets.length).to.be.gt(0);
    });

    it("should get position for specific vTokens", async () => {
      const results = await resolver.getPosition(account, [vBNB, vUSDT]);
      const userData = results[0];
      const userMarketsData = results[1];
      const marketsData = results[2];

      console.log("\n*************************************************");
      console.log("User Data");
      console.log("*************************************************");
      console.log(`Liquidity (liq threshold): ${formatUnits(userData.liquidity, 18)}`);
      console.log(`Shortfall (liq threshold): ${formatUnits(userData.shortfall, 18)}`);
      console.log(`Borrowing Liquidity (CF): ${formatUnits(userData.borrowingLiquidity, 18)}`);
      console.log(`Borrowing Shortfall (CF): ${formatUnits(userData.borrowingShortfall, 18)}`);
      console.log(`XVS Accrued: ${formatUnits(userData.xvsAccrued, 18)}`);

      for (let i = 0; i < marketsData.length; i++) {
        const market = marketsData[i];
        const userMarket = userMarketsData[i];

        console.log(`\n--- ${market.symbol} (${market.underlyingSymbol}) ---`);
        console.log(`  vToken: ${market.vTokenAddr}`);
        console.log(`  Underlying: ${market.underlyingAddr}`);
        console.log(`  Underlying Decimals: ${market.underlyingDecimals}`);
        console.log(`  Collateral Factor: ${formatUnits(market.collateralFactorMantissa, 18)}`);
        console.log(`  Liquidation Threshold: ${formatUnits(market.liquidationThresholdMantissa, 18)}`);
        console.log(`  Liquidation Incentive: ${formatUnits(market.liquidationIncentiveMantissa, 18)}`);
        console.log(`  Supply Rate/Block: ${market.supplyRatePerBlock}`);
        console.log(`  Borrow Rate/Block: ${market.borrowRatePerBlock}`);
        console.log(`  Total Supply (vTokens): ${market.totalSupply}`);
        console.log(`  Total Borrows: ${formatUnits(market.totalBorrows, market.underlyingDecimals)}`);
        console.log(`  Total Reserves: ${formatUnits(market.totalReserves, market.underlyingDecimals)}`);
        console.log(`  Available Cash: ${formatUnits(market.availableCash, market.underlyingDecimals)}`);
        console.log(`  Exchange Rate: ${market.exchangeRateStored}`);
        console.log(`  Reserve Factor: ${formatUnits(market.reserveFactorMantissa, 18)}`);
        console.log(`  XVS Supply Speed: ${market.xvsSupplySpeed}`);
        console.log(`  XVS Borrow Speed: ${market.xvsBorrowSpeed}`);
        console.log(`  Is Listed: ${market.isListed}`);
        console.log(`  Is Borrow Allowed: ${market.isBorrowAllowed}`);
        console.log(`  Pool ID: ${market.poolId}`);

        console.log(`  --- User Position ---`);
        console.log(`  Supply Balance: ${formatUnits(userMarket.supplyBalanceUnderlying, market.underlyingDecimals)}`);
        console.log(`  Borrow Balance: ${formatUnits(userMarket.borrowBalance, market.underlyingDecimals)}`);
        console.log(`  Is Collateral: ${userMarket.isCollateral}`);
        console.log(`  Underlying Price: ${userMarket.underlyingPrice}`);
        console.log(`  Wallet Balance: ${formatUnits(userMarket.walletBalance, market.underlyingDecimals)}`);
        console.log(`  Wallet Allowance: ${formatUnits(userMarket.walletAllowance, market.underlyingDecimals)}`);
      }

      expect(marketsData[0].isListed).to.eq(true);
      expect(marketsData[0].vTokenAddr).to.eq(vBNB);
    });

    it("should get position for all markets", async () => {
      const results = await resolver.getPositionAll(account);
      const userData = results[0];
      const userMarketsData = results[1];
      const marketsData = results[2];

      console.log("\n*************************************************");
      console.log("Full Position (All Markets)");
      console.log("*************************************************");
      console.log(`Total Markets: ${marketsData.length}`);
      console.log(`Liquidity: ${formatUnits(userData.liquidity, 18)}`);
      console.log(`Shortfall: ${formatUnits(userData.shortfall, 18)}`);
      console.log(`XVS Accrued: ${formatUnits(userData.xvsAccrued, 18)}`);

      let suppliedCount = 0;
      let borrowedCount = 0;

      for (let i = 0; i < marketsData.length; i++) {
        const market = marketsData[i];
        const userMarket = userMarketsData[i];

        if (userMarket.supplyBalanceUnderlying.gt(0) || userMarket.borrowBalance.gt(0)) {
          console.log(`\n  ${market.symbol} (${market.underlyingSymbol}):`);
          if (userMarket.supplyBalanceUnderlying.gt(0)) {
            console.log(`    Supply: ${formatUnits(userMarket.supplyBalanceUnderlying, market.underlyingDecimals)}`);
            suppliedCount++;
          }
          if (userMarket.borrowBalance.gt(0)) {
            console.log(`    Borrow: ${formatUnits(userMarket.borrowBalance, market.underlyingDecimals)}`);
            borrowedCount++;
          }
          console.log(`    Collateral: ${userMarket.isCollateral}`);
        }
      }

      console.log(`\nSupplied in ${suppliedCount} markets, Borrowed from ${borrowedCount} markets`);

      expect(marketsData.length).to.be.gt(0);
      expect(userData.liquidity.add(userData.shortfall)).to.be.gte(0);
    });
  });
});
