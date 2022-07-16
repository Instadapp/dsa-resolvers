import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { EulerResolver, EulerResolver__factory } from "../../typechain";
import { Tokens } from "../consts";
import hre from "hardhat";

describe("Euler Resolver", () => {
  let signer: SignerWithAddress;
  const user = "0x9F60699cE23f1Ab86Ec3e095b477Ff79d4f409AD";
  const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Euler Functions", () => {
    let resolver: EulerResolver;
    let activeSubAccounts: any[];
    let activeTokenIds: any[];

    before(async () => {
      await hre.network.provider.request({
        method: "hardhat_reset",
        params: [
          {
            forking: {
              // eslint-disable-next-line @typescript-eslint/ban-ts-comment
              // @ts-ignore
              jsonRpcUrl: hre.config.networks.hardhat.forking.url,
              blockNumber: 15131233,
            },
          },
        ],
      });

      const deployer = new EulerResolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
      console.log("Resolver deployed at: ", resolver.address);
    });

    it("Returns the positions on Euler", async () => {
      activeSubAccounts = await resolver.getAllActiveSubAccounts(user, [WETH]);
      console.log(activeSubAccounts);
    });

    it("Returns active token Ids", async () => {
      activeTokenIds = activeSubAccounts.map(i => i.id);
      console.log("activeTokenIds: ", activeTokenIds);
    });

    it("Returns position of active subaccounts", async () => {
      const response = await resolver.getPositionOfActiveSubAccounts(user, activeTokenIds, [WETH]);
      console.log(JSON.stringify(response));
    });

    it("Returns the positions of user", async () => {
      const response = await resolver.getPositionsOfUser(user, [WETH, Tokens.DAI.addr]);
      console.log(JSON.stringify(response));
    });
  });
});
