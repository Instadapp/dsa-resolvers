import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { formatEther, formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import {
  InstaPoolTogetherV4Resolver,
  InstaPoolTogetherV4Resolver__factory,
  InstaERC20Resolver,
  InstaERC20Resolver__factory,
} from "../../typechain";

// https://www.npmjs.com/package/@pooltogether/draw-calculator-js
import { calculateDrawResults } from "@pooltogether/draw-calculator-js";
import { doesNotThrow } from "assert";

const hre = require("hardhat");

const ALCHEMY_ID = process.env.ALCHEMY_API_KEY;

const USDC_PRIZE_POOL_ADDR = "0xd89a09084555a7D0ABe7B111b1f78DFEdDd638Be"; // USDC Prize Pool
const DRAW_BEACON_ADDR = "0x0D33612870cd9A475bBBbB7CC38fC66680dEcAC5";
const PRIZE_DISTRIBUTOR_ADDR = "0xb9a179DcA5a7bf5f8B9E088437B3A85ebB495eFe";
const DRAW_CALCULATOR_TIME_LOCK_ADDR = "0x6Ab2C44A548b8ac1D166Afbf490B200Ad4261c15";

describe("PoolTogether Resolvers", () => {
  let signer: SignerWithAddress;

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
            blockNumber: 13545682,
          },
        },
      ],
    });

    [signer] = await ethers.getSigners();
  });

  describe("PoolTogother Resolver", () => {
    let resolver: InstaPoolTogetherV4Resolver;
    let resolverERC20: InstaERC20Resolver;

    before(async () => {
      const deployer = new InstaPoolTogetherV4Resolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();

      const deployer2 = new InstaERC20Resolver__factory(signer);
      resolverERC20 = await deployer2.deploy();
      await resolverERC20.deployed();
    });

    it("Returns the positions correctly for a USDC Prize Pool", async () => {
      const owner = "0xf7b34b89b2261e31fc0ad6ab6210adc51b6fc9b6";
      const prizePools = [USDC_PRIZE_POOL_ADDR];
      const prizePoolData = await resolver.callStatic.getPosition(
        owner,
        prizePools,
        DRAW_BEACON_ADDR,
        PRIZE_DISTRIBUTOR_ADDR,
        DRAW_CALCULATOR_TIME_LOCK_ADDR,
      );

      for (let i = 0; i < prizePoolData.length; i++) {
        console.log("PrizePool: ", USDC_PRIZE_POOL_ADDR);
        console.log("Underlying Token: ", prizePoolData[i].token);

        // The total underlying balance of all assets. This includes both principal and interest.
        console.log("Balance: ", formatEther(prizePoolData[i].balance));

        // The total of all controlled tokens
        console.log("AccountedBalance: ", formatEther(prizePoolData[i].accountedBalance));
        console.log("AwardBalance: ", formatEther(prizePoolData[i].awardBalance));
        console.log("Liquidity Cap: ", formatEther(prizePoolData[i].liquidityCap));

        // Ticket Data
        const ticketData = prizePoolData[i].ticketData;
        console.log("\tTicketData: ");
        console.log("\t\tName: ", ticketData.name);
        console.log("\t\tAddress: ", ticketData.addr);
        console.log("\t\tSymbol: ", ticketData.symbol);
        console.log("\t\tDecimals: ", ticketData.decimals.toString());
        // User balances at current block
        console.log("\t\tUser BalanceOf: ", formatUnits(ticketData.balanceOf, ticketData.decimals));
        console.log("\t\tUser BalanceAt eligible for prize: ", formatUnits(ticketData.balanceAt, ticketData.decimals));
        // Total supply is total amount deposited in prize pool by everyone
        console.log("\t\tTotal Supply/Amount deposited: ", formatUnits(ticketData.totalSupply, ticketData.decimals));
        console.log("\t\tDelegateOf: ", ticketData.delegateOf);

        // Draw data
        console.log("Draws: ");
        const drawsData = prizePoolData[i].drawsData;
        const prizeDistributionsData = drawsData.prizeDistributions;
        const draws = drawsData.draws;

        const exampleUser = {
          address: owner, // user address we want to calculate for
          normalizedBalances: drawsData.normalizedBalancesForDrawIds,
        };

        // Loop through draws not including current draw
        for (let j = 0; j < draws.length; j++) {
          // Draw Data
          console.log("\tDraw Id: ", draws[j].drawId);
          console.log("\t\tWinning Number: ", draws[j].winningRandomNumber._hex);
          console.log("\t\tTimeStamp: ", draws[j].timestamp.toString());
          console.log("\t\tbeaconPeriodStartedAt: ", draws[j].beaconPeriodStartedAt.toString());
          console.log("\t\tbeaconPeriodSeconds: ", draws[j].beaconPeriodSeconds);
          // PrizeDistribution Data https://v4.docs.pooltogether.com/protocol/concepts/prize-distribution
          console.log("\t\tPrizeDistribution: ");
          console.log("\t\t\tBit Range Size: ", prizeDistributionsData[j].bitRangeSize);
          console.log("\t\t\tMatch Cardinality: ", prizeDistributionsData[j].matchCardinality);
          console.log("\t\t\tStart Timestamp Offset: ", prizeDistributionsData[j].startTimestampOffset);
          console.log("\t\t\tEnd Timestamp Offset: ", prizeDistributionsData[j].endTimestampOffset);
          console.log("\t\t\tMax Picks Per User: ", prizeDistributionsData[j].maxPicksPerUser);
          console.log("\t\t\tExpiry Duration: ", prizeDistributionsData[j].expiryDuration);
          // Number of Picks allocated to this chain based on total deposits vs all chains
          console.log("\t\t\tNumber Of Picks: ", prizeDistributionsData[j].numberOfPicks.toString());
          // Number of combinations/picks = (2^bit range)^cardinality
          const totalNumberOfPicks =
            (2 ** prizeDistributionsData[j].bitRangeSize) ** prizeDistributionsData[j].matchCardinality;
          console.log("\t\t\tTotal Number of Picks: ", totalNumberOfPicks);
          // Each prize pool is alloted a portion of the total picks proportional to its contribution to the prize network liquidity for the week.
          console.log(
            "\t\t\tPercentage of picks for chain: ",
            ((prizeDistributionsData[j].numberOfPicks.toNumber() / totalNumberOfPicks) * 100).toFixed(2),
            "%",
          );
          // Total Ticket TWAB Supply
          console.log("\t\t\tAverage Total Supply TWAB: ", formatUnits(drawsData.totalSupply[j], ticketData.decimals));
          // Price per pick = number of picks / Average Total Supply TWAB
          console.log(
            "\t\t\tPrice per pick: ",
            drawsData.totalSupply[j].toNumber() / 1e6 / prizeDistributionsData[j].numberOfPicks.toNumber(),
          );
          console.log("\t\t\tTotal Prize Amount: ", prizeDistributionsData[j].prize.toString());
          console.log("\t\t\tTiers: ", prizeDistributionsData[j].tiers.toString());
          const tiers = prizeDistributionsData[j].tiers;
          let numberOfPrizesForIndex = 1;
          for (let k = 0; k < tiers.length; k++) {
            if (tiers[k] != 0) {
              console.log(
                "\t\t\t\tTier Prize",
                k,
                ethers.BigNumber.from(tiers[k]).mul(ethers.BigNumber.from(prizeDistributionsData[j].prize)).toString(),
              );
              if (k > 0) {
                // Number of prizes for a degree = (2^bit range)^degree - (2^bit range)^(degree-1)
                numberOfPrizesForIndex =
                  (1 << (prizeDistributionsData[j].bitRangeSize * k)) -
                  (1 << (prizeDistributionsData[j].bitRangeSize * (k - 1)));
              }
              console.log("\t\t\t\t\tNumberofPrizesForIndex: ", numberOfPrizesForIndex);
              // prize for a degree(tier) = total prize * degree percentage / number of prizes for a degree
              const tierPrize =
                ((prizeDistributionsData[j].prize.toNumber() / 1e9) * tiers[k]) / numberOfPrizesForIndex / 1e6;
              console.log("\t\t\t\t\tTier Prize: $", tierPrize);
            }
          }

          // User Normalized Balances
          console.log("\t\tUser Normalizaed Balance: ", drawsData.normalizedBalancesForDrawIds[j].toString());
          // User Draw Picks
          console.log("\t\tUser Draw Picks: ", drawsData.userDrawData[j].drawPicks.toString());
          // User TWAB for this draw
          console.log("\t\tUser BalanceAt: ", formatUnits(drawsData.userDrawData[j].balanceAt, ticketData.decimals));
          // > 0 if user has claimed for this draw
          console.log("\t\tUser Payout Balance: ", drawsData.userDrawData[j].payoutBalance.toString());
          var abiEncodedValue = ethers.utils.solidityPack(
            ["bytes32", "uint256"],
            [ethers.utils.solidityKeccak256(["address"], [owner]), 105],
          );
          var userRandomNumber = ethers.utils.solidityKeccak256(["address"], [abiEncodedValue]);

          // Have to convert to Number because datatypes wasn't matching and got BigNumber
          const draw = {
            drawId: draws[j].drawId,
            winningRandomNumber: draws[j].winningRandomNumber,
            timestamp: draws[j].timestamp.toNumber(),
            beaconPeriodStartedAt: draws[j].beaconPeriodStartedAt.toNumber(),
            beaconPeriodSeconds: draws[j].beaconPeriodSeconds,
          };

          // Calculation intensive because it must compare all picks to winningRandomNumber
          const results = calculateDrawResults(prizeDistributionsData[j], draw, exampleUser, j);
          console.log("\t\tUser Prizes:");
          for (let l = 0; l < results.prizes.length; l++) {
            console.log(
              "\t\t\tAmount: $",
              results.prizes[l].amount.toNumber() / 1e6,
              " distributionIndex: ",
              results.prizes[l].distributionIndex,
              "pick: ",
              results.prizes[l].pick.toString(),
            );
          }
          console.log("\t\t\tTotal Value: ", results.totalValue.toNumber() / 1e6);
        }

        // Current Draw Beacon Data
        const drawBeaconData = prizePoolData[i].drawBeaconData;
        console.log("Current DrawBeaconData:");
        console.log("\tisRngCompleted: ", drawBeaconData.isRngCompleted);
        console.log("\tisRngRequested: ", drawBeaconData.isRngRequested);
        console.log("\tisRngTimedOut: ", drawBeaconData.isRngTimedOut);
        console.log("\tcanStartDraw: ", drawBeaconData.canStartDraw);
        console.log("\tcanCompleteDraw: ", drawBeaconData.canCompleteDraw);
        console.log(
          "\tcalculateNextBeaconPeriodStartTimeFromCurrentTime: ",
          drawBeaconData.nextBeaconPeriodStartTimeFromCurrentTime.toString(),
        );
        console.log("\tbeaconPeriodRemainingSeconds: ", drawBeaconData.beaconPeriodRemainingSeconds.toString());
        console.log("\tbeaconPeriodEndAt: ", drawBeaconData.beaconPeriodEndAt.toString());
        console.log("\tbeaconPeriodSeconds: ", drawBeaconData.beaconPeriodSeconds);
        console.log("\tbeaconPeriodStartedAt: ", drawBeaconData.beaconPeriodStartedAt.toString());
        console.log("\tdrawBuffer: ", drawBeaconData.drawBuffer);
        console.log("\tnextDrawId: ", drawBeaconData.nextDrawId);
        console.log("\tlastRngLockBlock: ", drawBeaconData.lastRngLockBlock);
        console.log("\trngTimeOut: ", drawBeaconData.rngTimeout);
        console.log("\tisBeaconPeriodOver: ", drawBeaconData.isBeaconPeriodOver);

        console.log("Draw Calculator Timelock:");
        console.log("\tTimeLock drawId: ", prizePoolData[i].timelock.drawId);
        console.log("\tTimeLock timestamp: ", prizePoolData[i].timelock.timestamp.toString());
        console.log("\tTimeLock hasElapsed: ", prizePoolData[i].hasElapsed);

        // Won't know user's number of picks until after prizeDistribution set, but can estimate with previous prizeDistribution
        //  assuming it stays the same and number of deposits stays around the same.
      }
    });
  });
});
