import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { InstaNotionalResolver, InstaNotionalResolver__factory } from "../../typechain";
import hre from "hardhat";
import { expect } from "chai";
import { parseEther, parseUnits } from "ethers/lib/utils";

describe("Notional Resolvers", () => {
  let signer: SignerWithAddress;
  const testAccount = "0x8665d75ff2db29355428b590856505459bb675e3";

  before(async () => {
    [signer] = await ethers.getSigners();
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            //@ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 14656322,
          },
        },
      ],
    });
  });

  describe("Notional Resolver", () => {
    let resolver: InstaNotionalResolver;
    before(async () => {
      const deployer = new InstaNotionalResolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("test_getAccount", async () => {
      const [accountContext, accountBalances, portfolio] = await resolver.getAccount(testAccount);
      expect(accountContext.hasDebt).to.equal("0x01");
      expect(accountBalances.length).to.equal(10);
      expect(portfolio.length).to.equal(5);
    });

    it("test_getFreeCollateral", async () => {
      const [netETHValue, netLocalAssetValues] = await resolver.getFreeCollateral(testAccount);
      expect(netETHValue).to.gte(ethers.utils.parseUnits("128482200000", 0));
      expect(netLocalAssetValues.length).to.equal(10);
    });

    it("test_getCurrencyAndRates", async () => {
      const [assetToken, underlyingToken, ethRate, assetRate] = await resolver.getCurrencyAndRates(3);
      expect(assetToken.tokenAddress, "cUSDC address").to.equal("0x39AA39c021dfbaE8faC545936693aC917d5E7563");
      expect(underlyingToken.tokenAddress, "USDC address").to.equal("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");
      expect(ethRate.rate);
      expect(assetRate.rate);
    });

    it("test_getActiveMarkets", async () => {
      const markets = await resolver.getActiveMarkets(1);
      expect(markets.length).to.equal(2);
    });

    it("test_getSettlementRate", async () => {
      const markets = await resolver.getActiveMarkets(3);
      const resp = await resolver.getSettlementRate(3, markets[0].maturity);
      expect(resp.rateOracle).to.equal("0x0000000000000000000000000000000000000000");
      expect(resp.rate).to.gte(ethers.utils.parseUnits("225857561000000", 0));
      expect(resp.underlyingDecimals).to.equal(ethers.utils.parseUnits("1000000", 0));
    });

    it("test_nTokenGetClaimableIncentives", async () => {
      const incentives = await resolver.nTokenGetClaimableIncentives(testAccount, 1649909533);
      expect(incentives).to.gte(ethers.utils.parseUnits("51600000000", 0));
    });

    it("test_calculateNTokensToMint", async () => {
      const amount = await resolver.calculateNTokensToMint(1, parseEther("2"));
      expect(amount).to.gte(ethers.utils.parseUnits("1999170000000000000", 0));
    });

    it("test_getBorrowfCashAmount", async () => {
      const markets = await resolver.getActiveMarkets(3);
      const amount = await resolver.getBorrowfCashAmount(
        3,
        parseUnits("1000", 6),
        1,
        1650925608,
        markets[0].maturity,
        parseUnits("5", 6),
      );
      expect(amount).to.lte(ethers.utils.parseUnits("-45007970000", 0));
    });

    it("test_getLendingfCashAmount", async () => {
      const markets = await resolver.getActiveMarkets(3);
      const amount = await resolver.getLendfCashAmount(
        3,
        parseUnits("1000", 6),
        1,
        1650925608,
        markets[0].maturity,
        parseUnits("5", 6),
      );
      expect(amount).to.gte(ethers.utils.parseUnits("44659570000", 0));
    });
  });
});
