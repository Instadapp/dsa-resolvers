import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, network, config } from "hardhat";
import { expect } from "chai";
import { ResolverV2UniverseFinance, ResolverV2UniverseFinance__factory } from "../../typechain";

const { BigNumber } = ethers;

describe("Uniswap", () => {
  let signer: SignerWithAddress;
  const vault = "0x5EC191A7Fd4CcC4f1369C2A6281E95aAf0AE9d8d";
  const user = "0x6C0E34EBAED7ce5a0Ca97cF98EF41dfA3a8ecc7F";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Universe Resolver", () => {
    let universe: ResolverV2UniverseFinance;
    before(async () => {
      const liquityFactory = <ResolverV2UniverseFinance__factory>(
        await ethers.getContractFactory("ResolverV2UniverseFinance")
      );
      universe = await liquityFactory.deploy();
      await universe.deployed();
    });

    it("deploys the resolver", () => {
      expect(universe.address).to.exist;
    });

    it("should get vault data", async () => {
      const allvaults = await universe.getAllVault();
      const vaultsData = await universe.getVaultDetail(allvaults);

      for (let i = 0; i < vaultsData.length; i++) {
        console.log(vaultsData[i]);
      }
    });

    it("should get correct decimals", async () => {
      const decimals = await universe.decimals(vault);
      console.log(decimals);
    });

    it("Should deposit", async () => {
      const decimals = await universe.decimals(vault);
      const [shareToken0Amount, shareToken1Amount] = await universe.getUserDepositAmount(
        vault,
        ethers.utils.parseEther("1"),
        ethers.utils.parseEther("1"),
      );
      console.log(`shareToken0Amount: ${Number(shareToken0Amount) / 10 ** decimals[0]}`);
      console.log(`shareToken1Amount: ${Number(shareToken1Amount) / 10 ** decimals[1]}`);
    });

    it("should withdraw", async () => {
      const [token0Amount, token1Amount] = await universe.getUserWithdrawAmount(vault, user);
      const decimals = await universe.decimals(vault);

      console.log(`token0Amount: ${Number(token0Amount) / 10 ** decimals[0]}`);
      console.log(`token1Amount: ${Number(token1Amount) / 10 ** decimals[1]}`);
    });

    it("should get user position by vaults and user addresses", async () => {
      const rawData = await universe.position([vault], user);
      const decimals = await universe.decimals(vault);
      const [share0, share1, amount0, amount1] = rawData[0];

      console.log(`share0: ${Number(share0) / 10 ** decimals[0]}`);
      console.log(`share1: ${Number(share1) / 10 ** decimals[1]}`);
      console.log(`amount0: ${Number(amount0) / 10 ** decimals[0]}`);
      console.log(`amount1: ${Number(amount1) / 10 ** decimals[1]}`);
    });

    it("should get position and vault data by user address", async () => {
      const rawData = await universe.positionByVault([vault], user);
      const decimals = await universe.decimals(vault);
      const [share0, share1, amount0, amount1] = rawData[0][0];
      const vaultData = rawData[1];

      console.log(`share0: ${Number(share0) / 10 ** decimals[0]}`);
      console.log(`share1: ${Number(share1) / 10 ** decimals[1]}`);
      console.log(`amount0: ${Number(amount0) / 10 ** decimals[0]}`);
      console.log(`amount1: ${Number(amount1) / 10 ** decimals[1]}`);
      console.log(`vault data: ${vaultData}`);
    });

    it("should get position and vault data by user address", async () => {
      const rawData = await universe.positionByAddress(user);
      const decimals = await universe.decimals(vault);
      const [share0, share1, amount0, amount1] = rawData[0][0];
      const vaultData = rawData[1];

      console.log(`share0: ${Number(share0) / 10 ** decimals[0]}`);
      console.log(`share1: ${Number(share1) / 10 ** decimals[1]}`);
      console.log(`amount0: ${Number(amount0) / 10 ** decimals[0]}`);
      console.log(`amount1: ${Number(amount1) / 10 ** decimals[1]}`);
      console.log(`vault datas: ${vaultData}`);
    });
  });
});
