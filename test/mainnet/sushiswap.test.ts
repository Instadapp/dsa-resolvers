import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, network, config } from "hardhat";
import { expect } from "chai";
import { formatEther, formatUnits } from "ethers/lib/utils";
import { InstaSushiSwapResolver, InstaSushiSwapResolver__factory } from "../../typechain";
import { Tokens } from "../consts";

const { BigNumber } = ethers;

const ethAddr = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
const wethAddr = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const daiAddr = "0x6b175474e89094c44da98b954eedeac495271d0f";

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

describe("Sushiswap", () => {
  let signer: SignerWithAddress;
  const account = "0xa8ABe411d1A3F524a2aB9C54f8427066a1F9f266";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Sushiswap Resolver", () => {
    let sushiswap: InstaSushiSwapResolver;
    before(async () => {
      const sushiFactory = <InstaSushiSwapResolver__factory>await ethers.getContractFactory("InstaSushiSwapResolver");
      sushiswap = await sushiFactory.deploy();
      await sushiswap.deployed();
    });

    it("deploys the resolver", () => {
      expect(sushiswap.address).to.exist;
    });

    it("Returns buy amount from sell amount", async () => {
      const [buyAmt, unitAmt] = await sushiswap.getBuyAmount(
        daiAddr,
        wethAddr,
        ethers.utils.parseEther("1"),
        "50000000000000000",
      );
      console.log("buy amount", buyAmt);
      console.log("unit amount", unitAmt);
    });

    it("Returns sell amount from buy amount", async () => {
      const [sellAmt, unitAmt] = await sushiswap.getSellAmount(
        daiAddr,
        wethAddr,
        ethers.utils.parseEther("1"),
        "50000000000000000",
      );
      console.log("sell amount", sellAmt);
      console.log("unit amount", unitAmt);
    });

    it("Returns deposit amount", async () => {
      const [amtB, unitAmt, minA, minB] = await sushiswap.getDepositAmount(
        wethAddr,
        daiAddr,
        ethers.utils.parseEther("1"),
        "50000000000000000",
        "50000000000000000",
      );
      console.log("AmountB", amtB);
      console.log("Unit Amount", unitAmt);
      console.log("Min Amount A", minA);
      console.log("Min Amount B", minB);
    });

    it("Returns single deposit amount", async () => {
      const [amtA, amtB, unitAmount, minUnitAmount] = await sushiswap.getSingleDepositAmount(
        wethAddr,
        daiAddr,
        ethers.utils.parseEther("1"),
        "50000000000000000",
      );
      console.log("Amount A", amtA);
      console.log("Amount B", amtB);
      console.log("Unit Amount", unitAmount);
      console.log("Min Unit Amount", minUnitAmount);
    });

    it("Returns withdraw amount", async () => {
      const [amtA, amtB, unitAmountA, unitAmountB] = await sushiswap.getWithdrawAmounts(
        wethAddr,
        daiAddr,
        "1000000000000000",
        "50000000000000000",
      );
      console.log("Amount A", amtA);
      console.log("Amount B", amtB);
      console.log("Unit Amount B", unitAmountA);
      console.log("Unit Amount B", unitAmountB);
    });
  });
});
