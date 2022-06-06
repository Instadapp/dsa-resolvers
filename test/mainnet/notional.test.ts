import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { InstaNotionalResolver, InstaNotionalResolver__factory } from "../../typechain";
import hre from "hardhat";
import { expect } from "chai";
import { parseEther, parseUnits } from "ethers/lib/utils";

const NOTIONAL_CONTRACT_ADDRESS = "0x1344A36A1B56144C3Bc62E7757377D288fDE0369";
const NOTIONAL_CONTRACT_ABI = [
  "function updateAssetRate(uint16 currencyId, address rateOracle) external",
  "function upgradeTo(address newImplementation) public",
  "function owner() external view returns (address)",
];
const ETH_WHALE = "0x9acb5CE4878144a74eEeDEda54c675AA59E0D3D2";

describe("Notional Resolvers", () => {
  let signer: SignerWithAddress;
  const testAccount = "0x8665d75ff2db29355428b590856505459bb675e3";
  let notional: any;
  let notionalOwner: any;
  let ethWhale: any;
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
            blockNumber: 14915865,
          },
        },
      ],
    });

    notional = new ethers.Contract(NOTIONAL_CONTRACT_ADDRESS, NOTIONAL_CONTRACT_ABI, ethers.provider);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ETH_WHALE],
    });
    ethWhale = await ethers.getSigner(ETH_WHALE);

    await ethWhale.sendTransaction({
      to: await notional.owner(),
      value: ethers.BigNumber.from(10).pow(18).mul(10),
    });

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [await notional.owner()],
    });
    notionalOwner = await ethers.getSigner(await notional.owner());

    await notional.connect(notionalOwner).upgradeTo("0x16eD130F7A6dcAc7e3B0617A7bafa4b470189962");
    await notional.connect(notionalOwner).updateAssetRate(1, "0x8E3D447eBE244db6D28E2303bCa86Ef3033CFAd6");
    await notional.connect(notionalOwner).updateAssetRate(2, "0x719993E82974f5b5eA0c5ebA25c260CD5AF78E00");
    await notional.connect(notionalOwner).updateAssetRate(3, "0x612741825ACedC6F88D8709319fe65bCB015C693");
    await notional.connect(notionalOwner).updateAssetRate(4, "0x39D9590721331B13C8e9A42941a2B961B513E69d");

    const deployer = new InstaNotionalResolver__factory(signer);
    resolver = await deployer.deploy();
    await resolver.deployed();
  });

  describe("Notional Resolver", () => {
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
      expect(amount).to.gte(ethers.utils.parseUnits("1998880000000000000", 0));
    });

    it("test_getfCashBorrowFromPrincipal", async () => {
      const markets = await resolver.getActiveMarkets(3);
      const resp = await resolver.getfCashBorrowFromPrincipal(
        3,
        parseUnits("1000", 6),
        markets[0].maturity,
        parseUnits("5", 6),
        1654408809,
        true,
      );
      expect(resp[0]).to.gte(ethers.utils.parseUnits("100237000000", 0));
      expect(resp[1]).to.equal(1);
    });

    it("test_getfCashLendFromDeposit", async () => {
      const markets = await resolver.getActiveMarkets(3);
      const resp = await resolver.getfCashLendFromDeposit(
        3,
        parseUnits("1000", 6),
        markets[0].maturity,
        parseUnits("5", 6),
        1654408809,
        true,
      );
      expect(resp[0]).to.gte(ethers.utils.parseUnits("100201000000", 0));
      expect(resp[1]).to.equal(1);
    });

    it("test_getDepositFromfCashLend", async () => {
      const markets = await resolver.getActiveMarkets(3);
      const resp = await resolver.getDepositFromfCashLend(
        3,
        parseUnits("1000", 8),
        markets[0].maturity,
        parseUnits("5", 6),
        1654408809,
      );
      expect(resp[0]).to.gte(ethers.utils.parseUnits("997990000", 0));
      expect(resp[1]).to.gte(ethers.utils.parseUnits("4413570000000", 0));
      expect(resp[2]).to.equal(1);
    });

    it("test_getPrincipalFromfCashBorrow", async () => {
      const markets = await resolver.getActiveMarkets(3);
      const resp = await resolver.getPrincipalFromfCashBorrow(
        3,
        parseUnits("1000", 8),
        markets[0].maturity,
        0,
        1654408809,
      );
      expect(resp[0]).to.gte(ethers.utils.parseUnits("997000000", 0));
      expect(resp[1]).to.gte(ethers.utils.parseUnits("4411960000000", 0));
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
