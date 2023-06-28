import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { InstaAaveV3MorphoResolver, InstaAaveV3MorphoResolver__factory } from "../../typechain";
import hre from "hardhat";

describe("Morpho Resolvers", () => {
  let signer: SignerWithAddress;
  const user = "0x49e96e255ba418d08e66c35b588e2f2f3766e1d0";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Morpho Resolver", () => {
    let aaveResolver: InstaAaveV3MorphoResolver;
    before(async () => {
      await hre.network.provider.request({
        method: "hardhat_reset",
        params: [
          {
            forking: {
              // eslint-disable-next-line @typescript-eslint/ban-ts-comment
              // @ts-ignore
              jsonRpcUrl: hre.config.networks.hardhat.forking.url,
              blockNumber: 17544460,
            },
          },
        ],
      });

      const deployer = new InstaAaveV3MorphoResolver__factory(signer);
      aaveResolver = await deployer.deploy();
      await aaveResolver.deployed();

      console.log("Morpho Resolver deployed at: ", aaveResolver.address);
    });

    it("Returns the morpho's configurations", async () => {
      const morphoConfig = await aaveResolver.getMorphoConfig();
      console.log("\t*******************AAVE MARKETS******************\n");
      console.log(`Claim Rewards paused: ${morphoConfig.isClaimRewardsPausedAave}`);
      console.log(`p2p supply amount: ${morphoConfig.p2pSupplyAmount}`);
      console.log(`p2p borrow amount: ${morphoConfig.p2pBorrowAmount}`);
      console.log(`pool supply amount: ${morphoConfig.poolSupplyAmount}`);
      console.log(`pool borrow amount: ${morphoConfig.poolBorrowAmount}`);
      console.log(`total supply amount: ${morphoConfig.totalSupplyAmount}`);
      console.log(`total borrow amount: ${morphoConfig.totalBorrowAmount}`);
      for (const aaveMarket of morphoConfig.aaveMarketsCreated) {
        console.log(`aToken: ${aaveMarket.config.aTokenAddress}`);
        // console.log(`underlying token: ${aaveMarket.config.underlyingToken}`);
        console.log(`decimals: ${aaveMarket.config.decimals}`);
        console.log(`eth price: ${aaveMarket.config.tokenPriceInEth}`);
        console.log(`usd price: ${aaveMarket.config.tokenPriceInUsd}`);
        console.log(`supply rate experienced on average by user in market: ${aaveMarket.avgSupplyRatePerYear}`);
        console.log(`borrow rate experienced on average by user in market: ${aaveMarket.avgBorrowRatePerYear}`);
        console.log(`p2p borrow rate: ${aaveMarket.p2pBorrowRate}`);
        console.log(`p2p supply rate: ${aaveMarket.p2pSupplyRate}`);
        console.log(`pool supply rate: ${aaveMarket.poolSupplyRate}`);
        console.log(`pool borrow rate: ${aaveMarket.poolBorrowRate}`);
        console.log(`total p2p supply: ${aaveMarket.totalP2PSupply}`);
        console.log(`total p2p borrow: ${aaveMarket.totalP2PBorrows}`);
        console.log(`total pool supply: ${aaveMarket.totalPoolSupply}`);
        console.log(`total pool borrow: ${aaveMarket.totalPoolBorrows}`);
        // console.log(`pool supply index: ${aaveMarket.poolSupplyIndex}`);
        // console.log(`pool borrow index: ${aaveMarket.poolBorrowIndex}`);
        console.log(`last updated timestamp: ${aaveMarket.lastUpdateTimestamp}`);
        // console.log(`p2p index cursor: ${aaveMarket.p2pIndexCursor}`);
        // console.log(`p2p delta: ${aaveMarket.p2pDelta}`);
        // console.log(`p2p total: ${aaveMarket.p2pTotal}`);
        console.log(`reserve Factor: ${aaveMarket.reserveFactor}`);
        console.log(`ltv: ${aaveMarket.aaveData.ltv}`);
        console.log(`liquidation threshold: ${aaveMarket.aaveData.liquidationThreshold}`);
        // console.log(`liquidation bonus: ${aaveMarket.aaveData.liquidationBonus}`);
        // console.log(`aToken emission per second: ${aaveMarket.aaveData.aEmissionPerSecond}`);
        // console.log(`sToken emission per second: ${aaveMarket.aaveData.sEmissionPerSecond}`);
        // console.log(`vToken emission per second: ${aaveMarket.aaveData.vEmissionPerSecond}`);
        // console.log(`available liquidity: ${aaveMarket.aaveData.availableLiquidity}`);
        console.log(`total supplies in underlying: ${aaveMarket.aaveData.totalSupplies}`);
        console.log(`total stables borrows in underlying: ${aaveMarket.aaveData.totalStableBorrows}`);
        console.log(`total variable borrows in underlying: ${aaveMarket.aaveData.totalVariableBorrows}`);
        console.log(`liquidity rate: ${aaveMarket.aaveData.liquidityRate}`);
        console.log(`isSupplyPaused: ${aaveMarket.flags.isSupplyPaused}`);
        console.log(`isSupplyCollateralPaused: ${aaveMarket.flags.isSupplyCollateralPaused}`);
        console.log(`isCreated: ${aaveMarket.flags.isCreated}`);
        console.log(`isBorrowPaused: ${aaveMarket.flags.isBorrowPaused}`);
        console.log(`isRepayPaused: ${aaveMarket.flags.isRepayPaused}`);
        console.log(`isWithdrawPaused: ${aaveMarket.flags.isWithdrawPaused}`);
        console.log(`isWithdrawCollateralPaused: ${aaveMarket.flags.isWithdrawCollateralPaused}`);
        console.log(`isLiquidateCollateralPaused: ${aaveMarket.flags.isLiquidateCollateralPaused}`);
        console.log(`isLiquidateBorrowPaused: ${aaveMarket.flags.isLiquidateBorrowPaused}`);
        console.log(`isDeprecated: ${aaveMarket.flags.isDeprecated}`);
        console.log(`isP2PDisabled: ${aaveMarket.flags.isP2PDisabled}\n`);
        console.log(`isBorrowEnabled: ${aaveMarket.flags.isUnderlyingBorrowEnabled}\n`);
      }
    });

    it("Returns the user's position details for all entered markets", async () => {
      console.log("\n\t****************AAVE USER POSITION DATA**************\n");
      const userData = await aaveResolver.callStatic.getPositionAll(user);
      console.log(`**User Position Data:**`);
      console.log(`health factor: ${userData.healthFactor}`);
      console.log(`eth price: ${userData.ethPriceInUsd}`);
      console.log(`collateral value: ${userData.collateralValue}`);
      console.log(`Debt Value: ${userData.debtValue}`);
      console.log(`Max Debt Value user can have: ${userData.maxDebtValue}`);
      console.log(`Max Borrow Value user can have: ${userData.maxBorrowable}`);
      // console.log(`is liquidatable: ${userData.isLiquidatable}`);
      console.log(`liquidation threshold: ${userData.liquidationThreshold}`);
      // console.log(`unclaimed rewards: ${userData.unclaimedRewards}`);
      console.log(`\n\t**Entered markets data**`);

      for (const market of userData.marketData) {
        console.log(`aToken: ${market.marketData.config.aTokenAddress}`);
        // console.log(`underlying token: ${market.marketData.config.underlyingToken}`);
        console.log(`decimals: ${market.marketData.config.decimals}`);
        console.log(`price in eth: ${market.marketData.config.tokenPriceInEth}`);
        console.log(`price in usd: ${market.marketData.config.tokenPriceInUsd}`);
        console.log(`borrow rate: ${market.borrowRatePerYear}`);
        console.log(`supply rate: ${market.supplyRatePerYear}`);
        console.log(`total supplies: ${market.totalSupplies}`);
        console.log(`total borrows: ${market.totalBorrows}`);
        console.log(`p2p supplies: ${market.p2pSupplies}`);
        console.log(`p2p borrows: ${market.p2pBorrows}`);
        console.log(`pool supplies: ${market.poolSupplies}`);
        console.log(`pool borrows: ${market.poolBorrows}`);
        // console.log(`max withdrawble: ${market.maxWithdrawable}`);
        console.log(`supply rate experienced on average by user in market: ${market.marketData.avgSupplyRatePerYear}`);
        console.log(`borrow rate experienced on average by user in market: ${market.marketData.avgBorrowRatePerYear}`);
        console.log(`p2p borrow rate: ${market.marketData.p2pBorrowRate}`);
        console.log(`p2p supply rate: ${market.marketData.p2pSupplyRate}`);
        console.log(`pool borrow rate: ${market.marketData.poolSupplyRate}`);
        console.log(`pool supply rate: ${market.marketData.poolBorrowRate}`);
        console.log(`total p2p supply: ${market.marketData.totalP2PSupply}`);
        console.log(`total p2p borrow: ${market.marketData.totalP2PBorrows}`);
        console.log(`total pool supply: ${market.marketData.totalPoolSupply}`);
        console.log(`total pool borrow: ${market.marketData.totalPoolBorrows}`);
        // console.log(`p2p supply delta: ${market.marketData.p2pDelta}`);
        // console.log(`p2p borrow delta: ${market.marketData.p2pBorrowDelta}`);
        console.log(`reserve Factor: ${market.marketData.reserveFactor}`);
        console.log(`ltv: ${market.marketData.aaveData.ltv}`);
        console.log(`liquidation threshold: ${market.marketData.aaveData.liquidationThreshold}`);
        // console.log(`liquidation bonus: ${market.marketData.aaveData.liquidationBonus}`);
        // console.log(`aToken emission per second: ${market.marketData.aaveData.aEmissionPerSecond}`);
        // console.log(`vToken emission per second: ${market.marketData.aaveData.vEmissionPerSecond}`);
        // console.log(`available liquidity: ${market.marketData.aaveData.availableLiquidity}`);
        console.log(`liquidity rate: ${market.marketData.aaveData.liquidityRate}`);
        // console.log(`isPaused: ${market.marketData.flags.isPaused}`);
        // console.log(`isPartiallyPaused: ${market.marketData.flags.isPartiallyPaused}`);
        console.log(`isP2PDisabled: ${market.marketData.flags.isP2PDisabled}\n`);
        console.log(`isBorrowEnabled: ${market.marketData.flags.isUnderlyingBorrowEnabled}\n`);
      }
    });
  });
});
