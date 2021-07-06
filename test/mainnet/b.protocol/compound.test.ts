import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatEther, formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaBCompoundResolver, InstaBCompoundResolver__factory } from "../../../typechain";
import { Tokens } from "../../consts";

describe("B.Compound Resolvers", () => {
  let signer: SignerWithAddress;
  const account = "0xf7D44D5a28d5AF27a7F9c8fc6eFe0129e554d7c4";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("B.Compound Resolver", () => {
    let resolver: InstaBCompoundResolver;
    before(async () => {
      const deployer = new InstaBCompoundResolver__factory(signer);
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
      const [daiData, wbtcData] = await resolver.getCompoundData(account, [Tokens.DAI.caddr, Tokens.WBTC.caddr]);

      console.log("WBTC Balance: ", formatUnits(wbtcData.balanceOfUser, 8));
      expect(wbtcData.balanceOfUser).to.gt(0);

      console.log("DAI borrow balance: ", formatEther(daiData.borrowBalanceStoredUser));
      expect(daiData.borrowBalanceStoredUser).to.gt(0);
    });
  });
});
