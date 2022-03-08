import { Contract } from "@ethersproject/contracts";
// We require the Hardhat Runtime Environment explicitly here. This is optional but useful for running the
// script in a standalone fashion through `node <script>`. When running the script with `hardhat run <script>`,
// you'll find the Hardhat Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

import { AaveV3Resolver__factory } from "../typechain";

async function main(): Promise<void> {
  const AaveV3Resolver: AaveV3Resolver__factory = await ethers.getContractFactory("AaveV3Resolver");
  const aaveV3Resolver: Contract = await AaveV3Resolver.deploy();
  await aaveV3Resolver.deployed();

  console.log("Resolver deployed to: ", aaveV3Resolver.address);
}

// We recommend this pattern to be able to use async/await everywhere and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
