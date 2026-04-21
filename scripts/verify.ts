import hre from "hardhat";

async function main() {
  const address = "0xA126B30C6719dD676B140386f45a4A254A88924B";
  const chain = String(hre.network.name);
  if (chain !== "hardhat") {
    await hre.run("verify:verify", {
      address: address,
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
