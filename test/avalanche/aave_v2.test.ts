import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaAaveV2ResolverAvalanche, InstaAaveV2ResolverAvalanche__factory } from "../../typechain";
import { Tokens } from "../consts";

describe("Aave V2 Resolvers", () => {
  let signer: SignerWithAddress;
  const account = "0xE8549B7CE9634C98D0cdAE8b74CEF4C853756f1C";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Aave V2 Resolver", () => {
    let resolver: InstaAaveV2ResolverAvalanche;
    before(async () => {
      const deployer = new InstaAaveV2ResolverAvalanche__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("Deploys the resolver", async () => {
      expect(resolver.address).to.exist;
    });

    it("should get user configurations and reserves list", async () => {
      const reservesList = await resolver.getReservesList();
      const reserves = await resolver.getConfiguration(account);
      console.log("Collateral Reserves Address");
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

    it("Should get prices", async () => {
      const weth = "0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB";
      const avax = "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7";

      const avaxPrice = await resolver.getPrice([avax]);
      const ethPrice = await resolver.getPrice([weth]);
      const decimal = 1e18;

      console.log(
        `Price avaxPrice : In eth (${Number(avaxPrice[0][0].priceInEth) / decimal}), In USD (${
          Number(avaxPrice[0][0].priceInUsd) / decimal
        }) `,
      );
      console.log(
        `Price ethPrice : In eth (${Number(ethPrice[0][0].priceInEth) / decimal}), In USD (${
          Number(ethPrice[0][0].priceInUsd) / decimal
        }) `,
      );
    });
  });
});
