import { ethers } from "hardhat";
import { expect } from "chai";

import { InstaAugmentedFinanceV1Resolver, InstaAugmentedFinanceV1Resolver__factory } from "../../typechain";
import { Tokens } from "../consts";

describe("Augmented Finance Resolver", () => {
  let resolver: InstaAugmentedFinanceV1Resolver;

  before(async () => {
    const [signer] = await ethers.getSigners();
    const deployer = new InstaAugmentedFinanceV1Resolver__factory(signer);
    resolver = await deployer.deploy();
    await resolver.deployed();
  });

  it("should returns the positions on Augmented Finance", async () => {
    const account = "0xdfce58faebe4731a8e2ca097b79280ae783254cd";
    const [[userTokenData], userData] = await resolver.getPositions(account, [Tokens.DAI.addr]);

    expect(userTokenData.supplyBalance).to.gte(0);
    expect(userTokenData.variableBorrowBalance).to.gte(0);
    expect(userData.totalBorrowsETH).to.gte(0);
    expect(userData.totalCollateralETH).to.gte(0);
    expect(userData.availableBorrowsETH).to.gte(0);
    expect(userData.healthFactor).to.gte(0);
  });
});
