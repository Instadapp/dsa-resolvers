import inquirer from "inquirer";
import { promises as fs } from "fs";
import { join } from "path";
import { execScript } from "./command";

async function testRunner() {
  const chain = ["avalanche", "mainnet", "polygon"];
  for (let ch of chain) {
    console.log(`📗Running test for %c${ch}: `, "blue");
    let path: string;
    const testsPath = join(__dirname, "../test", ch);
    await fs.access(testsPath);
    const availableTests = await fs.readdir(testsPath);
    if (availableTests.length !== 0) {
      path = availableTests.map(file => join(testsPath, file)).join(" ");

      await execScript({
        cmd: "npx",
        args: ["hardhat", "test", path],
        env: {
          networkType: ch,
        },
      });
    }
  }
}

testRunner()
  .then(() => console.log("🙌 finished the test runner"))
  .catch(err => console.error("❌ failed due to error: ", err));
