import hre from "hardhat";

async function main() {
  const address = "0x2fDd379D7Ca2B7d154d61eD8488189Cb38084D52";
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
