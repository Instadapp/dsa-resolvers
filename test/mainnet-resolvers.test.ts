import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { formatEther, formatUnits, parseUnits, parseEther } from "ethers/lib/utils";
import { ethers, network } from "hardhat";
import {
  IERC20__factory,
  InstaAaveV2Resolver,
  InstaAaveV2Resolver__factory,
  InstaCompoundResolver,
  InstaCompoundResolver__factory,
  InstaERC20Resolver,
  InstaERC20Resolver__factory,
  InstaMakerResolver,
  InstaMakerResolver__factory,
} from "../typechain";
import { Tokens } from "./consts";

describe("Resolvers", () => {
  let signer: SignerWithAddress;
  const account = "0xa8ABe411d1A3F524a2aB9C54f8427066a1F9f266";

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("Aave V2 Resolver", () => {
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

  describe("ERC20 Resolver", () => {
    let resolver: InstaERC20Resolver;

    before(async () => {
      const deployer = new InstaERC20Resolver__factory(signer);
      resolver = await deployer.deploy();
    });

    it("get token details should revert with a wrong token address", async () => {
      await expect(
        resolver.getTokenDetails([
          await ethers.Wallet.createRandom().getAddress(), // add a random address
          Tokens.USDC.addr, // add a token address
        ]),
      ).to.revertedWith("function call to a non-contract account");
    });

    it("gets token details properly", async () => {
      const tokenData = await resolver.getTokenDetails([
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", // ETH
        Tokens.DAI.addr,
        Tokens.USDC.addr,
      ]);

      const matches = [
        { name: "ETHER", sym: "ETH", is: true, decimals: 18 },
        { name: "Dai Stablecoin", sym: "DAI", is: true, decimals: 18 },
        { name: "USD Coin", sym: "USDC", is: true, decimals: 6 },
      ];

      for (let i = 0; i < matches.length; i++) {
        expect(tokenData[i].name).eq(matches[i].name);
        expect(tokenData[i].symbol).eq(matches[i].sym);
        expect(tokenData[i].isToken).eq(matches[i].is);
        expect(tokenData[i].decimals).eq(matches[i].decimals);
      }
    });

    it("token balances reverts if not a token", async () => {
      await expect(
        resolver.getBalances(account, [
          await ethers.Wallet.createRandom().getAddress(),
          "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", // ETH
        ]),
      ).to.revertedWith("function call to a non-contract account");
    });

    it("gets token balances properly", async () => {
      const tokenData = await resolver.getBalances(account, [
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", // ETH
        Tokens.DAI.addr,
        Tokens.USDC.addr,
      ]);

      const expectedOutput = [
        ethers.BigNumber.from("271779132138597342"),
        ethers.BigNumber.from("20001853994549354299"),
        ethers.BigNumber.from("4155609"),
      ];

      for (let i = 0; i < expectedOutput.length; i++) {
        expect(tokenData[i]).to.eq(expectedOutput[i]);
      }
    });

    it("token allowances reverts if not a token", async () => {
      await expect(
        resolver.getAllowances(account, signer.address, [
          await ethers.Wallet.createRandom().getAddress(),
          "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", // ETH
        ]),
      ).to.revertedWith("function call to a non-contract account");
    });

    it("gets token allowances properly", async () => {
      // impersonate account
      await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [account],
      });
      const fakeSigner = await ethers.getSigner(account);

      // fake allowances

      const dai = IERC20__factory.connect(Tokens.DAI.addr, fakeSigner);
      const usdc = IERC20__factory.connect(Tokens.USDC.addr, fakeSigner);
      const expectedAmts = [parseEther("0"), parseEther("100"), parseUnits("100", 6)];

      await dai.approve(signer.address, expectedAmts[1]);
      await usdc.approve(signer.address, expectedAmts[2]);

      const res = await resolver.getAllowances(account, signer.address, [
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", // ETH
        Tokens.DAI.addr,
        Tokens.USDC.addr,
      ]);

      for (let i = 0; i < expectedAmts.length; i++) {
        expect(res[i]).eq(expectedAmts[i]);
      }
    });
  });

  describe("Maker Resolver", () => {
    let resolver: InstaMakerResolver;

    before(async () => {
      const deployer = new InstaMakerResolver__factory(signer);
      resolver = await deployer.deploy();
    });

    it("returns the dai position properly", async () => {
      const res = await resolver.getDaiPosition(account);
      expect(res.amt).eq(ethers.BigNumber.from("200005872985130003460"));
      expect(res.dsr).eq(ethers.BigNumber.from("1000000000003170820659990704"));
    });
  });
});
