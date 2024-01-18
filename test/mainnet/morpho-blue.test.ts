import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { MorphoBlueResolver, MorphoBlueResolver__factory } from "../../typechain";
import hre from "hardhat";

describe("Morpho blue Resolvers", () => {
  let signer: SignerWithAddress;
  const user = "0xBe0feFb440347d0E021FAc386F7F1906AE0BC99c";
  const marketParams =  [
    {
      loanToken: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", // weth
      collateralToken: "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0", // wsteth
      oracle: "0x2a01EB9496094dA03c4E364Def50f5aD1280AD72",
      irm: "0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC",
      lltv: "945000000000000000"
    },
    {
      loanToken: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // usdc
      collateralToken: "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0", // wsteth
      oracle: "0x48F7E36EB6B826B2dF4B2E630B62Cd25e89E40e2",
      irm: "0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC",
      lltv: "860000000000000000"
    }
  ]

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
              blockNumber: 19034245
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
      const morphoConfig = await morphoBlueResolver.getPosition(user, marketParams);
      console.log("\t*******************Morpho Blue MARKETS******************\n");
      console.log('morphoConfig: ', morphoConfig)

      for (let i = 0; i < morphoConfig[1].length; i++) {
        console.log(`id: ${morphoConfig[1][i].id}`);
        console.log(`totalSuppliedAssets: ${i}: ${morphoConfig[1][i].totalSuppliedAsset}`);
        console.log(`totalSuppliedShares: ${i}: ${morphoConfig[1][i].totalSuppliedShares}`);
        console.log(`totalBorrowedAsset: ${i}: ${morphoConfig[1][i].totalBorrowedAsset}`);
        console.log(`totalBorrowedShares: ${i}: ${morphoConfig[1][i].totalBorrowedShares}`);
        console.log(`supplyAPY: ${i}: ${morphoConfig[1][i].supplyAPY}`);
        console.log(`borrowAPY: ${i}: ${morphoConfig[1][i].borrowAPY}`);
        console.log(`lastUpdate: ${i}: ${morphoConfig[1][i].lastUpdate}`);
        console.log(`fee: ${i}: ${morphoConfig[1][i].fee}`);
        console.log(`utilization: ${i}: ${morphoConfig[1][i].utilization}`);
        console.log(`borrowRateView: ${i}: ${morphoConfig[1][i].borrowRateView}`);
      }

      for (let j = 0; j < morphoConfig[0].length; j++) {
        console.log(`User totalSuppliedAssets: ${j}: ${morphoConfig[0][j].totalSuppliedAssets}`);
        console.log(`User totalBorrowedAssets: ${j}: ${morphoConfig[0][j].totalBorrowedAssets}`);
        console.log(`User totalCollateralAssets: ${j}: ${morphoConfig[0][j].totalCollateralAssets}`);
        console.log(`User healthFactor: ${j}: ${morphoConfig[0][j].healthFactor}`);
      }
    });
  });
});
