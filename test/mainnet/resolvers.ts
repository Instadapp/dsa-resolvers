import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatEther, formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import {
  InstaAaveV2Resolver,
  InstaAaveV2Resolver__factory,
  InstaCompoundResolver,
  InstaCompoundResolver__factory,
} from "../../typechain";
import { Tokens } from "../consts";

describe("Resolvers", () => {
  let signer: SignerWithAddress;
  const account = "0xa8ABe411d1A3F524a2aB9C54f8427066a1F9f266";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Aave V2 Resolver [mainnet]", () => {
    let resolver: InstaAaveV2Resolver;
    before(async () => {
      const deployer = new InstaAaveV2Resolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("Returns the positions on AaveV2", async () => {
      const results = await resolver.getPosition(account, [Tokens.DAI.addr]);
      const userTokenData = results[0];
      const userData = results[1];

      // check for token balances
      console.log("Supply Balance DAI: ", formatUnits(userTokenData[0].supplyBalance, Tokens.DAI.decimals));
      expect(userTokenData[0].supplyBalance).to.gt(0);
      console.log(
        "Variable Borrow Balance DAI: ",
        formatUnits(userTokenData[0].variableBorrowBalance, Tokens.DAI.decimals),
      );
      expect(userTokenData[0].variableBorrowBalance).to.gt(0);

      // check for user data
      expect(userData.totalBorrowsETH).to.gt(0);
      expect(userData.totalCollateralETH).to.gt(0);
    });
  });

  describe("Compound V2 Resolver", () => {
    let resolver: InstaCompoundResolver;
    before(async () => {
      const deployer = new InstaCompoundResolver__factory(signer);
      resolver = await deployer.deploy();
      await resolver.deployed();
    });

    it("Returns the price of cToken's underlying in ETH", async () => {
      const [priceInETH, priceInUSD] = await resolver.getPriceInEth(Tokens.DAI.caddr);
      console.log("DAI price in ETH: ", formatEther(priceInETH));
      console.log("DAI price in USD: ", formatEther(priceInUSD));
      expect(priceInETH).to.gt(0);
      expect(priceInUSD).to.gt(0);
    });

    it("Returns the positions correctly", async () => {
      const [daiData, usdcData] = await resolver.getCompoundData(account, [Tokens.DAI.caddr, Tokens.USDC.caddr]);

      console.log("USDC Balance: ", formatUnits(usdcData.balanceOfUser, 6));
      expect(usdcData.balanceOfUser).to.gt(0);

      console.log("DAI borrow balance: ", formatEther(daiData.borrowBalanceStoredUser));
      expect(daiData.borrowBalanceStoredUser).to.gt(0);
    });
  });
});
