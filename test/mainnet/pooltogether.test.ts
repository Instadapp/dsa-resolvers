import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { formatEther, formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import {
  InstaPoolTogetherResolver,
  InstaPoolTogetherResolver__factory,
  InstaERC20Resolver,
  InstaERC20Resolver__factory,
} from "../../typechain";

const DAI_PRIZE_POOL_ADDR = "0xEBfb47A7ad0FD6e57323C8A42B2E5A6a4F68fc1a"; // DAI Prize Pool
const POOL_PRIZE_POOL_ADDR = "0x396b4489da692788e327e2e4b2b0459a5ef26791"; // POOL Prize Pool
const USDC_PRIZE_POOL_ADDR = "0xde9ec95d7708b8319ccca4b8bc92c0a3b70bf416"; // USDC Prize Pool

const MULTI_TOKEN_LISTENER_ABI = ["function getAddresses() view external returns(address[] memory)"];

describe("PoolTogether Resolvers", () => {
  let signer: SignerWithAddress;

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("PoolTogother Resolver", () => {
    let resolver: InstaPoolTogetherResolver;
    let resolverERC20: InstaERC20Resolver;

    before(async () => {
      const deployer = new InstaPoolTogetherResolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();

      const deployer2 = new InstaERC20Resolver__factory(signer);
      resolverERC20 = await deployer2.deploy();
      await resolverERC20.deployed();
    });

    it("Returns the positions correctly for a DAI Prize Pool", async () => {
      const owner = "0x30030383d959675ec884e7ec88f05ee0f186cc06";
      const prizePools = [DAI_PRIZE_POOL_ADDR];
      const prizePoolData = await resolver.callStatic.getPoolTogetherData(owner, prizePools);

      for (let i = 0; i < prizePoolData.length; i++) {
        console.log("PrizePool: ", DAI_PRIZE_POOL_ADDR);
        console.log("Underlying Token", prizePoolData[i].token);
        console.log("AccountedBalance: ", formatEther(prizePoolData[i].accountedBalance));
        console.log("AwardBalance: ", formatEther(prizePoolData[i].awardBalance));
        console.log("Balance: ", formatEther(prizePoolData[i].balance));
        console.log("Max Exit Fee Mantissa: ", formatEther(prizePoolData[i].maxExitFeeMantissa));
        console.log("Reserve Total Supply: ", formatEther(prizePoolData[i].reserveTotalSupply));
        console.log("Liquidity Cap: ", formatEther(prizePoolData[i].liquidityCap));
        console.log("Tickets/Sponsorships: ");
        for (let j = 0; j < prizePoolData[i].tokenData.length; j++) {
          const controlledToken = prizePoolData[i].tokenData[j];
          console.log("\tTokenData: ");
          console.log("\t\tName: ", controlledToken.name);
          console.log("\t\tAddress: ", controlledToken.addr);
          console.log("\t\tSymbol: ", controlledToken.symbol);
          console.log("\t\tDecimals: ", controlledToken.decimals.toString());
          console.log("\t\tUser Balance: ", formatUnits(controlledToken.balance, controlledToken.decimals));
          console.log("\t\tCredit Limit: ", controlledToken.creditLimitMantissa.toString());
          console.log("\t\tCredit Rate: ", controlledToken.creditRateMantissa.toString());
        }

        const strategyData = prizePoolData[i].prizeStategyData;
        const tokenListener = strategyData.tokenListener;
        console.log("PrizeStategy: ");
        console.log("\tAddress: ", strategyData.addr);
        console.log("\tPrize Period Remaining Seconds: ", strategyData.prizePeriodRemainingSeconds.toString());
        console.log("\tIs Prize Period Over: ", strategyData.isPrizePeriodOver);
        console.log("\tPrize Period End At: ", strategyData.prizePeriodEndAt.toString());
        console.log("\tGet ExternalErc20 Awards: ");
        const assetData = await resolverERC20.getTokenDetails(strategyData.getExternalErc20Awards);
        console.log("\t\tExternal ERC20 Awards: ");
        for (let k = 0; k < assetData.length; k++) {
          console.log("\t\t\tName: ", assetData[k].name);
          console.log("\t\t\tSymbol: ", assetData[k].symbol);
          console.log("\t\t\tDecimals: ", assetData[k].decimals.toString());
          console.log("\t\t\tAddress: ", strategyData.getExternalErc20Awards[k]);
        }
        console.log("\tGet ExternalErc721 Awards: ", strategyData.getExternalErc721Awards);
        console.log("\tToken Listener: ", tokenListener);

        // Check if MultiTokenListener, TokenFaucet, or other TokenListener
        try {
          const tokenListenerContract = new ethers.Contract(tokenListener, MULTI_TOKEN_LISTENER_ABI, ethers.provider);
          const addresses = await tokenListenerContract.getAddresses();
          console.log("\tMultiTokenListener Addresses");

          for (let k = 0; k < addresses.length; k++) {
            try {
              const tokenFaucetData = await resolver.callStatic.getTokenFaucetData(owner, addresses[k]);
              console.log("\t\tTokenFaucet Address: ", addresses[k]);
              console.log("\t\t\tAsset: ", tokenFaucetData.asset);
              const assetData = await resolverERC20.getTokenDetails([tokenFaucetData.asset]);
              console.log("Asset Data: ", assetData);
              console.log("\t\t\tDrip Rate Per Second: ", tokenFaucetData.dripRatePerSecond.toString());
              console.log("\t\t\tExchange Rate Mantissa: : ", tokenFaucetData.exchangeRateMantissa.toString());
              console.log("\t\t\tTotal Unclaimed: : ", tokenFaucetData.totalUnclaimed.toString());
              console.log("\t\t\tLast Drip Timestamp: : ", tokenFaucetData.lastDripTimestamp);
              console.log("\t\t\tLast Exchange Rate Mantissa: : ", tokenFaucetData.lastExchangeRateMantissa.toString());
              console.log("\t\t\tBalance: : ", tokenFaucetData.balance.toString());
              console.log("\t\t\tOwner Balance: : ", tokenFaucetData.ownerBalance.toString());
            } catch (e) {
              // Ignore if not token faucet
              console.log("\t\tNon TokenFaucet Address: ", addresses[k]);
            }
          }
        } catch (e) {
          // Non MultiTokenListener
          // console.log("Non MultitokenListener");
        }

        try {
          const tokenFaucetData = await resolver.callStatic.getTokenFaucetData(owner, tokenListener);
          console.log("\t\tTokenFaucet Address: ", tokenListener);
          const assetData = await resolverERC20.getTokenDetails([tokenFaucetData.asset]);
          console.log("\t\t\tAsset Data: ");
          for (let i = 0; i < assetData.length; i++) {
            console.log("\t\t\t\tName: ", assetData[i].name);
            console.log("\t\t\t\tSymbol: ", assetData[i].symbol);
            console.log("\t\t\t\tDecimals: ", assetData[i].decimals.toString());
            console.log("\t\t\t\tAddress: ", tokenFaucetData.asset);
          }
          console.log("\t\t\tDrip Rate Per Second: ", tokenFaucetData.dripRatePerSecond.toString());
          console.log("\t\t\tExchange Rate Mantissa: : ", tokenFaucetData.exchangeRateMantissa.toString());
          console.log("\t\t\tTotal Unclaimed: : ", tokenFaucetData.totalUnclaimed.toString());
          console.log("\t\t\tLast Drip Timestamp: : ", tokenFaucetData.lastDripTimestamp);
          console.log("\t\t\tLast Exchange Rate Mantissa: : ", tokenFaucetData.lastExchangeRateMantissa.toString());
          console.log("\t\t\tBalance: : ", tokenFaucetData.balance.toString());
          console.log("\t\t\tOwner Balance: : ", tokenFaucetData.ownerBalance.toString());
        } catch (e) {
          console.log("Non Token Faucet");
        }
      }
    });
  });
});
