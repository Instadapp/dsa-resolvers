import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaMetamorphoResolver, InstaMetamorphoResolver__factory } from "../../typechain";
import hre from "hardhat";

describe("Metamorpho Resolver", () => {
  let signer: SignerWithAddress;
  const account = "0xa58cfe09f3bb372b513d5799cacc25e5e62c90ea";

  const vaultAddresses: string[] = [
    '0x38989bba00bdf8181f4082995b3deae96163ac5d',
    '0xBEEF01735c132Ada46AA9aA4c54623cAA92A64CB',
  ];

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 19106931,
          },
        },
      ],
    });

    [signer] = await ethers.getSigners();
  });

  describe("Metamorpho Resolver", () => {
    let resolver: InstaMetamorphoResolver;

    before(async () => {
      const deployer = new InstaMetamorphoResolver__factory(signer);
      resolver = await deployer.deploy();
    });

    it("get token details should revert with a wrong token address", async () => {
      await expect(
        resolver.getVaultDetails([
          await ethers.Wallet.createRandom().getAddress(), // add a random address
        ]),
      ).to.revertedWith("function call to a non-contract account");
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
