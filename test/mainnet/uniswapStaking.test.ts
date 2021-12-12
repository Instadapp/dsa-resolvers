import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, network, config } from "hardhat";
import userDepositedToken from "../../scripts/getUsersToken";
import { expect } from "chai";
import { InstaUniswapStakerResolver, InstaUniswapStakerResolver__factory } from "../../typechain";
import { abi as nftManagerABI } from "@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json";
import { abi as uniswapRouterABI } from "@uniswap/v3-periphery/artifacts/contracts/SwapRouter.sol/SwapRouter.json";
import { abi as IERC20 } from "@openzeppelin/contracts/build/contracts/IERC20.json";
import { abi as stakerABI } from "../../artifacts/contracts/protocols/mainnet/uniswapStaking/interfaces.sol/IUniswapV3Staker.json";

import addLiquidity from "../../scripts/addLiquidity";
import { BigNumber } from "ethers";

let tokenId: any;
let key: any;

const ethAddr = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
const wethAddr = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

const stakerAddress = "0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d";

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

const DAI_ADDR = "0x6b175474e89094c44da98b954eedeac495271d0f";
const ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
const USDT_ADDRESS = "0xdac17f958d2ee523a2206206994597c13d831ec7";

describe("Uniswap", () => {
  let signer: SignerWithAddress;

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Uniswap Resolver", () => {
    let uniswapStakeResolver: InstaUniswapStakerResolver;
    let swapRouter, nftManager: any;
    let uniswapSatker: any;
    let poolAddr: any;
    before(async () => {
      nftManager = await ethers.getContractAt(nftManagerABI, "0xC36442b4a4522E871399CD717aBDD847Ab11FE88");
      swapRouter = await ethers.getContractAt(uniswapRouterABI, "0xE592427A0AEce92De3Edee1F18E0157C05861564");
      uniswapSatker = await ethers.getContractAt(stakerABI, stakerAddress);
      const uniswapStakeResolverFactory = <InstaUniswapStakerResolver__factory>(
        await ethers.getContractFactory("InstaUniswapStakerResolver")
      );
      uniswapStakeResolver = await uniswapStakeResolverFactory.deploy();
      await uniswapStakeResolver.deployed();
    });

    it("deploys the resolver", () => {
      expect(uniswapStakeResolver.address).to.exist;

      console.log("Contract deployed to", uniswapStakeResolver.address);
    });

    it("Should deposit DAI token", async () => {
      await addLiquidity("dai", signer.address, ethers.utils.parseEther("1000"));
      await addLiquidity("usdt", signer.address, ethers.utils.parseEther("1000"));
    });

    it("Should mint NFT position", async () => {
      const daiToken: any = await ethers.getContractAt(IERC20, DAI_ADDR);
      await daiToken.approve(nftManager.address, ethers.utils.parseEther("400"));
      const usdtToken: any = await ethers.getContractAt(IERC20, USDT_ADDRESS);
      await usdtToken.approve(nftManager.address, ethers.utils.parseEther("1000"));
      const tx: any = await nftManager.mint([
        DAI_ADDR,
        USDT_ADDRESS,
        FeeAmount.MEDIUM,
        getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
        getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
        ethers.utils.parseEther("400"),
        ethers.utils.parseEther("400").div(Math.pow(10, 12)),
        "0",
        "0",
        signer.address,
        new Date().getTime().toString(),
      ]);
      const receipt: any = await tx.wait();

      const events: any = await receipt.events;

      tokenId = events[3].args.tokenId;
    });

    it("Should deposit NFT & create incentive successfully", async () => {
      await nftManager["safeTransferFrom(address,address,uint256)"](signer.address, stakerAddress, tokenId);
      const usdtToken: any = await ethers.getContractAt(IERC20, USDT_ADDRESS);
      await usdtToken.approve(uniswapSatker.address, ethers.utils.parseEther("100"));
      poolAddr = await uniswapStakeResolver.getPoolAddress(tokenId);
      key = await uniswapStakeResolver.getIncentiveKey(USDT_ADDRESS, signer.address, poolAddr, 1000);
      await uniswapSatker.createIncentive(key, ethers.utils.parseEther("100"));
    });

    it("Should stake successfully", async () => {
      await uniswapSatker.stakeToken(key, tokenId);
    });

    it("Should return deposited tokenId", async () => {
      const deposited = await uniswapStakeResolver.getDepositedToken(signer.address);
      console.log("Deposited", deposited);
    });

    it("Should return deposited pool address", async () => {
      const poolInfo = await uniswapStakeResolver.getStakedPoolInfo(signer.address);
      console.log("staked pools", poolInfo);
    });

    it("Should return unclaimed rewards", async () => {
      const rewardsInfo = await uniswapStakeResolver.getUnclaimedRewards(USDT_ADDRESS, signer.address);
      console.log("Unclaimed Rewards", rewardsInfo);
    });

    it("Should return rewards rate", async () => {
      const rewardsInfo = await uniswapStakeResolver.getRewardsRate(key);
      console.log("Rewards rate", rewardsInfo);
    });

    it("Should return User's liquidity", async () => {
      const liquidity = await uniswapStakeResolver.getUsersLiquidity(tokenId);
      console.log("User's liquidity", liquidity);
    });

    it("Should return Pool's liquidity", async () => {
      const liquidity = await uniswapStakeResolver.getUsersLiquidity(tokenId);
      console.log("Pool's liquidity", liquidity);
    });

    it("should test successfully", async () => {
      let tokenInfo = await userDepositedToken(signer.address);
      console.log("TokenID", tokenInfo);
    });

    it("Should return positions info", async () => {
      const result: any = await uniswapStakeResolver.getPositions([{ tokenId, incentiveKey: key }], signer.address);
      console.log("result", result);
    });
  });
});

const getMinTick = (tickSpacing: any) => Math.ceil(-887272 / tickSpacing) * tickSpacing;
const getMaxTick = (tickSpacing: any) => Math.floor(887272 / tickSpacing) * tickSpacing;
