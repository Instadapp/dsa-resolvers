import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { InstaYearnV2Resolver, InstaYearnV2Resolver__factory } from "../../typechain";
import { Tokens } from "../consts";

describe("YearnV2 Resolvers", () => {
  let signer: SignerWithAddress;
  const account = "0xe8e8f41ed29e46f34e206d7d2a7d6f735a3ff2cb";
  const unsupportedERC20 = "0x0d8775f648430679a709e98d2b0cb6250d2887ef";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("YearnV2 Resolvers", () => {
    let resolver: InstaYearnV2Resolver;
    before(async () => {
      const deployer = new InstaYearnV2Resolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("Should check if a token is supported", async () => {
      const unsupportedToken = await resolver.isWantSupported(unsupportedERC20);
      await expect(unsupportedToken).to.be.false;
      const supportedToken = await resolver.isWantSupported(Tokens.DAI.addr);
      await expect(supportedToken).to.be.true;
    });

    it("Should retrieve the number of vaults for DAI", async () => {
      const num = await resolver.numVaultsForWant(Tokens.DAI.addr);
      await expect(num).to.be.gt(0);
    });

    it("Should retrieve the vaults addresses for DAI", async () => {
      const vaults = await resolver.listVaultsForWant(Tokens.DAI.addr);
      await expect(vaults.length).to.be.gt(0);
    });

    it("Should retrieve 0 vault address for notSupportedERC20", async () => {
      const vaults = await resolver.listVaultsForWant(unsupportedERC20);
      await expect(vaults.length).to.be.eq(0);
    });

    it("Should retrieve the depositLimit", async () => {
      const vaults = await resolver.listVaultsForWant(Tokens.DAI.addr);
      await expect(vaults.length).to.be.gt(0);
      const depositLimit = await resolver.getAvailableDepositLimit(vaults[vaults.length - 1]);
      await expect(depositLimit).to.be.gt(0);
    });

    it("Should retrieve the pricePerShare", async () => {
      const vaults = await resolver.listVaultsForWant(Tokens.DAI.addr);
      await expect(vaults.length).to.be.gt(0);
      const pricePerShare = await resolver.getPricePerShare(vaults[vaults.length - 1]);
      await expect(pricePerShare).to.be.gt(0);
    });

    it("Should check if a vault is in emergencyShutdown", async () => {
      const vaults = await resolver.listVaultsForWant(Tokens.DAI.addr);
      await expect(vaults.length).to.be.gt(0);
      await expect(resolver.isEmergencyShutdown(vaults[vaults.length - 1])).not.to.be.reverted;
    });

    it("Should check the balance of an user", async () => {
      const vaults = await resolver.listVaultsForWant(Tokens.DAI.addr);
      await expect(vaults.length).to.be.gt(0);
      const balance = await resolver.getBalance(account, vaults[vaults.length - 1]);
      await expect(balance).to.be.gte(0);
    });

    it("Should check the balance of an user", async () => {
      const vaults = await resolver.listVaultsForWant(Tokens.DAI.addr);
      await expect(vaults.length).to.be.gt(0);
      const shareValue = await resolver.getExpectedShareValue(account, vaults[vaults.length - 1]);
      await expect(shareValue).to.be.gte(0);
    });

    it("Should check the balance of an user", async () => {
      const vaults = await resolver.getPositions(account, [Tokens.DAI.addr, Tokens.USDC.addr]);
      for (let index = 0; index < vaults.length; index++) {
        const vault = vaults[index];
        if (!vault.balanceOf.isZero()) {
          expect(vault.balanceOf).to.gt(vault.wantBalanceOf);
        }
      }
    });
  });
});
