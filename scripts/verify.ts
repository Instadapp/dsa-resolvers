import hre from "hardhat";

async function main() {
  const address = "0x8DF22eF181eB03A7692f58242d3C29297FD8cC47";
  const chain = String(hre.network.name);
  if (chain !== "hardhat") {
    await hre.run("verify:verify", {
      address: address,
      contract: "contracts/protocols/mainnet/allowance/main.sol:InstaAllowanceResolver",
      constructorArguments: [],
    });
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});
