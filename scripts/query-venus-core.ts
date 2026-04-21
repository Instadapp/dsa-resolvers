import { formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaVenusCoreResolverBSC__factory } from "../typechain";

async function main() {
  const resolverAddr = "0xA126B30C6719dD676B140386f45a4A254A88924B";
  const user = "0xc1490E0489f487477A9B4e52Da19416d21fC09E0";
  const vTokens = [
    "0x6bCa74586218dB34cdB402295796b79663d816e9",
    "0xfD5840Cd36d94D7229439859C0112a4185BC0255",
  ];

  const resolver = InstaVenusCoreResolverBSC__factory.connect(resolverAddr, ethers.provider);
  const [userData, userMarketsData, marketsData] = await resolver.getPosition(user, vTokens);

  console.log("USER_DATA");
  console.log(`liquidity=${userData.liquidity.toString()}`);
  console.log(`shortfall=${userData.shortfall.toString()}`);
  console.log(`borrowingLiquidity=${userData.borrowingLiquidity.toString()}`);
  console.log(`borrowingShortfall=${userData.borrowingShortfall.toString()}`);
  console.log(`xvsAccrued=${userData.xvsAccrued.toString()}`);

  for (let i = 0; i < marketsData.length; i++) {
    const market = marketsData[i];
    const userMarket = userMarketsData[i];
    console.log(`\nMARKET_${i}`);
    console.log(`vToken=${market.vTokenAddr}`);
    console.log(`symbol=${market.symbol}`);
    console.log(`underlyingSymbol=${market.underlyingSymbol}`);
    console.log(`underlyingDecimals=${market.underlyingDecimals}`);
    console.log(`isListed=${market.isListed}`);
    console.log(`isBorrowAllowed=${market.isBorrowAllowed}`);
    console.log(`collateralFactor=${formatUnits(market.collateralFactorMantissa, 18)}`);
    console.log(`liquidationThreshold=${formatUnits(market.liquidationThresholdMantissa, 18)}`);
    console.log(`liquidationIncentive=${formatUnits(market.liquidationIncentiveMantissa, 18)}`);
    console.log(`supplyRatePerBlock=${market.supplyRatePerBlock.toString()}`);
    console.log(`borrowRatePerBlock=${market.borrowRatePerBlock.toString()}`);
    console.log(`underlyingPriceRaw=${userMarket.underlyingPrice.toString()}`);
    console.log(`supplyBalanceUnderlying=${formatUnits(userMarket.supplyBalanceUnderlying, market.underlyingDecimals)}`);
    console.log(`borrowBalance=${formatUnits(userMarket.borrowBalance, market.underlyingDecimals)}`);
    console.log(`isCollateral=${userMarket.isCollateral}`);
    console.log(`walletBalance=${formatUnits(userMarket.walletBalance, market.underlyingDecimals)}`);
    console.log(`walletAllowance=${formatUnits(userMarket.walletAllowance, market.underlyingDecimals)}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
