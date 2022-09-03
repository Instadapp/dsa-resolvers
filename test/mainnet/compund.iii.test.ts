import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
// import { expect } from "chai";
// import { formatEther, formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaCompoundIIIResolver, InstaCompoundIIIResolver__factory } from "../../typechain";
// import { Tokens } from "../consts";

describe("Compound Resolvers", () => {
  let signer: SignerWithAddress;
  const user = "0x0a904e5e342d853952ad8159502dc1a29f9b084e";
  const markets = ["0xc3d688B66703497DAA19211EEdff47f25384cdc3"];

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Compound Resolver", () => {
    let resolver: InstaCompoundIIIResolver;
    before(async () => {
      const deployer = new InstaCompoundIIIResolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("Returns the market's configurations", async () => {
      const marketConfig = await resolver.getMarketConfiguration(markets);
      for (const market of marketConfig) {
        console.log(`Number of supported assets: ${market.assetCount}`);
        console.log(`Market base asset utilization: ${market.utilization}`);
        console.log(`Market supply rate: ${market.supplyRateInPercentWei}`);
        console.log(`Market borrow rate: ${market.borrowRateInPercentWei}`);
        console.log(`Supply index tracking speed: ${market.baseTrackingSupplySpeed}`);
        console.log(`Borrow index tracking speed: ${market.baseTrackingBorrowSpeed}`);
        console.log(`Market reserves: ${market.reservesInBase}`);
        console.log(
          `Fraction of the liquidation penalty that goes to buyers of collateral: ${market.storeFrontPriceFactor}`,
        );
        console.log(`Minimum borrow amount: ${market.baseBorrowMinInBase}`);
        console.log(
          `Max base asset balance of market until which collateral can be sold: ${market.targetReservesInBase}`,
        );
        console.log(`TotalSupply in base: ${market.totalSupplyInBase}`);
        console.log(`TotalBorrow in base: ${market.totalBorrowInBase}`);

        console.log(`**Base asset info:** \n`);
        console.log(`Base token: ${market.baseToken.token}`);
        console.log(`Base token priceFeed: ${market.baseToken.priceFeed}`);
        console.log(`Base token price: ${market.baseToken.price}`);
        console.log(`Base token decimals: ${market.baseToken.decimals}`);
        console.log(`Base token scale: ${market.baseToken.mantissa}`);
        console.log(`Base token index's scale: ${market.baseToken.indexScale}`);
        console.log(`Base token supply tracking index: ${market.baseToken.trackingSupplyIndex}`);
        console.log(`Base token borrow tracking index: ${market.baseToken.trackingBorrowIndex}`);

        console.log(`**Scales used throughout the market:** \n`);
        console.log(`Factor scale: ${market.scales.factorScale}`);
        console.log(`Price scale: ${market.scales.priceScale}`);
        console.log(`Tracking Indices scale: ${market.scales.trackingIndexScale}`);

        console.log(`**Rewards asset configuration:** \n`);
        console.log(`Reward token: ${market.rewardConfig[0].token}`);
        console.log(`Reward token rescale factor: ${market.rewardConfig[0].rescaleFactor}`);
        console.log(
          `Min base balance of the market for rewards to be accrued: ${market.rewardConfig[0].baseMinForRewardsInBase}`,
        );

        console.log(`**Supported assets configuration:** \n`);
        const assets = market.assets;

        for (const asset of assets) {
          console.log(`Asset address: ${asset.token.token}`);
          console.log(`Asset Offset: ${asset.token.offset}`);
          console.log(`Asset decimals: ${asset.token.decimals}`);
          console.log(`Asset symbol: ${asset.token.symbol}`);
          console.log(`Asset scale: ${asset.token.scale}`);
          console.log(`Asset priceFeed: ${asset.priceFeed}`);
          console.log(`Asset price: ${asset.price}`);
          console.log(`Asset borrow collateral factor: ${asset.borrowCollateralFactor}`);
          console.log(`Asset liquidate collateral factor: ${asset.liquidateCollateralFactor}`);
          console.log(`Asset liquidation factor: ${asset.liquidationFactor}`);
          console.log(`Asset supply cap: ${asset.supplyCapInWei}`);
          console.log(`Asset totalCollateral: ${asset.totalCollateralInWei}`);
        }
      }
    });

    it("Returns the user's position details", async () => {
      const userPositions = await resolver.callStatic.getPositionForMarkets(user, markets);

      for (const position of userPositions.positionData) {
        const userData = position.userData;
        const collateralData = position.collateralData;

        console.log(`**User Position Data:**`);
        console.log(`Supplied balance: ${userData.principalInBase}`);
        console.log(`Supplied balance: ${userData.suppliedBalanceInBase}`);
        console.log(`Borrowed balance: ${userData.borrowedBalanceInBase}`);
        console.log(`Collateral assets: ${userData.assetsIn}`);
        console.log(`Account tracking index: ${userData.accountTrackingIndex}`);
        console.log(`Interest accrued: ${userData.interestAccruedInBase}`);
        console.log(`Use Nonce: ${userData.userNonce}`);
        console.log(`Borrowable Amount: ${await resolver.callStatic.getBorrowableAmount(user, markets[0])}`);
        console.log(`Health factor: ${await resolver.callStatic.getHealthFactor(user, markets[0])}`);
        console.log(`Position is liquidatable: ${userData.flags.isLiquidatable}`);
        console.log(`Position can borrow: ${userData.flags.isBorrowCollateralized}`);

        console.log(`**Rewards data:**`);
        console.log(`Reward token: ${userData.rewards[0].rewardToken}`);
        console.log(`Reward token decimals: ${userData.rewards[0].rewardTokenDecimals}`);
        console.log(`Reward owed: ${userData.rewards[0].amountOwedInWei}`);
        console.log(`Reward claimed: ${userData.rewards[0].amountClaimedInWei}`);

        for (const collateral of collateralData) {
          console.log(`**User Collateral Data:**`);
          console.log(`Collateral token: ${collateral.token}`);
          console.log(`SuppliedBalance in base: ${collateral.suppliedBalanceInBase}`);
          console.log(`SuppliedBalance in asset: ${collateral.suppliedBalanceInAsset}`);
        }
      }
    });

    it("Returns user's collateral details", async () => {
      const collaterals = await resolver.callStatic.getUsedCollateralsList(user, markets);
      for (const collateral of collaterals) {
        for (const asset of collateral) {
          console.log(asset);
        }
      }
    });
  });
});
