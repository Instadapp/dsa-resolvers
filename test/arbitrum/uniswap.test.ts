import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, network, config } from "hardhat";
import { expect } from "chai";
import { formatEther, formatUnits } from "ethers/lib/utils";
import { InstaUniswapV3ResolverArbitrum, InstaUniswapV3ResolverArbitrum__factory } from "../../typechain";
import { Tokens } from "../consts";

const { BigNumber } = ethers;

const ethAddr = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
const wethAddr = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1";

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

describe("Uniswap", () => {
  let signer: SignerWithAddress;
  const account = "0xa8ABe411d1A3F524a2aB9C54f8427066a1F9f266";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Uniswap Resolver", () => {
    let uniswap: InstaUniswapV3ResolverArbitrum;
    before(async () => {
      const liquityFactory = <InstaUniswapV3ResolverArbitrum__factory>(
        await ethers.getContractFactory("InstaUniswapV3Resolver")
      );
      uniswap = await liquityFactory.deploy();
      await uniswap.deployed();
    });

    it("deploys the resolver", () => {
      expect(uniswap.address).to.exist;
    });

    it("Returns position Info from tokenId", async () => {
      const [
        token0,
        token1,
        pool,
        fee,
        tickLower,
        tickUpper,
        currentTick,
        liquidity,
        tokenOwed0,
        tokenOwed1,
        amount0,
        amount1,
        collectAmount0,
        collectAmount1,
      ] = await uniswap.getPositionInfoByTokenId(BigNumber.from("20933"));
      console.log("Token0 Address: ", token0);
      console.log("Token1 Address: ", token1);
      console.log("Pool Address: ", pool);
      console.log("Liquidity: ", liquidity);
      console.log("Amount0: ", amount0);
      console.log("Amount1: ", amount1);
      console.log("Collect Amount0: ", collectAmount0);
      console.log("Collect Amount1: ", collectAmount1);
    });

    it("Returns sortted token address", async () => {
      const [token0, token1] = await uniswap.sort(wethAddr, ethAddr);
      expect(token0).to.equal(ethAddr);
      expect(token1).to.equal(wethAddr);
    });

    it("Returns deposit amount", async () => {
      const [liquidity, amount0, amount1] = await uniswap.getDepositAmount(
        BigNumber.from("20933"),
        ethers.utils.parseEther("1"),
        ethers.utils.parseEther("1"),
        "50000000000000000",
      );
      console.log("Liquidity", liquidity);
      console.log("Amount0", amount0);
      console.log("Amount1", amount1);
    });

    it("Returns single deposit Amount", async () => {
      const [liquidity, token1, amount1, amount0Min, amount1Min] = await uniswap.getSingleDepositAmount(
        BigNumber.from("20933"),
        ethAddr,
        ethers.utils.parseEther("1"),
        "50000000000000000",
      );
      console.log("liquidity", liquidity);
      console.log("token1", token1);
      console.log("amount1", amount1);
      console.log("amount0Min", amount0Min);
      console.log("amount1Min", amount1Min);
    });

    it("Returns single mint Amount", async () => {
      const [liquidity, amount1, amount0Min, amount1Min] = await uniswap.getSingleMintAmount(
        ethAddr,
        Tokens.USDC.addr,
        ethers.utils.parseEther("1"),
        "50000000000000000",
        FeeAmount.MEDIUM,
        getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
        getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
      );
      console.log("liquidity", liquidity);
      console.log("amount1", amount1);
    });

    it("Returns withdraw Amount", async () => {
      const [amount0, amount1] = await uniswap.getWithdrawAmount(
        BigNumber.from("20933"),
        ethers.utils.parseEther("0.001"),
        "50000000000000000",
      );
      console.log("amount0", amount0);
      console.log("amount1", amount1);
    });

    it("Returns collect Amount", async () => {
      const [amount0, amount1] = await uniswap.getCollectAmount(BigNumber.from("20933"));
      console.log("amount0", amount0);
      console.log("amount1", amount1);
    });
  });
});

const getMinTick = (tickSpacing: any) => Math.ceil(-887272 / tickSpacing) * tickSpacing;
const getMaxTick = (tickSpacing: any) => Math.floor(887272 / tickSpacing) * tickSpacing;
