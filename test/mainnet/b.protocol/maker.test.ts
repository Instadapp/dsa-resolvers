import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { InstaBMakerResolver, InstaBMakerResolver__factory } from "../../../typechain";

describe("B.Maker Resolvers", () => {
  let signer: SignerWithAddress;
  const account = "0x9788A89a055d727E737dE733e7D1D01D99FCD542";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("B.Maker Resolver", () => {
    let resolver: InstaBMakerResolver;

    before(async () => {
      const deployer = new InstaBMakerResolver__factory(signer);
      resolver = await deployer.deploy();
    });

    it("returns the vault info properly", async () => {
      const res = await resolver.getVaults(account);

      expect(res.length).to.be.equal(1);
      const vault = res[0];

      expect(vault[0]).to.be.equal("0xbc"); // id
      expect(vault[1]).to.be.equal(account); // owner
      expect(vault[2]).to.be.equal("ETH-A"); // collateral type 
      expect(vault[3]).to.be.equal("0x0163a06b6e044000"); // collateral 0.1001 ETH
      expect(vault[4]).to.be.equal("0"); // art
      
      const singleRes = await resolver.getVaultById(0xbc);
      expect(JSON.stringify(singleRes)).to.be.equal(JSON.stringify(res[0]));
    });
  });
});
