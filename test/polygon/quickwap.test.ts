import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, network, config } from "hardhat";
import { expect } from "chai";
import { formatEther, formatUnits } from "ethers/lib/utils";
import { InstaQuickSwapResolverPolygon, InstaQuickSwapResolverPolygon__factory } from "../../typechain";

const { BigNumber } = ethers;

const ethAddr = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
const wethAddr = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
const daiAddr = "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063";

const FeeAmount = {
  LOW: 500,
  MEDIUM: 3000,
  HIGH: 10000,
};

const TICK_SPACINGS: any = {
  500: 10,
  3000: 60,
  10000: 200,
};

describe("Quickswap", () => {
  let signer: SignerWithAddress;
  const account = "0xa8ABe411d1A3F524a2aB9C54f8427066a1F9f266";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Quickswap Resolver", () => {
    let Quickswap: InstaQuickSwapResolverPolygon;
    before(async () => {
      const quickFactory = <InstaQuickSwapResolverPolygon__factory>(
        await ethers.getContractFactory("InstaQuickSwapResolverPolygon")
      );
      Quickswap = await quickFactory.deploy();
      await Quickswap.deployed();
    });

    it("deploys the resolver", () => {
      expect(Quickswap.address).to.exist;
    });

    it("Returns buy amount from sell amount", async () => {
      const [buyAmt, unitAmt] = await Quickswap.getBuyAmount(
        daiAddr,
        wethAddr,
        ethers.utils.parseEther("1"),
        "50000000000000000",
      );
      console.log("buy amount", buyAmt.toString());
      console.log("unit amount", unitAmt.toString());
    });

    it("Returns sell amount from buy amount", async () => {
      const [sellAmt, unitAmt] = await Quickswap.getSellAmount(
        daiAddr,
        wethAddr,
        ethers.utils.parseEther("1"),
        "50000000000000000",
      );
      console.log("sell amount", sellAmt.toString());
      console.log("unit amount", unitAmt.toString());
    });

    it("Returns deposit amount", async () => {
      const [amtB, unitAmt, minA, minB] = await Quickswap.getDepositAmount(
        wethAddr,
        daiAddr,
        ethers.utils.parseEther("1"),
        "50000000000000000",
        "50000000000000000",
      );
      console.log("AmountB", amtB.toString());
      console.log("Unit Amount", unitAmt.toString());
      console.log("Min Amount A", minA.toString());
      console.log("Min Amount B", minB.toString());
    });

    it("Returns single deposit amount", async () => {
      const [amtA, amtB, unitAmount, minUnitAmount] = await Quickswap.getSingleDepositAmount(
        wethAddr,
        daiAddr,
        ethers.utils.parseEther("1"),
        "50000000000000000",
      );
      console.log("Amount A", amtA.toString());
      console.log("Amount B", amtB.toString());
      console.log("Unit Amount", unitAmount.toString());
      console.log("Min Unit Amount", minUnitAmount.toString());
    });

    it("Returns withdraw amount", async () => {
      const [amtA, amtB, unitAmountA, unitAmountB] = await Quickswap.getWithdrawAmounts(
        wethAddr,
        daiAddr,
        "1000000000000000",
        "50000000000000000",
      );
      console.log("Amount A", amtA.toString());
      console.log("Amount B", amtB.toString());
      console.log("Unit Amount B", unitAmountA.toString());
      console.log("Unit Amount B", unitAmountB.toString());
    });
  });
});
