import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatUnits } from "ethers/lib/utils";
import { simpleToExactAmount, assertBNClosePercent, DEFAULT_DECIMALS } from "../utils";
import { ethers } from "hardhat";
import { InstaMstableResolver, InstaMstableResolver__factory } from "../../typechain";

const mUsdToken = "0xe2f2a5c287993345a840db3b0845fbc70f5935a5";
const daiToken = "0x6b175474e89094c44da98b954eedeac495271d0f";
const alUsdToken = "0xbc6da0fe9ad5f3b0d58160288917aa56653660e9";
const alUsdFeeder = "0x4eaa01974B6594C0Ee62fFd7FEE56CF11E6af936";
const usdcToken = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";

describe("mStable Resolvers", () => {
  let signer: SignerWithAddress;

  // account with imUSD Vault balance
  const account = "0x2082A3604DAD1CD4109EAee06bc21C2f85c6FA29";

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
    it.skip("Should getVaultBalance()", async () => {
      return true;
    });
    it.skip("Should getUserData()", async () => {
      return true;
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
