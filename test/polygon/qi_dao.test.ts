import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { InstaQiDaoResolverPolygon, InstaQiDaoResolverPolygon__factory } from "../../typechain";

describe("QiDao Resolvers", () => {
  let signer: SignerWithAddress;
  const maticVaultAddress = "0xa3fa99a148fa48d14ed51d610c367c61876997f1";
  const maticERC721Address = "0x6af1d9376a7060488558cfb443939ed67bb9b48d";
  const gnosisSafeAddress = "0x1d8a6b7941ef1349c1b5E378783Cd56B001EcfBc";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("QiDao Resolver", () => {
    let resolver: InstaQiDaoResolverPolygon;
    before(async () => {
      const deployer = new InstaQiDaoResolverPolygon__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("deploys the resolver", () => {
      expect(resolver.address).to.exist;
    });

    it("should get vault 0 collateral", async () => {
      const vaultCollateral = await resolver.getVaultCollateral(maticVaultAddress, 0);
      expect(vaultCollateral.gte(0));
    });

    it("should get vault 0 debt", async () => {
      const vaultDebt = await resolver.getVaultDebt(maticVaultAddress, 0);
      expect(vaultDebt.eq(0));
    });

    it("should return the vault index of an owner", async () => {
      const vaultCollateral = await resolver.getVaultByOwnerIndex(maticERC721Address, gnosisSafeAddress, 0);
      expect(vaultCollateral.eq(0));
    });

    it("should return the vault index of an owner", async () => {
      const vaults = await resolver.getAllVaultsByOwner(maticVaultAddress, maticERC721Address, gnosisSafeAddress);
      const [vaultId, , vaultDebt] = vaults[0];
      expect(vaultId.eq(0));
      expect(vaultDebt.eq(0));
    });
  });
});
