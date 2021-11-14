import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaAaveV2ResolverPolygon, InstaAaveV2ResolverPolygon__factory } from "../../typechain";
import { Tokens } from "../consts";

describe("Aave V2 Resolvers", () => {
  let signer: SignerWithAddress;
  const account = "0x697F5736eE44454fD1Ab614d9fAB237BD1FDB25C";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Aave V2 Resolver", () => {
    let resolver: InstaAaveV2ResolverPolygon;
    before(async () => {
      const deployer = new InstaAaveV2ResolverPolygon__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("deploys the resolver", () => {
      expect(resolver.address).to.exist;
    });

    it("should get user configurations and reserves list", async () => {
      const reservesList = await resolver.getReservesList();
      const reserves = await resolver.getConfiguration(account);
      console.log("Collateral Reserves Address");
      for (let i = 0; i < reserves[0].length; i++) {
        if (reserves[0][i].toNumber() === 1) {
          console.log(reservesList[i]);
        }
      }
      console.log("Borrowed Reserves Address");
      for (let i = 0; i < reserves[1].length; i++) {
        if (reserves[1][i].toNumber() === 1) {
          console.log(reservesList[i]);
        }
      }
    });

    it("Returns the positions on AaveV2", async () => {
      const daiAddr = "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063";
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
