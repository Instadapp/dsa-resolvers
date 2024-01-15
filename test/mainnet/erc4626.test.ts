import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaERC4626Resolver, InstaERC4626Resolver__factory } from "../../typechain";

describe("ERC4626 Resolvers", () => {
  let signer: SignerWithAddress;
  const account = "0xa58cfe09f3bb372b513d5799cacc25e5e62c90ea";

  const vaultAddresses: string[] = [
    "0x83f20f44975d03b1b09e64809b757c47f942beea", // SDAI address
    "0xc21f107933612ecf5677894d45fc060767479a9b", // Aave erc4626 address
  ];

  before(async () => {
    [signer] = await ethers.getSigners();
  });

  describe("ERC4626 Resolver", () => {
    let resolver: InstaERC4626Resolver;

    before(async () => {
      const deployer = new InstaERC4626Resolver__factory(signer);
      resolver = await deployer.deploy();
    });

    it("get token details should revert with a wrong token address", async () => {
      await expect(
        resolver.getVaultDetails([
          await ethers.Wallet.createRandom().getAddress(), // add a random address
        ]),
      ).to.revertedWith("function call to a non-contract account");
    });

    it("gets token details properly", async () => {
      const tokenData = await resolver.getVaultDetails(vaultAddresses);

      const matches = [
        {
          name: "Savings Dai",
          sym: "sDAI",
          is: true,
          decimals: 18,
          asset: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
        },
        {
          name: "ERC4626-Wrapped Aave v2 WETH",
          sym: "wa2WETH",
          is: true,
          decimals: 18,
          asset: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        },
      ];

      for (let i = 0; i < matches.length; i++) {
        expect(tokenData[i].name).eq(matches[i].name);
        expect(tokenData[i].symbol).eq(matches[i].sym);
        expect(tokenData[i].isToken).eq(matches[i].is);
        expect(tokenData[i].decimals).eq(matches[i].decimals);
        expect(tokenData[i].asset).eq(matches[i].asset);
        console.log("convertToShares :>> ", tokenData[i].convertToShares);
        console.log("convertToAssets :>> ", tokenData[i].convertToAssets);
      }
    });

    it("token balances reverts if not a token", async () => {
      await expect(resolver.getPositions(account, [await ethers.Wallet.createRandom().getAddress()])).to.revertedWith(
        "function call to a non-contract account",
      );
    });

    it("gets user positions properly", async () => {
      const tokenData = await resolver.getPositions(account, vaultAddresses);

      console.log("tokenData :>> ", tokenData);
    });

    it("token allowances reverts if not a token", async () => {
      await expect(resolver.getAllowances(account, [await ethers.Wallet.createRandom().getAddress()])).to.revertedWith(
        "function call to a non-contract account",
      );
    });

    it("gets token allowances properly", async () => {
      const res = await resolver.getAllowances(account, vaultAddresses);

      console.log("res :>> ", res);
    });

    it("gets Vault Preview", async () => {
      const _vaultPreview = await resolver.getVaultPreview(parseEther("1"), vaultAddresses);

      console.log("_vaultPreview :>> ", _vaultPreview);
    });

    it("gets MetaMorpho Details", async () => {
      const metaMorphoMarkets = [
        '0x38989bba00bdf8181f4082995b3deae96163ac5d',
        '0xBEEF01735c132Ada46AA9aA4c54623cAA92A64CB',
      ]
      const _metamorphpDetails = await resolver.getMetaMorphoDetails(metaMorphoMarkets);

      console.log("_metamorphpDetails :>> ", _metamorphpDetails);
    });
  });
});
