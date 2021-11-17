import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { formatEther, formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import {
  InstaPoolTogetherV4PolygonResolver,
  InstaPoolTogetherV4PolygonResolver__factory,
  InstaERC20Resolver,
  InstaERC20Resolver__factory,
} from "../../typechain";

// https://www.npmjs.com/package/@pooltogether/draw-calculator-js
import { calculateDrawResults } from "@pooltogether/draw-calculator-js";
import { doesNotThrow } from "assert";

const hre = require("hardhat");

const ALCHEMY_ID = process.env.ALCHEMY_POLYGON_API_KEY;

const USDC_PRIZE_POOL_ADDR = "0x19DE635fb3678D8B8154E37d8C9Cdf182Fe84E60"; // USDC Prize Pool
const DRAW_BUFFER_ADDR = "0x44B1d66E7B9d4467139924f31754F34cbC392f44";
const PRIZE_DISTRIBUTOR_ADDR = "0x8141BcFBcEE654c5dE17C4e2B2AF26B67f9B9056";
const DRAW_CALCULATOR_TIME_LOCK_ADDR = "0x676a541cF8CBa8C324ACE66E8dFd19CAcF9c7484";

describe("PoolTogether Resolvers", () => {
  let signer: SignerWithAddress;

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
            blockNumber: 20668404,
          },
        },
      ],
    });

    [signer] = await ethers.getSigners();
  });

  describe("PoolTogother Resolver", () => {
    let resolver: InstaPoolTogetherV4PolygonResolver;
    let resolverERC20: InstaERC20Resolver;

    before(async () => {
      const deployer = new InstaPoolTogetherV4PolygonResolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();

      const deployer2 = new InstaERC20Resolver__factory(signer);
      resolverERC20 = await deployer2.deploy();
      await resolverERC20.deployed();
    });

    it("Returns the positions correctly for a USDC Prize Pool", async () => {
      const owner = "0x05db7a553b1acd10e0774ab809314cacafb4943b";
      const prizePools = [USDC_PRIZE_POOL_ADDR];
      const prizePoolData = await resolver.callStatic.getPosition(
        owner,
        prizePools,
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
