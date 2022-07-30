import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { EulerResolver, EulerResolver__factory } from "../../typechain";
// import { Tokens } from "../consts";
import hre from "hardhat";

describe("Euler Resolver", () => {
  let signer: SignerWithAddress;
  const user = "0x7338afb07db145220849B04A45243956f20B14d9";
  const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  const EUL = "0xd9Fcd98c322942075A5C3860693e9f4f03AAE07b";
  const agEUR = "0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8";
  const ENS = "0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72";
  const oSQTH = "0xf1B99e3E573A1a9C5E6B2Ce818b617F0E664E86B";
  const SHIB = "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE";
  const RBN = "0x6123B0049F904d730dB3C36a31167D9d4121fA6B";
  const CVX = "0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B";
  const PERP = "0xbC396689893D065F41bc2C6EcbeE5e0085233447";
  const AXS = "0xBB0E17EF65F82Ab018d8EDd776e8DD940327B28b";
  const tokens = [WETH, EUL, agEUR, ENS, oSQTH, SHIB, RBN, CVX, PERP, AXS];

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
              blockNumber: 15240589,
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
      const response = await resolver.getPositionOfActiveSubAccounts(user, ["0", "1"], tokens);
      console.log(JSON.stringify(response));
    });

    it("Returns the positions of user", async () => {
      // const response = await resolver.getAllPositionsOfUser(user, ["0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"]);
      // console.log(JSON.stringify(response));
      console.log(
        (await resolver.getAllPositionsOfUser(user, ["0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"])).toString,
      );
    });
  });
});
