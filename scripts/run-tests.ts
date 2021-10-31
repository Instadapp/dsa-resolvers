import inquirer from "inquirer";
import { promises as fs } from "fs";
import { join } from "path/posix";
import { spawn } from "child_process";
import { assert } from "chai";

export async function execScript(cmd: string): Promise<number> {
  return new Promise((resolve, reject) => {
    const parts = cmd.split(" ");
    const proc = spawn(parts[0], parts.slice(1), { shell: true, stdio: "inherit" });
    proc.on("exit", code => {
      if (code !== 0) {
        reject(code);
        return;
      }

      resolve(code);
    });
  });
}

async function testRunner() {
  let currentNetwork = String(network.name);
  if (String(network.name) === "hardhat") {
    currentNetwork = "mainnet";
  }
  console.log(`Current Network: ${currentNetwork}`);
  const { chain } = await inquirer.prompt([
    {
      name: "chain",
      message: "What chain do you want to run tests on?",
      type: "list",
      choices: ["mainnet", "polygon", "avalanche"],
    },
  ]);

  let networkType;
  const testsPath = join(__dirname, "../test", chain);
  await fs.access(testsPath);
  const availableTests = await fs.readdir(testsPath);
  if (availableTests.length === 0) {
    throw new Error(`No tests available for ${chain}`);
  }

  if (chain === "mainnet") {
    networkType = "hardhat";
  } else if (chain === "polygon") {
    networkType = "polygon";
  } else if (chain === "avalanche") {
    networkType = "avalanche";
  }

  const { testName } = await inquirer.prompt([
    {
      name: "testName",
      message: "For which resolver you want to run the tests?",
      type: "list",
      choices: ["all", ...availableTests],
    },
  ]);

  let path: string;
  if (testName === "all") {
    path = availableTests.map(file => join(testsPath, file)).join(" ");
  } else {
    path = join(testsPath, testName);
  }

  assert(String(network.name) === networkType, "Please select suitable network otherwise change hardhat config");
  await execScript("npx hardhat test " + path);
}

testRunner()
  .then(() => console.log("🙌 finished the test runner"))
  .catch(err => console.error("❌ failed due to error: ", err));
