import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaAaveV2Resolver, InstaAaveV2ResolverAvalanche__factory } from "../../typechain";
import { Tokens } from "../consts";

describe("Aave V2 Resolvers", () => {
  let signer: SignerWithAddress;
  const account = "0xE8549B7CE9634C98D0cdAE8b74CEF4C853756f1C";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Aave V2 Resolver", () => {
    let resolver: InstaAaveV2Resolver;
    before(async () => {
      const deployer = new InstaAaveV2ResolverAvalanche__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("Should successfully deploy", async () => {
      console.log("deployed");
    });

    it("Returns the positions on AaveV2", async () => {
      const daiAddr = "0xd586E7F844cEa2F87f50152665BCbc2C279D8d70";
      const results = await resolver.getPosition(account, [daiAddr]);
      const userTokenData = results[0];
      const userData = results[1];

      // check for token balances
      console.log("Supply Balance DAI: ", formatUnits(userTokenData[0].supplyBalance, Tokens.DAI.decimals));
      expect(userTokenData[0].supplyBalance).to.gte(0);
      console.log(
        "Variable Borrow Balance DAI: ",
        formatUnits(userTokenData[0].variableBorrowBalance, Tokens.DAI.decimals),
      );
      expect(userTokenData[0].variableBorrowBalance).to.gte(0);

      // check for user data
      expect(userData.totalBorrowsETH).to.gte(0);
      expect(userData.totalCollateralETH).to.gte(0);
    });
  });
});
