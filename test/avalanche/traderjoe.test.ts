import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { JoeResolver, JoeResolver__factory } from "../../typechain";
import { Tokens } from "../consts";
import BigNumber from "bignumber.js";

describe("TraderJoe", () => {
  let signer: SignerWithAddress;
  const account = "0x9681319f4e60dD165CA2432f30D91Bb4DcFdFaa2";
  // const account = "0x15C6b352c1F767Fa2d79625a40Ca4087Fab9a198";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Trader Joe Resolver", () => {
    let resolver: JoeResolver;
    before(async () => {
      const deployer = new JoeResolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("Returns the positions on traderJoe for given assets", async () => {
      const results = await resolver.callStatic.getPosition(account, [
        "0xEd6AaF91a2B084bd594DBd1245be3691F9f637aC",
        "0xc988c170d0E38197DC634A45bF00169C7Aa7CA19",
      ]);

      //check user data
      console.log();
      console.log("**********************************************");
      console.log("User Data");
      console.log("**********************************************");
      const supplies = results.totalCollateralUSD;
      const borrows = results.totalBorrowUSD;
      expect(supplies).to.gte(0);
      expect(borrows).to.gte(0);
      console.log(`Supplies in USD: ${Number(supplies) / 10 ** 18}`);
      console.log(`Borrows in USD: ${Number(borrows) / 10 ** 18}`);
      console.log(`liquidity: ${results.liquidity}`);
      console.log(`shortfall: ${results.shortfall}`);
      console.log(`healthFactor: ${results.healthFactor}`);

      // check for token data
      for (let i = 0; i < 2; i++) {
        const data = results.tokensData[i];

        console.log();
        console.log("**********************************************");
        if (i == 0) console.log("USDC data:");
        else console.log("DAI data: ");
        console.log("**********************************************");

        console.log(`tokenAddress: ${data.jToken}`);
        console.log(`tokenSupplyBalance: ${data.supplyBalance}`);
        console.log(`tokenSupplyUSD: ${data.supplyValueUSD}`);
        console.log(`collateralUSD: ${data.collateralValueUSD}`);
        console.log(`borrowBalance: ${data.borrowBalanceStored}`);
        console.log(`borrowUSD: ${data.borrowValueUSD}`);
        console.log(`underlyingTokenBalance: ${data.underlyingTokenBalance}`);
        console.log(`underlyingTokenAllowance: ${data.underlyingTokenAllowance}`);
        console.log(`supplyRatePerSec: ${data.tokenData.supplyRatePerSecond}`);
        console.log(`borrowRatePerSec: ${data.tokenData.borrowRatePerSecond}`);
        console.log(`collateralCap: ${data.tokenData.collateralCap}`);
        console.log(`underlyingPrice: ${data.tokenData.underlyingPrice}`);
        console.log(`EthPrice: ${data.tokenData.priceInETH}`);
        console.log(`UsdPrice: ${data.tokenData.priceInUSD}`);
        console.log(`supplyCap: ${data.tokenData.supplyCap}`);
        console.log(`borrowCap: ${data.tokenData.borrowCap}`);
        console.log(`reserveFactorMantissa: ${data.tokenData.reserveFactorMantissa}`);
        console.log(`collateralFactorMantissa: ${data.tokenData.collateralFactorMantissa}`);
        console.log(`jTokenDecimal: ${data.tokenData.jTokenDecimals}`);
        console.log(`underlyingDecimal: ${data.tokenData.underlyingDecimals}`);
        console.log();
      }
    });

    it("Returns the user's positions on traderJoe for all jTokens", async () => {
      const results = await resolver.callStatic.getPositionAll(account);

      //check user data
      console.log();
      console.log("**********************************************");
      console.log("User Data");
      console.log("**********************************************");
      const supplies = results.totalCollateralUSD;
      const borrows = results.totalBorrowUSD;
      expect(supplies).to.gte(0);
      expect(borrows).to.gte(0);
      console.log(`Supplies in USD: ${Number(supplies) / 10 ** 18}`);
      console.log(`Borrows in USD: ${Number(borrows) / 10 ** 18}`);
      console.log(`liquidity: ${results.liquidity}`);
      console.log(`shortfall: ${results.shortfall}`);
      console.log(`healthFactor: ${results.healthFactor}`);
      console.log();
      console.log("**********************************************");
      console.log("Token data:");
      console.log("**********************************************");

      // check for token data
      for (let i = 0; i < results.tokensData.length; i++) {
        const data = results.tokensData[i];

        console.log();
        console.log(`tokenAddress: ${data.jToken}`);
        console.log(`tokenSupplyBalance: ${data.supplyBalance}`);
        console.log(`tokenSupplyUSD: ${data.supplyValueUSD}`);
        console.log(`collateralValueUSD: ${data.collateralValueUSD}`);
        console.log(`borrowBalance: ${data.borrowBalanceStored}`);
        console.log(`borrowUSD: ${data.borrowValueUSD}`);
        console.log(`underlyingTokenBalance: ${data.underlyingTokenBalance}`);
        console.log(`underlyingTokenAllowance: ${data.underlyingTokenAllowance}`);
        console.log(`supplyRatePerSec: ${data.tokenData.supplyRatePerSecond}`);
        console.log(`borrowRatePerSec: ${data.tokenData.borrowRatePerSecond}`);
        console.log(`collateralCap: ${data.tokenData.collateralCap}`);
        console.log(`underlyingPrice: ${data.tokenData.underlyingPrice}`);
        console.log(`EthPrice: ${data.tokenData.priceInETH}`);
        console.log(`UsdPrice: ${data.tokenData.priceInUSD}`);
        console.log(`supplyCap: ${data.tokenData.supplyCap}`);
        console.log(`borrowCap: ${data.tokenData.borrowCap}`);
        console.log(`reserveFactorMantissa: ${data.tokenData.reserveFactorMantissa}`);
        console.log(`collateralFactorMantissa: ${data.tokenData.collateralFactorMantissa}`);
        console.log(`jTokenDecimal: ${data.tokenData.jTokenDecimals}`);
        console.log(`underlyingDecimal: ${data.tokenData.underlyingDecimals}`);
        console.log();
      }
    });
  });
});
