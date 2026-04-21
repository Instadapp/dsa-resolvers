import { formatUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { InstaVenusCoreResolverBSC__factory } from "../typechain";

async function main() {
  const [signer] = await ethers.getSigners();
  console.log(`Network: ${(await ethers.provider.getNetwork()).chainId}`);
  console.log(`Deployer: ${signer.address}`);

  const factory = new InstaVenusCoreResolverBSC__factory(signer);
  const resolver = await factory.deploy();
  await resolver.deployed();

  console.log(`Resolver deployed at: ${resolver.address}`);

  const user = "0x344996e9Fb42Be22F646B0e2CE0be2a87368240b";
  const vBNB = "0xA07c5b74C9B40447a954e1466938b865b6BBea36";
  const vUSDT = "0xfD5840Cd36d94D7229439859C0112a4185BC0255";

  console.log("\n=== name() ===");
  console.log(await resolver.name());

  console.log("\n=== getMarketsList() ===");
  const markets = await resolver.getMarketsList();
  console.log(`Markets count: ${markets.length}`);

  console.log("\n=== getPosition(user, [vBNB, vUSDT]) ===");
  try {
    const [userData, userMarketData, marketData] = await resolver.getPosition(user, [vBNB, vUSDT]);
    console.log(`Liquidity: ${formatUnits(userData.liquidity, 18)}`);
    console.log(`Shortfall: ${formatUnits(userData.shortfall, 18)}`);
    console.log(`Markets returned: ${marketData.length}`);
    console.log(`User markets returned: ${userMarketData.length}`);
  } catch (error) {
    console.error("getPosition failed:", error);
  }

  console.log("\n=== getPositionAll(user) ===");
  try {
    const [userDataAll, userMarketsAll, marketsAll] = await resolver.getPositionAll(user);
    console.log(`Liquidity: ${formatUnits(userDataAll.liquidity, 18)}`);
    console.log(`Shortfall: ${formatUnits(userDataAll.shortfall, 18)}`);
    console.log(`Markets returned: ${marketsAll.length}`);
    console.log(`User markets returned: ${userMarketsAll.length}`);
  } catch (error) {
    console.error("getPositionAll failed:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
