import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { simpleToExactAmount, assertBNClosePercent, DEFAULT_DECIMALS } from "../utils";
import { ethers } from "hardhat";
import { InstaPMstableResolver, InstaPMstableResolver__factory } from "../../typechain";
import { BigNumber } from "ethers";

const mUsdToken = "0xe840b73e5287865eec17d250bfb1536704b43b21";
const daiToken = "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063";
const fraxToken = "0x104592a158490a9228070E0A8e5343B499e125D0";
const fraxFeeder = "0xb30a907084ac8a0d25dddab4e364827406fd09f0";
const usdcToken = "0x2791bca1f2de4661ed88a30c99a7a9449aa84174";

const toEther = (amount: BigNumber) => ethers.utils.formatEther(amount);

describe("mStable Resolvers", () => {
  let signer: SignerWithAddress;

  // accounts with imUSD Vault balance currently or before
  const accountWithVault = "0x9a593151c7935aa2c636f9c862e0c4df4934cdfd";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("mStable Resolver", () => {
    let resolver: InstaPMstableResolver;
    before(async () => {
      const deployer = new InstaPMstableResolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("Deploys the Resolver", async () => {
      expect(resolver.address).to.be.properAddress;
      expect(await resolver.name()).to.equal("mStable-Polygon-Resolver-v1");
    });

    it("Should estimateDeposit() mUSD", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver.estimateDeposit(mUsdToken, input);
      expect(output).to.eq(input);
    });
    it("Should estimateDeposit() bAsset", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver.estimateDeposit(daiToken, input);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should estimateDepositWithPath() fAsset", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver.estimateDepositWithPath(fraxToken, input, fraxFeeder);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should estimateWithdrawal() mUSD", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver.estimateWithdrawal(mUsdToken, input);
      expect(output).to.eq(input);
    });
    it("Should estimateWithdrawal() bAsset", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver.estimateWithdrawal(daiToken, input);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should estimateWithdrawalWithPath() fAsset", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver.estimateWithdrawalWithPath(fraxToken, input, fraxFeeder);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should getRewards() accountNewVault", async () => {
      const [rewardsEarned, platformRewards] = await resolver.getRewards(accountWithVault);
      console.log("rewardsEarned:", toEther(rewardsEarned));
      console.log("platformRewards:", toEther(platformRewards));
      expect(rewardsEarned).to.gte(0);
      expect(platformRewards).to.gte(0);
    });
    it("Should getVaultData() accountOldVault", async () => {
      const userDataOutput = await resolver.getVaultData(accountWithVault);

      expect(userDataOutput).to.be.an("array");
      expect(userDataOutput.credits).to.be.gte(0);
      expect(userDataOutput.balance).to.be.gte(0);
      expect(userDataOutput.exchangeRate).to.be.gte(0);
      expect(userDataOutput.rewardsEarned).to.be.gte(0);
      expect(userDataOutput.platformRewards).to.be.gte(0);

      console.log("Credits: ", toEther(userDataOutput.credits));
      console.log("Balance: ", toEther(userDataOutput.balance));
      console.log("Exchange Rate: ", toEther(userDataOutput.exchangeRate));
      console.log("Rewards Earned: ", toEther(userDataOutput.rewardsEarned));
      console.log("Platform Rewards: ", toEther(userDataOutput.platformRewards));
    });
    it("Should estimateSwap() mUSD to bAsset", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver.estimateSwap(mUsdToken, daiToken, input);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should estimateSwap() bAsset to mUSD", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver.estimateSwap(daiToken, mUsdToken, input);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should estimateSwap() bAsset to bAsset", async () => {
      const input = simpleToExactAmount(100);
      const usdcScale = ethers.BigNumber.from(10).pow(DEFAULT_DECIMALS - 6);
      const output = (await resolver.estimateSwap(daiToken, usdcToken, input)).mul(usdcScale);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should estimateSwapWithPath() via Feeder", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver.estimateSwapWithPath(mUsdToken, fraxToken, input, fraxFeeder);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
  });
});
