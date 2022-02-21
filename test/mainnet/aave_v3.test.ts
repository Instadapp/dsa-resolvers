import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { AaveV3Resolver, AaveV3Resolver__factory } from "../../typechain";
import { Tokens } from "../consts";

describe("Aave V3 Resolvers", () => {
  let signer: SignerWithAddress;
  const account = "0x15C6b352c1F767Fa2d79625a40Ca4087Fab9a198";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Aave V3 Resolver", () => {
    let resolver: AaveV3Resolver;
    before(async () => {
      const deployer = new AaveV3Resolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("should get user configurations and reserves list", async () => {
      const reservesList = await resolver.getReservesList();
      const reserves = await resolver.getConfiguration(account);
      console.log("Collateral Reserves Address");
      console.log(reservesList);
      console.log(reserves);
      for (let i = 0; i < reserves[0].length; i++) {
        if (reserves[0][i]) {
          console.log(`- ${reservesList[i]}`);
        }
      }
      console.log("Borrowed Reserves Address");
      for (let i = 0; i < reserves[1].length; i++) {
        if (reserves[1][i]) {
          console.log(`- ${reservesList[i]}`);
        }
      }
    });

    it("Returns the positions on AaveV3", async () => {
      const results = await resolver.getPosition(account, [Tokens.DAI.addr]);
      const userTokenData = results[0];
      // const userData = results[1];

      // check for token balances
      console.log("Supply Balance DAI: ", formatUnits(userTokenData[0].supplyBalance, Tokens.DAI.decimals));
      expect(userTokenData[0].supplyBalance).to.gte(0);
      console.log(
        "Variable Borrow Balance DAI: ",
        formatUnits(userTokenData[0].variableBorrowBalance, Tokens.DAI.decimals),
      );
      expect(userTokenData[0].variableBorrowBalance).to.gte(0);
      // check for user data
      // expect(userData.totalBorrowsBase).to.gte(0);
      // expect(userData.totalCollateralETH).to.gte(0);
    });
  });
});
