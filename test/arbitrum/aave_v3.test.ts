import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import hre from "hardhat";
import { expect } from "chai";
import { formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaAaveV3ResolverArbitrum, InstaAaveV3ResolverArbitrum__factory } from "../../typechain";
import { Tokens } from "../consts";

describe("Aave", () => {
  const POOL_ADDRESS_PROVIDER_ARBITRUM = '0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb'
  let signer: SignerWithAddress;
  const account = "0x545358c58C1dE83b54759f1A64487c83Cb6fdf26";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Aave V3 Resolver", () => {
    let resolver: InstaAaveV3ResolverArbitrum;
    before(async () => {
      await hre.network.provider.request({
        method: "hardhat_reset",
        params: [
          {
            forking: {
              // eslint-disable-next-line @typescript-eslint/ban-ts-comment
              // @ts-ignore
              jsonRpcUrl: hre.config.networks.arbitrum.url,
              blockNumber: 261807484,
            },
          },
        ],
      });

      const deployer = new InstaAaveV3ResolverArbitrum__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("should get user configurations and reserves list", async () => {
      const reservesList = await resolver.getReservesList(POOL_ADDRESS_PROVIDER_ARBITRUM);
      const reserves = await resolver.getConfiguration(account, POOL_ADDRESS_PROVIDER_ARBITRUM);
      console.log("Collateral Reserves Address");
      console.log(reservesList);
      console.log(reserves);
      for (let i = 0; i < reserves[0].length; i++) {
        if (reserves[0][i]) {
          console.log(`- ${reservesList[i]}`);
        }
      }
      console.log("Borrowed Reserves Address");
      for (let i = 0; i < reserves[1].length; i++) {
        if (reserves[1][i]) {
          console.log(`- ${reservesList[i]}`);
        }
      }
    });

    it("Returns the positions on AaveV3", async () => {
      const results = await resolver.callStatic.getPosition(account, [
        "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
        "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4",
      ], POOL_ADDRESS_PROVIDER_ARBITRUM);
      const userTokenData = results[1];
      const tokenData = results[2];
      const userData = results[0];

      //check tokenPrice
      // const daiPriceInETH = tokenData[0].tokenPrice.priceInEth;
      // const daiPriceInUsd = tokenData[0].tokenPrice.priceInUsd;

      // console.log(`Price of DAI in ETH: ${Number(daiPriceInETH) / 10 ** 18}`);
      // console.log(`Price of DAI in Usd: ${Number(daiPriceInUsd) / 10 ** 18}`);

      // check for token balances
      console.log("Supply Balance USDC: ", formatUnits(userTokenData[0].supplyBalance, Tokens.USDC.decimals));
      expect(userTokenData[0].supplyBalance).to.gte(0);
      console.log(
        "Stable Borrow Balance USDC: ",
        formatUnits(userTokenData[1].stableBorrowBalance, Tokens.USDC.decimals),
      );
      console.log(`ltv: ${tokenData[1].ltv}`);

      expect(userTokenData[0].variableBorrowBalance).to.gte(0);
      // check for user data
      expect(userData.totalBorrowsBase).to.gte(0);
      expect(userData.totalCollateralBase).to.gte(0);
    });

    it("Returns the user's positions on AaveV3 for all assets", async () => {
      const results = await resolver.callStatic.getPositionAll(account, POOL_ADDRESS_PROVIDER_ARBITRUM);
      const userTokenData = results[1];
      const tokenData = results[2];
      const userData = results[0];
      const rewards = results[3];

      // check for user data
      expect(userData.totalBorrowsBase).to.gte(0);
      expect(userData.totalCollateralBase).to.gte(0);
      console.log();
      console.log("*************************************************");
      console.log("User Data");
      console.log("*************************************************");
      console.log(`totalCollateralInBase: ${userData.totalCollateralBase}`);
      console.log(`totalBorrowsInBase: ${userData.totalBorrowsBase}`);
      console.log(`availableBorrowsInBase: ${userData.availableBorrowsBase}`);
      console.log(`liquidationThreshold: ${userData.currentLiquidationThreshold}`);
      console.log(`ltv: ${userData.ltv}`);
      console.log(`healthFactor: ${userData.healthFactor}`);
      console.log(`eModeId: ${userData.eModeId}`);
      console.log(`BaseAddress: ${userData.base.baseAddress}`);
      // console.log(`BaseInUsd: ${userData.base.baseInUSD}`);
      console.log(`BaseSymbol: ${userData.base.symbol}`);

      console.log();
      console.log("*************************************************");
      console.log("Assets Data");
      console.log("*************************************************");
      for (let i = 0; i < tokenData.length; i++) {
        console.log();
        console.log(`Reserve: ${tokenData[i].asset}`);
        console.log(`Symbol: ${tokenData[i].symbol}`);
        console.log("Supply Balance: ", formatUnits(userTokenData[i].supplyBalance, tokenData[i].decimals));
        console.log(
          "Stable Borrow Balance: ",
          formatUnits(userTokenData[i].stableBorrowBalance, tokenData[i].decimals),
        );
        console.log(
          "Variable Borrow Balance: ",
          formatUnits(userTokenData[i].variableBorrowBalance, tokenData[i].decimals),
        );
        console.log(`Supply rate: ${userTokenData[i].supplyRate}`);
        console.log(`Stable Borrow Rate: ${userTokenData[i].stableBorrowRate}`);
        console.log(`User Stable Borrow Rate: ${userTokenData[i].userStableBorrowRate}`);
        console.log(`Variable Borrow Rate: ${userTokenData[i].variableBorrowRate}`);
        console.log(`ltv: ${tokenData[i].ltv}`);
        console.log(`liquidation threshold: ${tokenData[i].threshold}`);
        console.log(`Reserve factor: ${tokenData[i].reserveFactor}`);
        console.log(`Total Supply: ${tokenData[i].totalSupply}`);
        console.log(`Available liquidity: ${tokenData[i].availableLiquidity}`);
        console.log("Total stable debt: ", formatUnits(tokenData[i].totalStableDebt, tokenData[i].decimals));
        console.log("Total variable debt: ", formatUnits(tokenData[i].totalVariableDebt, tokenData[i].decimals));
        console.log(`Price in base: ${userTokenData[i].price}`);
        // console.log(`Price in ETH: ${Number(tokenData[i].tokenPrice.priceInEth) / 10 ** 18}`);
        // console.log(`Price in Usd: ${Number(tokenData[i].tokenPrice.priceInUsd) / 10 ** 18}`);
        console.log(`Supply cap: ${tokenData[i].token.supplyCap}`);
        console.log(`Borrow cap: ${tokenData[i].token.borrowCap}`);
        console.log(`Borrowable in isolation mode: ${tokenData[i].token.isolationBorrowEnabled}`);
        console.log("----------------------------------------------------");
        console.log("aToken Rewards Details - ");
        console.log("----------------------------------------------------");
        console.log(`aToken: ${tokenData[i].reserves.aToken.tokenAddress}`);
        console.log(`aToken symbol: ${tokenData[i].reserves.aToken.symbol}`);
        console.log(`aToken decimals: ${tokenData[i].reserves.aToken.decimals}`);

        for (let j = 0; j < rewards[i].aIncentiveData.rewardsTokenInfo.length; j++) {
          console.log(`Reward token address: ${rewards[i].aIncentiveData.rewardsTokenInfo[j].rewardTokenAddress}`);
          console.log(`Reward token symbol: ${rewards[i].aIncentiveData.rewardsTokenInfo[j].rewardTokenSymbol}`);
          console.log(`Reward token decimals: ${rewards[i].aIncentiveData.rewardsTokenInfo[j].rewardTokenDecimals}`);
          console.log(`Reward token precision: ${rewards[i].aIncentiveData.rewardsTokenInfo[j].precision}`);
          console.log(`Emission rate per second: ${rewards[i].aIncentiveData.rewardsTokenInfo[j].emissionPerSecond}`);
        }
        for (let j = 0; j < rewards[i].aIncentiveData.userRewards.rewardsToken.length; j++) {
          console.log(
            `Unclaimed Reward: ${rewards[i].aIncentiveData.userRewards.unbalancedAmounts[j]} for ${rewards[i].aIncentiveData.userRewards.rewardsToken[j]}`,
          );
        }
        console.log("----------------------------------------------------");
        console.log("sToken Rewards Details - ");
        console.log("----------------------------------------------------");
        console.log(`Stable Debt Token: ${tokenData[i].reserves.stableDebtToken.tokenAddress}`);
        console.log(`Stable Debt symbol: ${tokenData[i].reserves.stableDebtToken.symbol}`);
        console.log(`Stable Debt decimals: ${tokenData[i].reserves.stableDebtToken.decimals}`);
        for (let j = 0; j < rewards[i].sIncentiveData.rewardsTokenInfo.length; j++) {
          console.log(`Reward token address: ${rewards[i].sIncentiveData.rewardsTokenInfo[j].rewardTokenAddress}`);
          console.log(`Reward token symbol: ${rewards[i].sIncentiveData.rewardsTokenInfo[j].rewardTokenSymbol}`);
          console.log(`Reward token decimals: ${rewards[i].sIncentiveData.rewardsTokenInfo[j].rewardTokenDecimals}`);
          console.log(`Reward token precision: ${rewards[i].sIncentiveData.rewardsTokenInfo[j].precision}`);
          console.log(`Emission rate per second: ${rewards[i].sIncentiveData.rewardsTokenInfo[j].emissionPerSecond}`);
        }
        for (let j = 0; j < rewards[i].sIncentiveData.userRewards.rewardsToken.length; j++) {
          console.log(
            `Unclaimed Reward: ${rewards[i].sIncentiveData.userRewards.unbalancedAmounts[j]} for ${rewards[i].sIncentiveData.userRewards.rewardsToken[j]}`,
          );
        }
        console.log("----------------------------------------------------");
        console.log("vToken Rewards Details - ");
        console.log("----------------------------------------------------");
        console.log(`Variable Debt Token: ${tokenData[i].reserves.variableDebtToken.tokenAddress}`);
        console.log(`Variable Debt symbol: ${tokenData[i].reserves.variableDebtToken.symbol}`);
        console.log(`Variable Debt decimals: ${tokenData[i].reserves.variableDebtToken.decimals}`);
        for (let j = 0; j < rewards[i].vIncentiveData.rewardsTokenInfo.length; j++) {
          console.log(`Reward token address: ${rewards[i].vIncentiveData.rewardsTokenInfo[j].rewardTokenAddress}`);
          console.log(`Reward token symbol: ${rewards[i].vIncentiveData.rewardsTokenInfo[j].rewardTokenSymbol}`);
          console.log(`Reward token decimals: ${rewards[i].vIncentiveData.rewardsTokenInfo[j].rewardTokenDecimals}`);
          console.log(`Reward token precision: ${rewards[i].vIncentiveData.rewardsTokenInfo[j].precision}`);
          console.log(`Emission rate per second: ${rewards[i].vIncentiveData.rewardsTokenInfo[j].emissionPerSecond}`);
        }
        for (let j = 0; j < rewards[i].vIncentiveData.userRewards.rewardsToken.length; j++) {
          console.log(
            `Unclaimed Reward: ${rewards[i].vIncentiveData.userRewards.unbalancedAmounts[j]} for ${rewards[i].vIncentiveData.userRewards.rewardsToken[j]}`,
          );
        }
        console.log();

        // console.log(`E-Mode category: ${tokenData[i].token.eModeCategory}`);
        console.log(
          "Debt ceiling: ",
          formatUnits(tokenData[i].token.debtCeiling, tokenData[i].token.debtCeilingDecimals),
        );
        console.log(`Liquidation Fee: ${tokenData[i].token.liquidationFee}`);
      }

      expect(userTokenData[0].supplyBalance).to.gte(0);
      expect(userTokenData[0].variableBorrowBalance).to.gte(0);
    });

    it("Returns the e-mode category details of e-modeID", async () => {
      const emodeData = await resolver.getEmodeCategoryData(1, POOL_ADDRESS_PROVIDER_ARBITRUM);
      console.log();
      console.log("*************************************************");
      console.log("E-Mode category Data");
      console.log("*************************************************");
      console.log(`e-mode LTV: ${emodeData.data.ltv}`);
      console.log(`e-mode liquidation threshold: ${emodeData.data.liquidationThreshold}`);
      console.log(`e-mode liquidation bonus: ${emodeData.data.liquidationBonus}`);
      console.log(`e-mode label: ${emodeData.data.label}`);
      console.log(`e-mode is colleteral bitmap: ${emodeData.data.isCollateralBitmap}`);
      console.log(`e-mode is borrowable bitmap: ${emodeData.data.isBorrowableBitmap}`);
    });

    it("Returns the ethPrice", async () => {
      const ethPrice = await resolver.getEthPrice();
      console.log(`ethPrice: ${ethPrice}`);
    });
  });
});
