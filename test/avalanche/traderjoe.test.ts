import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { JoeResolver, JoeResolver__factory } from "../../typechain";
import { Tokens } from "../consts";
import BigNumber from "bignumber.js";

describe("TraderJoe", () => {
  let signer: SignerWithAddress;
  // const account = "0xde33f4573bB315939a9D1E65522575E1a9fC3e74";
  const account = "0x15C6b352c1F767Fa2d79625a40Ca4087Fab9a198";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Trader Joe Resolver", () => {
    let resolver: JoeResolver;
    before(async () => {
      const deployer = new JoeResolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("Returns the positions on traderJOe", async () => {
      const results = await resolver.callStatic.getPosition(account, [
        "0xEd6AaF91a2B084bd594DBd1245be3691F9f637aC",
        "0xc988c170d0E38197DC634A45bF00169C7Aa7CA19",
      ]);

      //check user collateral and supplies
      const supplies = results.totalCollateralUSD;
      const borrows = results.totalBorrowUSD;
      expect(supplies).to.gte(0);
      expect(borrows).to.gte(0);
      console.log(`Supplies in USD: ${Number(supplies) / 10 ** 18}`);
      console.log(`Borrows in USD: ${Number(borrows) / 10 ** 18}`);

      // check for token data
      console.log(`tokenData USDC: ${results.tokensData[0]}`);
      console.log(`tokenData DAI: ${results.tokensData[1]}`);
    });
  });
});
