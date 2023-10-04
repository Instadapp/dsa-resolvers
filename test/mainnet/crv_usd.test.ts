import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
// import { expect } from "chai";
// import { formatEther, formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaCurveUSDResolver, InstaCurveUSDResolver__factory } from "../../typechain";
// import { Tokens } from "../consts";

describe("CRV-USD Resolvers", () => {
  let signer: SignerWithAddress;
  const user = "0x294125EBE0a93815A68E0165935c521275E2Dc1e";
  const markets = [
    "0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0",
    "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
    "0xac3e018457b222d93114458476f3e3416abbe38f", //sfrxETH version 1
    "0x18084fba666a33d37592fa2633fd49a74dd93a88",
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    "0xac3e018457b222d93114458476f3e3416abbe38f", // sfrxETH version 2
  ];
  const indexed = [
    0,
    0,
    0, //sfrxETH version 1
    0,
    0,
    1, // sfrxETH version 2
  ];

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("CRV-USD Resolver", () => {
    let resolver: InstaCurveUSDResolver;
    before(async () => {
      const deployer = new InstaCurveUSDResolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("Returns the market's configurations", async () => {
      const marketConfig = await resolver.getMarketDetailsAll(markets, indexed);
      for (const market of marketConfig) {
        console.log("======================================================");
        console.log(`Total Debt: ${market.totalDebt}`);
        console.log(`basePrice: ${market.basePrice}`);
        console.log(`oracle price: ${market.oraclePrice}`);
        console.log(`Amplicitation coefficient: ${market.A}`);
        console.log(`Count of loan: ${market.loanLen}`);
        console.log(`fractionPerSecond: ${market.fractionPerSecond}`);
        console.log(`sigma factor: ${market.sigma}`);
        console.log(`Fraction of the target fraction: ${market.targetDebtFraction}`);
        console.log(`CRV market controller address: ${market.controller}`);
        console.log(`AMM address: ${market.AMM}`);
        console.log(`Monetary address: ${market.monetary}`);
        console.log(`total Curve borrowable amount: ${market.borrowable}`);
        console.log(`Coin0 address: ${market.coins.coin0}`);
        console.log(`Coin1 address: ${market.coins.coin1}`);
        console.log(`Coin0 token decimals: ${market.coins.coin0Decimals}`);
        console.log(`Coin1 token decimals: ${market.coins.coin1Decimals}`);
        console.log(`Coin0 balance: ${market.coins.coin0Amount}`);
        console.log(`Coin1 balance: ${market.coins.coin1Amount}`);
        console.log(`min Band: ${market.minBand}`);
        console.log(`max Band: ${market.maxBand}`);
        console.log("======================================================");
      }
    });

    it("Returns the user's position details", async () => {
      const userPositions = await resolver.getPositionAll(user, markets, indexed);

      for (const position of userPositions.positionData) {
        console.log("-----------------------------------------------------------");
        console.log(`**User Position Data:**`);
        console.log(`Supplied balance: ${position.supply}`);
        console.log(`Borrowed balance: ${position.borrow}`);
        console.log(`User band Number: ${position.N}`);
        console.log(`Is created loan?: ${position.existLoan}`);
        console.log(`User health: ${position.health}`);
        console.log(`Use loan ID: ${position.loanId}`);
        console.log(`User upper price: ${position.prices.upper}`);
        console.log(`User lower price: ${position.prices.lower}`);
        console.log(`User bandRange: ${position.bandRange}`);
        console.log(`User liquidationRange: ${position.liquidationRange}`);
        console.log("-----------------------------------------------------------");
      }
    });

    it("Returns max debt amount", async () => {
      const maxDebt = await resolver.getMaxDebt(markets[0], 0, "1000000000000000000", 12);
      console.log("maxDebt amount: ", maxDebt);
    });

    it("Returns min collateral amount", async () => {
      const minCollateral = await resolver.getMinCollateral(markets[0], 0, "500000000000000000000", 10);
      console.log("maxDebt amount: ", minCollateral);
    });

    it("Returns Band range", async () => {
      const minCollateral = await resolver.getBandRangeAndLiquidationRange(
        markets[0],
        0,
        "2205663198573977494528",
        "2589469072122129017791488",
        21,
      );
      console.log("maxDebt amount: ", minCollateral);
    });
  });
});
