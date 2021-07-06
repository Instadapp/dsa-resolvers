import { ethers, network, config } from "hardhat";
import {
  InstaLiquityResolver,
  InstaLiquityResolver__factory,
  PriceFeedOracle,
  PriceFeedOracle__factory,
} from "../../typechain";
import { useChai } from "../utils";
const { BigNumber } = ethers;
const expect = useChai();

// Deterministic block number to run these tests from on forked mainnet. If you change this, tests will break.
const BLOCK_NUMBER = 12478959;

// Liquity user with a Trove, Stability deposit, and Stake
const JUSTIN_SUN_ADDRESS = "0x903d12bf2c57a29f32365917c706ce0e1a84cce3";

// Liquity price oracle
const PRICE_FEED_ADDRESS = "0x4c517D4e2C851CA76d7eC94B805269Df0f2201De";

/* Begin: Mock test data (based on specified BLOCK_NUMBER and JUSTIN_SUN_ADDRESS) */
const expectedTrovePosition = {
  collateral: BigNumber.from("582880000000000000000000"),
  debt: BigNumber.from("372000200000000000000000000"),
  icr: BigNumber.from("3859882210893925325"),
};
const expectedStabilityPosition = {
  deposit: BigNumber.from("299979329615565997640451998"),
  ethGain: BigNumber.from("8629038660000000000"),
  lqtyGain: BigNumber.from("53244322633874479119945"),
};
const expectedStakePosition = {
  amount: BigNumber.from("981562996504090969804965"),
  ethGain: BigNumber.from("18910541408996344243"),
  lusdGain: BigNumber.from("66201062534511228032281"),
};
const expectedSystemState = {
  borrowFee: BigNumber.from("6900285109012952"),
  ethTvl: BigNumber.from("852500462432421494350957"),
  tcr: BigNumber.from("3250195441371082828"),
  isInRecoveryMode: false,
};
const expectedTrovePositionHints = {
  upperHint: "0xbf9a4eCC4151f28C03100bA2C0555a3D3e439e69",
  lowerHint: "0xa4FC81A7AB93360543eb1e814D0127f466012CED",
};
const expectedRedemptionPositionHints = {
  partialRedemptionHintNicr: "69529933762909647",
  firstHint: "0xc16aDd8bA17ab81B27e930Da8a67848120565d8c",
  upperHint: "0x66882C005188F0F4d95825ED7A7F78ed3055f167",
  lowerHint: "0x0C22C11a8ed4C23ffD19629283548B1692b58e92",
};
/* End: Mock test data */

describe("InstaLiquityResolver", () => {
  let liquity: InstaLiquityResolver;
  let liquityPriceOracle: PriceFeedOracle;

  before(async () => {
    await resetHardhatBlockNumber(BLOCK_NUMBER); // Start tests from clean mainnet fork at BLOCK_NUMBER

    const liquityFactory = <InstaLiquityResolver__factory>await ethers.getContractFactory("InstaLiquityResolver");

    liquityPriceOracle = PriceFeedOracle__factory.connect(PRICE_FEED_ADDRESS, ethers.provider);

    liquity = await liquityFactory.deploy();

    await liquity.deployed();
  });

  it("deploys the resolver", () => {
    expect(liquity.address).to.exist;
  });

  describe("getTrove()", () => {
    it("returns a user's Trove position", async () => {
      const trovePosition = await liquity.callStatic.getTrove(JUSTIN_SUN_ADDRESS);

      expect(trovePosition.collateral).to.equal(expectedTrovePosition.collateral);
      expect(trovePosition.debt).to.equal(expectedTrovePosition.debt);
      expect(trovePosition.icr).to.equal(expectedTrovePosition.icr);
    });
  });

  describe("getStabilityDeposit()", () => {
    it("returns a user's Stability Pool position", async () => {
      const stabilityPosition = await liquity.getStabilityDeposit(JUSTIN_SUN_ADDRESS);
      expect(stabilityPosition.deposit).to.equal(expectedStabilityPosition.deposit);
      expect(stabilityPosition.ethGain).to.equal(expectedStabilityPosition.ethGain);
      expect(stabilityPosition.lqtyGain).to.equal(expectedStabilityPosition.lqtyGain);
    });
  });

  describe("getStake()", () => {
    it("returns a user's Stake position", async () => {
      const stakePosition = await liquity.getStake(JUSTIN_SUN_ADDRESS);
      expect(stakePosition.amount).to.equal(expectedStakePosition.amount);
      expect(stakePosition.ethGain).to.equal(expectedStakePosition.ethGain);
      expect(stakePosition.lusdGain).to.equal(expectedStakePosition.lusdGain);
    });
  });

  describe("getPosition()", () => {
    it("returns a user's Liquity position", async () => {
      const position = await liquity.callStatic.getPosition(JUSTIN_SUN_ADDRESS);
      const expectedPosition = {
        trove: expectedTrovePosition,
        stability: expectedStabilityPosition,
        stake: expectedStakePosition,
      };
      expect(position.trove.collateral).to.equal(expectedPosition.trove.collateral);
      expect(position.trove.debt).to.equal(expectedPosition.trove.debt);
      expect(position.trove.icr).to.equal(expectedPosition.trove.icr);

      expect(position.stability.deposit).to.equal(expectedPosition.stability.deposit);
      expect(position.stability.ethGain).to.equal(expectedPosition.stability.ethGain);
      expect(position.stability.lqtyGain).to.equal(expectedPosition.stability.lqtyGain);

      expect(position.stake.amount).to.equal(expectedPosition.stake.amount);
      expect(position.stake.ethGain).to.equal(expectedPosition.stake.ethGain);
      expect(position.stake.lusdGain).to.equal(expectedPosition.stake.lusdGain);
    });
  });

  describe("getSystemState()", () => {
    it("returns Liquity system state", async () => {
      const systemState = await liquity.callStatic.getSystemState();
      expect(systemState.borrowFee).to.equal(expectedSystemState.borrowFee);
      expect(systemState.ethTvl).to.equal(expectedSystemState.ethTvl);
      expect(systemState.tcr).to.equal(expectedSystemState.tcr);
      expect(systemState.isInRecoveryMode).to.equal(expectedSystemState.isInRecoveryMode);
    });
  });

  describe("getTrovePositionHints()", () => {
    it("returns the upper and lower address of Troves nearest to the given Trove", async () => {
      const collateral = ethers.utils.parseEther("10");
      const debt = ethers.utils.parseUnits("5000", 18); // 5,000 LUSD
      const searchIterations = 10;
      const randomSeed = 3;
      const [upperHint, lowerHint] = await liquity.getTrovePositionHints(
        collateral,
        debt,
        searchIterations,
        randomSeed,
      );

      expect(upperHint).eq(expectedTrovePositionHints.upperHint);
      expect(lowerHint).eq(expectedTrovePositionHints.lowerHint);
    });
  });

  describe("getRedemptionPositionHints()", () => {
    it("returns the upper and lower address of the range of Troves to be redeemed against the given amount", async () => {
      const amount = ethers.utils.parseUnits("10000", 18); // 10,000 LUSD
      const searchIterations = 10;
      const randomSeed = 3;
      const [partialRedemptionHintNicr, firstHint, upperHint, lowerHint] =
        await liquity.callStatic.getRedemptionPositionHints(amount, searchIterations, randomSeed);

      expect(partialRedemptionHintNicr).eq(expectedRedemptionPositionHints.partialRedemptionHintNicr);
      expect(firstHint).eq(expectedRedemptionPositionHints.firstHint);
      expect(upperHint).eq(expectedRedemptionPositionHints.upperHint);
      expect(lowerHint).eq(expectedRedemptionPositionHints.lowerHint);
    });
  });
});

const resetHardhatBlockNumber = async (blockNumber: number) => {
  return await network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: config.networks.hardhat.forking!.url,
          blockNumber,
        },
      },
    ],
  });
};
