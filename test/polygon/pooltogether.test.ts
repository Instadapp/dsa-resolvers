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
const DAI_POD_ADDR = "0x2f994e2E4F3395649eeE8A89092e63Ca526dA829"; // DAI Pod

const MULTI_TOKEN_LISTENER_ABI = ["function getAddresses() view external returns(address[] memory)"];
const WETH_PRIZE_POOL_ADDR = "0xa88ca010b32a54d446fc38091ddbca55750cbfc3"; // Community WETH Prize Pool (Rari)

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

    async function outputTokenFaucetData(owner: string, tokenFaucetData: any, assetData: any) {
      console.log("\t\t\tAsset Data: ");
      for (let i = 0; i < assetData.length; i++) {
        console.log("\t\t\t\tName: ", assetData[i].name);
        console.log("\t\t\t\tSymbol: ", assetData[i].symbol);
        console.log("\t\t\t\tDecimals: ", assetData[i].decimals.toString());
        console.log("\t\t\t\tAddress: ", tokenFaucetData.asset);
      }
      console.log("\t\t\tDrip Rate Per Second: ", tokenFaucetData.dripRatePerSecond.toString());
      console.log("\t\t\tExchange Rate Mantissa: ", tokenFaucetData.exchangeRateMantissa.toString());
      console.log("\t\t\tTotal Unclaimed: ", tokenFaucetData.totalUnclaimed.toString());
      console.log("\t\t\tLast Drip Timestamp: ", tokenFaucetData.lastDripTimestamp);
      console.log("\t\t\tLast Exchange Rate Mantissa: ", tokenFaucetData.lastExchangeRateMantissa.toString());
      console.log("\t\t\tOwner Balance last calculated: ", tokenFaucetData.balance.toString());
      console.log("\t\t\tOwner Balance when claiming: ", tokenFaucetData.ownerBalance.toString());
    }

    it("Returns the positions correctly for a DAI Prize Pool", async () => {
      //   const owner = "0x30030383d959675ec884e7ec88f05ee0f186cc06";
      const owner = "0x64bcca4ba670cb6777faf79a2406f655d85cf402";
      const prizePools = [DAI_PRIZE_POOL_ADDR];
      const prizePoolData = await resolver.callStatic.getPosition(owner, prizePools);

      for (let i = 0; i < prizePoolData.length; i++) {
        console.log("PrizePool: ", DAI_PRIZE_POOL_ADDR);
        console.log("Underlying Token: ", prizePoolData[i].token);
        // The total underlying balance of all assets. This includes both principal and interest.
        console.log("Balance: ", formatEther(prizePoolData[i].balance));
        // The total of all controlled tokens
        console.log("AccountedBalance: ", formatEther(prizePoolData[i].accountedBalance));
        console.log("AwardBalance: ", formatEther(prizePoolData[i].awardBalance));
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
          console.log("\t\tUser Balance: ", formatUnits(controlledToken.balanceOf, controlledToken.decimals));
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
          const balance = await resolverERC20.getBalances(prizePools[i], [strategyData.getExternalErc20Awards[k]]);
          console.log("\t\t\tBalance: ", balance.toString());
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
              const assetData = await resolverERC20.getTokenDetails([tokenFaucetData.asset]);
              console.log("\t\tTokenFaucet Address: ", addresses[k]);
              await outputTokenFaucetData(owner, tokenFaucetData, assetData);
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
          const assetData = await resolverERC20.getTokenDetails([tokenFaucetData.asset]);
          console.log("\t\tTokenFaucet Address: ", tokenListener);
          await outputTokenFaucetData(owner, tokenFaucetData, assetData);
        } catch (e) {
          console.log("\t\tNon Token Faucet");
        }
      }
    });

    it("Returns the pod positions correctly for a Pod DAI Prize Pool", async () => {
      const owner = "0xb0bd53e103dbd9efba9e4c07ff5b3883a666b78a";
      const pods = [DAI_POD_ADDR];
      const podsData = await resolver.callStatic.getPodPosition(owner, pods);

      for (let i = 0; i < podsData.length; i++) {
        console.log("Pod: ", pods[i]);
        console.log("Name: ", podsData[i].name);
        console.log("Symbol: ", podsData[i].symbol);
        console.log("Decimals: ", podsData[i].decimals.toString());
        console.log("PrizePool: ", podsData[i].prizePool);
        console.log("Price Per Share: ", podsData[i].pricePerShare.toString());
        console.log("Pod Balance: ", podsData[i].balance.toString());
        console.log("Owner Balance: ", podsData[i].balanceOf.toString());
        // Balance of Underlying should be equal when price per share is 1
        console.log("Owner Balance of Underlying: ", podsData[i].balanceOfUnderlying.toString());
        console.log("Total Supply: ", podsData[i].totalSupply.toString());

        // Faucet for the Pod
        console.log("Token Faucet: ", podsData[i].faucet);
        const tokenFaucetData = await resolver.callStatic.getTokenFaucetData(owner, podsData[i].faucet);
        const assetData = await resolverERC20.getTokenDetails([tokenFaucetData.asset]);
        console.log("\t\tTokenFaucet Address: ", podsData[i].faucet);
        await outputTokenFaucetData(owner, tokenFaucetData, assetData);

        // Token Drop distributes token faucet reweards to users
        console.log("Token Drop: ");
        console.log("\tAsset: ", podsData[i].tokenDrop.asset);
        console.log("\tMeasure: ", podsData[i].tokenDrop.measure);
        console.log("\tExchange Rate Mantissa: ", podsData[i].tokenDrop.exchangeRateMantissa.toString());
        console.log("\tTotal Unclaimed: ", podsData[i].tokenDrop.totalUnclaimed.toString());
        console.log("\tLast Drip Timestamp: ", podsData[i].tokenDrop.lastDripTimestamp);
        console.log("\tLast Exchange Rate Mantissa: ", podsData[i].tokenDrop.lastExchangeRateMantissa.toString());
        console.log("\tOwner Balance: ", podsData[i].tokenDrop.ownerBalance.toString());
      }
    });
  });
});
