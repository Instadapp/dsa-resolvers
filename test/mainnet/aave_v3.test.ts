import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatUnits } from "ethers/lib/utils";
import { ethers, web3 } from "hardhat";
import { AaveV3Resolver, AaveV3Resolver__factory } from "../../typechain";
import { Tokens } from "../consts";
import BigNumber from "bignumber.js";

describe("Aave", () => {
  let signer: SignerWithAddress;
  // const account = "0xde33f4573bB315939a9D1E65522575E1a9fC3e74";
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
      const results = await resolver.callStatic.getPosition(account, [
        "0x2Ec4c6fCdBF5F9beECeB1b51848fc2DB1f3a26af",
        "0x5B8B635c2665791cf62fe429cB149EaB42A3cEd8",
      ]);
      const userTokenData = results[0];
      const tokenData = results[1];
      const userData = results[2];

      //check tokenPrice
      const daiPriceInETH = tokenData[0].tokenPrice.priceInEth;
      const daiPriceInUsd = tokenData[0].tokenPrice.priceInUsd;

      console.log(`Price of DAI in ETH: ${Number(daiPriceInETH) / 10 ** 18}`);
      console.log(`Price of DAI in Usd: ${Number(daiPriceInUsd) / 10 ** 18}`);

      // check for token balances
      console.log("Supply Balance USDC: ", formatUnits(userTokenData[0].supplyBalance, Tokens.USDC.decimals));
      expect(userTokenData[0].supplyBalance).to.gte(0);
      console.log(
        "Stable Borrow Balance USDC: ",
        formatUnits(userTokenData[1].stableBorrowBalance, Tokens.USDC.decimals),
      );
      console.log(`ltv: ${tokenData[1].ltv}`);

      expect(userTokenData[0].variableBorrowBalance).to.gte(0);
      // check for user data
      expect(userData.totalBorrowsBase).to.gte(0);
      expect(userData.totalCollateralBase).to.gte(0);
    });

    it("Returns the e-mode category details of e-modeID", async () => {
      const emodeData = await resolver.getEmodeCategoryData(1);
      console.log(`emodeData: ${emodeData}`);
    });
  });
});
