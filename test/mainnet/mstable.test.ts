import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { simpleToExactAmount, assertBNClosePercent, DEFAULT_DECIMALS } from "../utils";
import { ethers } from "hardhat";
import { InstaMstableResolver, InstaMstableResolver__factory } from "../../typechain";
import { BigNumber } from "ethers";

const mUsdToken = "0xe2f2a5c287993345a840db3b0845fbc70f5935a5";
const daiToken = "0x6b175474e89094c44da98b954eedeac495271d0f";
const alUsdToken = "0xbc6da0fe9ad5f3b0d58160288917aa56653660e9";
const alUsdFeeder = "0x4eaa01974B6594C0Ee62fFd7FEE56CF11E6af936";
const usdcToken = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";

const toEther = (amount: BigNumber) => ethers.utils.formatEther(amount);

describe("mStable Resolvers", () => {
  let signer: SignerWithAddress;

  // account with imUSD Vault balance
  const accountNewVault = "0xab3655b0d22f461900569f2280dccb0c1ccdd628";
  const accountOldVault = "0x42bf6235cfe0aae2ed8782e606d33c992c963010";
  const accountThirdVault = "0x9a4471fd3cbb0deebf5efdedc29313828d55cdf4";
  const accountFourthVault = "0xE76Be9C1e10910d6Bc6b63D8031729747910c2f6";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("mStable Resolver", () => {
    let resolver: InstaMstableResolver;
    before(async () => {
      const deployer = new InstaMstableResolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("Deploys the Resolver", async () => {
      expect(resolver.address).to.be.properAddress;
      expect(await resolver.name()).to.equal("mStable-Mainnet-Resolver-v1");
    });

    it("Should estimateDeposit() mUSD", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver["estimateDeposit(address,uint256)"](mUsdToken, input);
      expect(output).to.eq(input);
    });
    it("Should estimateDeposit() bAsset", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver["estimateDeposit(address,uint256)"](daiToken, input);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should estimateDeposit() fAsset", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver["estimateDeposit(address,uint256,address)"](alUsdToken, input, alUsdFeeder);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should estimateWithdrawal() mUSD", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver["estimateWithdrawal(address,uint256)"](mUsdToken, input);
      expect(output).to.eq(input);
    });
    it("Should estimateWithdrawal() bAsset", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver["estimateWithdrawal(address,uint256)"](daiToken, input);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should estimateWithdrawal() fAsset", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver["estimateWithdrawal(address,uint256,address)"](alUsdToken, input, alUsdFeeder);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should getVestingData()", async () => {
      const data = await resolver.getVestingData(accountOldVault);
      expect(data).to.be.an("array");
      expect(data.length).to.gt(0);
      expect(data[0].start).to.gt(1600000000);
      expect(data[0].finish).to.gt(1600000000);
      expect(data[0].rate).to.gt(0);
    });
    it("Should getLockedAmount() accountNewVault", async () => {
      const [lockedAmount, unlockedAmount] = await resolver.getVestingAmounts(accountNewVault);
      console.log("Locked Amount: ", toEther(lockedAmount));
      console.log("Unlocked Amount: ", toEther(unlockedAmount));
      expect(lockedAmount).to.gte(simpleToExactAmount(0));
      expect(unlockedAmount).to.gte(simpleToExactAmount(0));
    });
    it("Should getLockedAmount() accountOldVault", async () => {
      const [lockedAmount, unlockedAmount] = await resolver.getVestingAmounts(accountOldVault);
      console.log("Locked Amount: ", toEther(lockedAmount));
      console.log("Unlocked Amount: ", toEther(unlockedAmount));
      expect(lockedAmount).to.gte(simpleToExactAmount(0));
      expect(unlockedAmount).to.gte(simpleToExactAmount(0));
    });
    it.only("Should getVaultData() accountOldVault", async () => {
      const userDataOutput = await resolver.getVaultData(accountNewVault);

      expect(userDataOutput).to.be.an("array");
      expect(userDataOutput.credits).to.be.gte(0);
      expect(userDataOutput.balance).to.be.gte(0);
      expect(userDataOutput.exchangeRage).to.be.gte(0);
      expect(userDataOutput.rewardsEarned).to.be.gte(0);
      expect(userDataOutput.rewardsUnclaimed).to.be.gte(0);
      expect(userDataOutput.rewardsLocked).to.be.gte(0);

      console.log("Credits: ", toEther(userDataOutput.credits));
      console.log("Balance: ", toEther(userDataOutput.balance));
      console.log("Exchange Rage: ", toEther(userDataOutput.exchangeRage));
      console.log("Rewards Earned: ", toEther(userDataOutput.rewardsEarned));
      console.log("Rewards Unlocked: ", toEther(userDataOutput.rewardsUnclaimed));
      console.log("Rewards Locked: ", toEther(userDataOutput.rewardsLocked));
    });
    it("Should estimateSwap() mUSD to bAsset", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver["estimateSwap(address,address,uint256)"](mUsdToken, daiToken, input);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should estimateSwap() bAsset to mUSD", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver["estimateSwap(address,address,uint256)"](daiToken, mUsdToken, input);
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should estimateSwap() bAsset to bAsset", async () => {
      const input = simpleToExactAmount(100);
      const usdcScale = ethers.BigNumber.from(10).pow(DEFAULT_DECIMALS - 6);
      const output = (await resolver["estimateSwap(address,address,uint256)"](daiToken, usdcToken, input)).mul(
        usdcScale,
      );
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
    it("Should estimateSwap() via Feeder", async () => {
      const input = simpleToExactAmount(100);
      const output = await resolver["estimateSwap(address,address,uint256,address)"](
        mUsdToken,
        alUsdToken,
        input,
        alUsdFeeder,
      );
      expect(output).to.not.eq(input);
      assertBNClosePercent(input, output, 1);
    });
  });
});
