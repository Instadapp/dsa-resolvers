import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { InstaMakerResolver, InstaMakerResolver__factory } from "../../typechain";

describe("Maker Resolvers", () => {
  let signer: SignerWithAddress;
  const account = "0xa8ABe411d1A3F524a2aB9C54f8427066a1F9f266";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Maker Resolver", () => {
    let resolver: InstaMakerResolver;

    before(async () => {
      const deployer = new InstaMakerResolver__factory(signer);
      resolver = await deployer.deploy();
    });

    it("returns the dai position properly", async () => {
      const res = await resolver.getDaiPosition(account);
      expect(res.amt).eq(ethers.BigNumber.from("200004660040725427446"));
      expect(res.dsr).eq(ethers.BigNumber.from("1000000000003170820659990704"));
    });
  });
});
