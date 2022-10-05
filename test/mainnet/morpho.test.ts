import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { InstaMorphoResolver, InstaMorphoResolver__factory } from "../../typechain";

describe("Morpho Resolvers", () => {
  let signer: SignerWithAddress;
  const user = "0x49e96e255ba418d08e66c35b588e2f2f3766e1d0";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Morpho Resolver", () => {
    let resolver: InstaMorphoResolver;
    before(async () => {
      const deployer = new InstaMorphoResolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("Returns the morpho's configurations", async () => {
      const morphoConfig = await resolver.getMorphoConfig();
      console.log("\t*******************AAVE MARKETS******************\n");
      console.log(`Claim Rewards paused: ${morphoConfig.isClaimRewardsPausedAave}`);
      for (const aaveMarket of morphoConfig.aaveMarketsCreated) {
        console.log(`aToken: ${aaveMarket.config.poolTokenAddress}`);
        console.log(`underlying token: ${aaveMarket.config.underlyingToken}`);
        console.log(`decimals: ${aaveMarket.config.decimals}`);
        console.log(`supply rate experienced on average by user in market: ${aaveMarket.avgSupplyRate}`);
        console.log(`borrow rate experienced on average by user in market: ${aaveMarket.avgBorrowRate}`);
        console.log(`p2p borrow rate: ${aaveMarket.p2pBorrowRate}`);
        console.log(`p2p supply rate: ${aaveMarket.p2pSupplyRate}`);
        console.log(`pool borrow rate: ${aaveMarket.poolSupplyRate}`);
        console.log(`pool supply rate: ${aaveMarket.poolBorrowRate}`);
        console.log(`total p2p supply: ${aaveMarket.totalP2PSupply}`);
        console.log(`total p2p borrow: ${aaveMarket.totalP2PBorrows}`);
        console.log(`total pool supply: ${aaveMarket.totalPoolSupply}`);
        console.log(`total pool borrow: ${aaveMarket.totalPoolBorrows}`);
        console.log(`pool supply index: ${aaveMarket.poolSupplyIndex}`);
        console.log(`pool borrow index: ${aaveMarket.poolBorrowIndex}`);
        console.log(`p2p supply delta: ${aaveMarket.p2pSupplyDelta}`);
        console.log(`p2p borrow delta: ${aaveMarket.p2pBorrowDelta}`);
        console.log(`reserve Factor: ${aaveMarket.reserveFactor}`);
        console.log(`ltv: ${aaveMarket.aaveData.ltv}`);
        console.log(`liquidation threshold: ${aaveMarket.aaveData.liquidationThreshold}`);
        console.log(`liquidation bonus: ${aaveMarket.aaveData.liquidationBonus}`);
        console.log(`aToken emission per second: ${aaveMarket.aaveData.aEmissionPerSecond}`);
        console.log(`vToken emission per second: ${aaveMarket.aaveData.vEmissionPerSecond}`);
        console.log(`available liquidity: ${aaveMarket.aaveData.availableLiquidity}`);
        console.log(`liquidity rate: ${aaveMarket.aaveData.liquidityRate}`);
        console.log(`isPaused: ${aaveMarket.flags.isPaused}`);
        console.log(`isPartiallyPaused: ${aaveMarket.flags.isPartiallyPaused}`);
        console.log(`isP2PDisabled: ${aaveMarket.flags.isP2PDisabled}\n`);
      }

      console.log("\n\t*******************COMP MARKETS******************\n");
      console.log(`Claim Rewards paused: ${morphoConfig.isClaimRewardsPausedComp}`);
      for (const compMarket of morphoConfig.compMarketsCreated) {
        console.log(`cToken: ${compMarket.config.poolTokenAddress}`);
        console.log(`underlying token: ${compMarket.config.underlyingToken}`);
        console.log(`decimals: ${compMarket.config.decimals}`);
        console.log(`supply rate experienced on average by user in market: ${compMarket.avgSupplyRate}`);
        console.log(`borrow rate experienced on average by user in market: ${compMarket.avgBorrowRate}`);
        console.log(`p2p borrow rate: ${compMarket.p2pBorrowRate}`);
        console.log(`p2p supply rate: ${compMarket.p2pSupplyRate}`);
        console.log(`pool borrow rate: ${compMarket.poolSupplyRate}`);
        console.log(`pool supply rate: ${compMarket.poolBorrowRate}`);
        console.log(`total p2p supply: ${compMarket.totalP2PSupply}`);
        console.log(`total p2p borrow: ${compMarket.totalP2PBorrows}`);
        console.log(`total pool supply: ${compMarket.totalPoolSupply}`);
        console.log(`total pool borrow: ${compMarket.totalPoolBorrows}`);
        console.log(`pool supply index: ${compMarket.poolSupplyIndex}`);
        console.log(`pool borrow index: ${compMarket.poolBorrowIndex}`);
        console.log(`p2p supply delta: ${compMarket.p2pSupplyDelta}`);
        console.log(`p2p borrow delta: ${compMarket.p2pBorrowDelta}`);
        console.log(`reserve Factor: ${compMarket.reserveFactor}`);
        console.log(`collateral: ${compMarket.compData.collateralFactor}`);
        console.log(`comp speed: ${compMarket.compData.compSpeed}`);
        console.log(`comp supply speed: ${compMarket.compData.compSupplySpeed}`);
        console.log(`comp borrow speed: ${compMarket.compData.compBorrowSpeed}`);
        console.log(`isPaused: ${compMarket.flags.isPaused}`);
        console.log(`isPartiallyPaused: ${compMarket.flags.isPartiallyPaused}`);
        console.log(`isP2PDisabled: ${compMarket.flags.isP2PDisabled}\n`);
      }
    });

    it("Returns the user's position details for all entered markets", async () => {
      console.log("\n\t****************COMP USER POSITION DATA**************\n");
      let userData = await resolver.callStatic.getPositionAll(1, user);
      console.log(`**User Position Data:**`);
      console.log(`health factor: ${userData.healthFactor}`);
      console.log(`collateral value: ${userData.collateralValue}`);
      console.log(`Debt Value: ${userData.debtValue}`);
      console.log(`Max Debt Value user can have: ${userData.maxDebtValue}`);
      console.log(`is liquidatable: ${userData.isLiquidatable}`);
      console.log(`unclaimed rewards: ${userData.unclaimedRewards}`);
      console.log(`\n\t**Entered markets data**`);

      for (const market of userData.marketData) {
        console.log(`cToken: ${market.marketData.config.poolTokenAddress}`);
        console.log(`underlying token: ${market.marketData.config.underlyingToken}`);
        console.log(`decimals: ${market.marketData.config.decimals}`);
        console.log(`borrow rate: ${market.borrowRate}`);
        console.log(`supply rate: ${market.supplyRate}`);
        console.log(`total supplies: ${market.totalSupplies}`);
        console.log(`total borrows: ${market.totalBorrows}`);
        console.log(`p2p supplies: ${market.p2pSupplies}`);
        console.log(`p2p borrows: ${market.p2pBorrows}`);
        console.log(`pool supplies: ${market.poolSupplies}`);
        console.log(`pool borrows: ${market.poolBorrows}`);
        console.log(`max withdrawble: ${market.maxWithdrawable}`);
        console.log(`max borrowable: ${market.maxBorrowable}`);
        console.log(`supply rate experienced on average by user in market: ${market.marketData.avgSupplyRate}`);
        console.log(`borrow rate experienced on average by user in market: ${market.marketData.avgBorrowRate}`);
        console.log(`p2p borrow rate: ${market.marketData.p2pBorrowRate}`);
        console.log(`p2p supply rate: ${market.marketData.p2pSupplyRate}`);
        console.log(`pool borrow rate: ${market.marketData.poolSupplyRate}`);
        console.log(`pool supply rate: ${market.marketData.poolBorrowRate}`);
        console.log(`total p2p supply: ${market.marketData.totalP2PSupply}`);
        console.log(`total p2p borrow: ${market.marketData.totalP2PBorrows}`);
        console.log(`total pool supply: ${market.marketData.totalPoolSupply}`);
        console.log(`total pool borrow: ${market.marketData.totalPoolBorrows}`);
        console.log(`pool supply index: ${market.marketData.poolSupplyIndex}`);
        console.log(`pool borrow index: ${market.marketData.poolBorrowIndex}`);
        console.log(`p2p supply delta: ${market.marketData.p2pSupplyDelta}`);
        console.log(`p2p borrow delta: ${market.marketData.p2pBorrowDelta}`);
        console.log(`reserve Factor: ${market.marketData.reserveFactor}`);
        console.log(`collateral factor: ${market.marketData.compData.collateralFactor}`);
        console.log(`comp speed: ${market.marketData.compData.compSpeed}`);
        console.log(`comp supply speed: ${market.marketData.compData.compSupplySpeed}`);
        console.log(`comp borrow speed: ${market.marketData.compData.compBorrowSpeed}`);
        console.log(`isPaused: ${market.marketData.flags.isPaused}`);
        console.log(`isPartiallyPaused: ${market.marketData.flags.isPartiallyPaused}`);
        console.log(`isP2PDisabled: ${market.marketData.flags.isP2PDisabled}\n`);
      }

      console.log("\n\t****************AAVE USER POSITION DATA**************\n");
      userData = await resolver.callStatic.getPositionAll(0, user);
      console.log(`**User Position Data:**`);
      console.log(`health factor: ${userData.healthFactor}`);
      console.log(`collateral value: ${userData.collateralValue}`);
      console.log(`Debt Value: ${userData.debtValue}`);
      console.log(`Max Debt Value user can have: ${userData.maxDebtValue}`);
      console.log(`is liquidatable: ${userData.isLiquidatable}`);
      console.log(`liquidation threshold: ${userData.liquidationThreshold}`);
      console.log(`unclaimed rewards: ${userData.unclaimedRewards}`);
      console.log(`\n\t**Entered markets data**`);

      for (const market of userData.marketData) {
        console.log(`aToken: ${market.marketData.config.poolTokenAddress}`);
        console.log(`underlying token: ${market.marketData.config.underlyingToken}`);
        console.log(`decimals: ${market.marketData.config.decimals}`);
        console.log(`borrow rate: ${market.borrowRate}`);
        console.log(`supply rate: ${market.supplyRate}`);
        console.log(`total supplies: ${market.totalSupplies}`);
        console.log(`total borrows: ${market.totalBorrows}`);
        console.log(`p2p supplies: ${market.p2pSupplies}`);
        console.log(`p2p borrows: ${market.p2pBorrows}`);
        console.log(`pool supplies: ${market.poolSupplies}`);
        console.log(`pool borrows: ${market.poolBorrows}`);
        console.log(`max withdrawble: ${market.maxWithdrawable}`);
        console.log(`max borrowable: ${market.maxBorrowable}`);
        console.log(`supply rate experienced on average by user in market: ${market.marketData.avgSupplyRate}`);
        console.log(`borrow rate experienced on average by user in market: ${market.marketData.avgBorrowRate}`);
        console.log(`p2p borrow rate: ${market.marketData.p2pBorrowRate}`);
        console.log(`p2p supply rate: ${market.marketData.p2pSupplyRate}`);
        console.log(`pool borrow rate: ${market.marketData.poolSupplyRate}`);
        console.log(`pool supply rate: ${market.marketData.poolBorrowRate}`);
        console.log(`total p2p supply: ${market.marketData.totalP2PSupply}`);
        console.log(`total p2p borrow: ${market.marketData.totalP2PBorrows}`);
        console.log(`total pool supply: ${market.marketData.totalPoolSupply}`);
        console.log(`total pool borrow: ${market.marketData.totalPoolBorrows}`);
        console.log(`pool supply index: ${market.marketData.poolSupplyIndex}`);
        console.log(`pool borrow index: ${market.marketData.poolBorrowIndex}`);
        console.log(`p2p supply delta: ${market.marketData.p2pSupplyDelta}`);
        console.log(`p2p borrow delta: ${market.marketData.p2pBorrowDelta}`);
        console.log(`reserve Factor: ${market.marketData.reserveFactor}`);
        console.log(`ltv: ${market.marketData.aaveData.ltv}`);
        console.log(`liquidation threshold: ${market.marketData.aaveData.liquidationThreshold}`);
        console.log(`liquidation bonus: ${market.marketData.aaveData.liquidationBonus}`);
        console.log(`aToken emission per second: ${market.marketData.aaveData.aEmissionPerSecond}`);
        console.log(`vToken emission per second: ${market.marketData.aaveData.vEmissionPerSecond}`);
        console.log(`available liquidity: ${market.marketData.aaveData.availableLiquidity}`);
        console.log(`liquidity rate: ${market.marketData.aaveData.liquidityRate}`);
        console.log(`isPaused: ${market.marketData.flags.isPaused}`);
        console.log(`isPartiallyPaused: ${market.marketData.flags.isPartiallyPaused}`);
        console.log(`isP2PDisabled: ${market.marketData.flags.isP2PDisabled}\n`);
      }
    });
  });
});
