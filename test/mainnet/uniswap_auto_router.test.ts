import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, network, config } from "hardhat";
import { expect } from "chai";
import { formatEther, formatUnits } from "ethers/lib/utils";
import { InstaUniswapV3AutoRouterResolver, InstaUniswapV3AutoRouterResolver__factory } from "../../typechain";
import { Tokens } from "../consts";

const { BigNumber } = ethers;

const ethAddr = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
const wethAddr = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

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

const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const ETH = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

describe("Uniswap-Auth-Router", () => {
  const account = "0xa8ABe411d1A3F524a2aB9C54f8427066a1F9f266";

  describe("Uniswap Resolver", () => {
    let uniswap: InstaUniswapV3AutoRouterResolver;
    before(async () => {
      const liquityFactory = <InstaUniswapV3AutoRouterResolver__factory>(
        await ethers.getContractFactory("InstaUniswapV3AutoRouterResolver")
      );
      uniswap = await liquityFactory.deploy();
      await uniswap.deployed();
    });

    it("deploys the resolver", () => {
      expect(uniswap.address).to.exist;
    });

    it("Returns position Info from tokenId", async () => {
      const path = await uniswap.getSwapRouter(USDC, ETH, FeeAmount.HIGH);
      console.log("Token0 Address: ", path);
    });
  });
});

const getMinTick = (tickSpacing: any) => Math.ceil(-887272 / tickSpacing) * tickSpacing;
const getMaxTick = (tickSpacing: any) => Math.floor(887272 / tickSpacing) * tickSpacing;
