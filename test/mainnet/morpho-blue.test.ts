import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { MorphoBlueResolver, MorphoBlueResolver__factory } from "../../typechain";
import hre from "hardhat";

describe("Morpho blue Resolvers", () => {
  let signer: SignerWithAddress;
  const user = "0xB5d870D24Fa7C0993a30c2fefAa83A40DC5a447a";
  const MarketParams =  {
    loanToken: "",
    collateralToken: "",
    oracle: "",
    irm: "",
    lltv: ""
  }

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Morpho blue Resolver", () => {
    let morphoBlueResolver: MorphoBlueResolver;
    before(async () => {
      await hre.network.provider.request({
        method: "hardhat_reset",
        params: [
          {
            forking: {
              // eslint-disable-next-line @typescript-eslint/ban-ts-comment
              // @ts-ignore
              jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            },
          },
        ],
      });

      const deployer = new MorphoBlueResolver__factory(signer);
      morphoBlueResolver = await deployer.deploy();
      await morphoBlueResolver.deployed();

      console.log("Morpho Resolver deployed at: ", morphoBlueResolver.address);
    });

    it("Returns the morpho's configurations", async () => {
      const morphoConfig = await morphoBlueResolver.getPosition(user, [MarketParams]);
      console.log("\t*******************Morpho Blue MARKETS******************\n");

      for (const marketData of morphoConfig.marketData) {
        console.log(`totalSupplyAssets: ${marketData.market.totalSupplyAssets}`);
        console.log(`totalSupplyShares: ${marketData.market.totalSupplyShares}`);
        console.log(`totalBorrowAssets: ${marketData.market.totalBorrowAssets}`);
        console.log(`totalBorrowShares: ${marketData.market.totalBorrowShares}`);
        console.log(`lastUpdate: ${marketData.market.lastUpdate}`);
        console.log(`market fee: ${marketData.market.fee}`);
        console.log(`totalSuppliedAsset: ${marketData.totalSuppliedAsset}`);
        console.log(`totalBorrowedAsset: ${marketData.totalBorrowedAsset}`);
        console.log(`supplyAPR: ${marketData.supplyAPR}`);
        console.log(`borrowAPR: ${marketData.borrowAPR}`);
        console.log(`lastUpdate: ${marketData.lastUpdate}`);
        console.log(`fee: ${marketData.fee}`);
      }

      for (const positionData of morphoConfig.userDataData) {
        console.log(`totalSuppliedAssets: ${positionData.totalSuppliedAssets}`);
        console.log(`totalBorrowedAssets: ${positionData.totalBorrowedAssets}`);
        console.log(`totalCollateralAssets: ${positionData.totalCollateralAssets}`);
        console.log(`healthFactor: ${positionData.healthFactor}`);
        console.log(`Position.supplyShares: ${positionData.position.supplyShares}`);
        console.log(`Position.borrowShares: ${positionData.position.borrowShares}`);
        console.log(`Position.collateral: ${positionData.position.collateral}`);
      }

    });
  });
});
