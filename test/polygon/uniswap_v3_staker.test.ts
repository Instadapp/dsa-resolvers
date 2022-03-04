import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaUniswapStakerResolverPolygon__factory, InstaUniswapStakerResolverPolygon } from "../../typechain";
import { Tokens } from "../consts";

let signer: SignerWithAddress;

const stakerAddress = "0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d";

describe("Uniswap", () => {
  let signer: SignerWithAddress;
  let uniswapStakeResolver: InstaUniswapStakerResolverPolygon;
  let swapRouter, nftManager: any;
  let uniswapSatker: any;
  let poolAddr: any;
  before(async () => {
    const uniswapStakeResolverFactory = <InstaUniswapStakerResolverPolygon__factory>(
      await ethers.getContractFactory("InstaUniswapStakerResolverPolygon")
    );
    uniswapStakeResolver = await uniswapStakeResolverFactory.deploy();
    await uniswapStakeResolver.deployed();
  });

  it("deploys the resolver", () => {
    expect(uniswapStakeResolver.address).to.exist;

    console.log("Contract deployed to", uniswapStakeResolver.address);
  });

  it("Should run the functions", async () => {
    const params = [
      {
        key: {
          endTime: "1649210400",
          pool: "0x45dda9cb7c25131df268515131f647d726f50608",
          refundee: "0xc4a71290b16ac201782996b3022558b74ade7615",
          rewardToken: "0x25dbe484e8f96154904b2e58201e7829af394eda",
          startTime: "1641438000",
        },
        minUpperTick: 197500,
        minLowerTick: 197490,
        maxUpperTick: 887220,
        maxLowerTick: -887220,
      },
      {
        key: {
          endTime: "1642046400",
          pool: "0x0eaa1e140f9b2f40564b8deb89a13d02c0826bde",
          refundee: "0x2d21d2b0404093ef9485db72145177150e48be41",
          rewardToken: "0x371b97c779e8c5197426215225de0eeac7dd13af",
          startTime: "1642037400",
        },
        minUpperTick: -81600,
        minLowerTick: -81800,
        maxUpperTick: 887220,
        maxLowerTick: -887220,
      },
      {
        key: {
          endTime: "1645244412",
          pool: "0xeb00f118fde9a921aade0919200e0efb401a5e3d",
          refundee: "0x546d090bbcec3d96903d41e38c3436c1c601af9c",
          rewardToken: "0x5423063af146f5abf88eb490486e6b53fa135ec9",
          startTime: "1642393212",
        },
        minUpperTick: 887400,
        minLowerTick: 887200,
        maxUpperTick: 887220,
        maxLowerTick: -887220,
      },
      {
        key: {
          endTime: "1644699600",
          pool: "0x45dda9cb7c25131df268515131f647d726f50608",
          refundee: "0x6bdf44c97b38c12cc6e022335f1535cf7c765507",
          rewardToken: "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063",
          startTime: "1642021200",
        },
        minUpperTick: 197500,
        minLowerTick: 197490,
        maxUpperTick: 887220,
        maxLowerTick: -887220,
      },
    ];
    const response = await uniswapStakeResolver.getRewardsDetailsMinAndMax(params);

    const pools = ["0x45dda9cb7c25131df268515131f647d726f50608", "0xeb00f118fde9a921aade0919200e0efb401a5e3d"];
    const tokens = await uniswapStakeResolver.getTokensAddr(pools);
    console.log(tokens);
  });
});
