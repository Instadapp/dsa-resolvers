import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { InstaNotionalResolver, InstaNotionalResolver__factory } from "../../typechain";
import hre from "hardhat";
import { expect } from "chai";
import { parseEther, parseUnits } from "ethers/lib/utils";

describe("Notional Resolvers", () => {
  let signer: SignerWithAddress;
  const testAccount = "0x8665d75ff2db29355428b590856505459bb675e3";
  let resolver: InstaNotionalResolver;

  beforeEach(async () => {
    [signer] = await ethers.getSigners();
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            //@ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 15083800,
          },
        },
      ],
    });

    const deployer = new InstaNotionalResolver__factory(signer);
    resolver = await deployer.deploy();
    await resolver.deployed();
  });

  describe("Notional Resolver", () => {
    it("test_getAccount", async () => {
      const [accountContext, accountBalances, portfolio] = await resolver.getAccount(testAccount);
      expect(accountContext.hasDebt).to.equal("0x01");
      expect(accountBalances.length).to.equal(10);
      expect(portfolio.length).to.equal(3);
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
      expect(amount).to.gte(ethers.utils.parseUnits("1998500000000000000", 0));
    });

    it("test_getfCashBorrowFromPrincipal", async () => {
      const markets = await resolver.getActiveMarkets(3);
      const block = await hre.ethers.provider.getBlock("latest");
      const resp = await resolver.getfCashBorrowFromPrincipal(
        3,
        parseUnits("1000", 6),
        markets[0].maturity,
        parseUnits("5", 6),
        block.timestamp,
        true,
      );
      expect(resp[0]).to.gte(ethers.utils.parseUnits("100036000000", 0));
      expect(resp[1]).to.equal(1);
    });

    it("test_getfCashLendFromDeposit", async () => {
      const markets = await resolver.getActiveMarkets(3);
      const block = await hre.ethers.provider.getBlock("latest");
      const resp = await resolver.getfCashLendFromDeposit(
        3,
        parseUnits("1000", 6),
        markets[1].maturity,
        parseUnits("5", 6),
        block.timestamp,
        true,
      );
      expect(resp[0]).to.gte(ethers.utils.parseUnits("100201000000", 0));
      expect(resp[1]).to.equal(2);
    });

    it("test_getDepositFromfCashLend", async () => {
      const markets = await resolver.getActiveMarkets(3);
      const block = await hre.ethers.provider.getBlock("latest");
      const resp = await resolver.getDepositFromfCashLend(
        3,
        parseUnits("1000", 8),
        markets[1].maturity,
        parseUnits("5", 6),
        block.timestamp,
      );
      expect(resp[0]).to.gte(ethers.utils.parseUnits("987800000", 0));
      expect(resp[1]).to.gte(ethers.utils.parseUnits("4368040000000", 0));
      expect(resp[2]).to.equal(2);
    });

    it("test_getPrincipalFromfCashBorrow", async () => {
      const markets = await resolver.getActiveMarkets(3);
      const block = await hre.ethers.provider.getBlock("latest");
      const resp = await resolver.getPrincipalFromfCashBorrow(
        3,
        parseUnits("1000", 8),
        markets[0].maturity,
        0,
        block.timestamp,
      );
      expect(resp[0]).to.gte(ethers.utils.parseUnits("991000000", 0));
      expect(resp[1]).to.gte(ethers.utils.parseUnits("4380000000000", 0));
      expect(resp[2]).to.equal(1);
    });

    it("test_convertCashBalanceToExternal_asset", async () => {
      const resp = await resolver.convertCashBalanceToExternal(3, parseUnits("1000", 8), false);
      expect(resp).to.equal(ethers.utils.parseUnits("100000000000", 0));
    });

    it("test_convertCashBalanceToExternal_underlying", async () => {
      const resp = await resolver.convertCashBalanceToExternal(3, parseUnits("1000", 8), true);
      expect(resp).to.gte(ethers.utils.parseUnits("22610000", 0));
    });
  });
});
