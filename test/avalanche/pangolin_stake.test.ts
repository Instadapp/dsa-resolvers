import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, network, config } from "hardhat";
import { expect } from "chai";
import { InstaPangolinStakeResolver, InstaPangolinStakeResolver__factory } from "../../typechain";
import { BigNumber } from "ethers";

describe("Pangolin Stake", async () => {
  let signer: SignerWithAddress;

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Pangolin Stake Resolver", async () => {
    let pangolin_stake: InstaPangolinStakeResolver;
    before(async () => {
      const pangolinresolver = <InstaPangolinStakeResolver__factory>(
        await ethers.getContractFactory("InstaPangolinStakeResolver")
      );
      pangolin_stake = await pangolinresolver.deploy();
      await pangolin_stake.deployed();
    });

    it("deploys the resolver", () => {
      expect(pangolin_stake.address).to.exist;
      if (!!pangolin_stake.address) {
        console.log("Resolver address: " + pangolin_stake.address);
      }
    });

    it("Returns LP stake Data", async () => {
      const [lpAddress, stakedAmount, pendingReward, totalStaked] = await pangolin_stake.getLPStakeData(
        signer.address,
        BigNumber.from("0"),
      );
      console.log("--- Returns LP stake Data ---");
      console.log("lpAddress: " + lpAddress);
      console.log("stakedAmount: " + stakedAmount.toString());
      console.log("pendingReward: " + pendingReward.toString());
      console.log("totalStaked: " + totalStaked.toString());
    });

    describe("getPIDbyLPAddress function", async () => {
      it("Returns PID by address with success true", async () => {
        const [pid, success] = await pangolin_stake.getPIDbyLPAddress("0xd7538cABBf8605BdE1f4901B47B8D42c61DE0367");
        console.log("--- Returns PID and Success ---");
        console.log("pid: " + pid.toString());
        console.log("success: " + success);
      });

      it("Not returns because is not added token", async () => {
        const [pid, success] = await pangolin_stake.getPIDbyLPAddress("0x78d4BFb3b50E5895932073DC5Eb4713eb532941B");
        console.log("--- Returns PID and Success ---");
        console.log("pid: " + pid.toString());
        console.log("success: " + success);
      });
    });

    it("Returns PNG Satake Data", async () => {
      const [stakedAmount, pendingReward, rewardToken, totalStaked] = await pangolin_stake.getPNGStakeData(
        signer.address,
        "0x78d4BFb3b50E5895932073DC5Eb4713eb532941B",
      );
      console.log("--- Returns PNG Satake Data---");
      console.log("stakedAmount: " + stakedAmount.toString());
      console.log("pendingReward: " + pendingReward.toString());
      console.log("rewardToken: " + rewardToken);
      console.log("totalStaked: " + totalStaked.toString());
    });
  });
});
