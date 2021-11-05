import inquirer from "inquirer";
import { promises as fs } from "fs";
import { join } from "path/posix";
import { execFile, spawn } from "child_process";

export async function execScript(cmd: string): Promise<number> {
  return new Promise((resolve, reject) => {
    const parts = cmd.split(" ");
    const proc = spawn(parts[1], parts.slice(2), { env: { networkType: parts[0] }, shell: true, stdio: "inherit" });
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
  const chain = ["avalanche", "mainnet", "polygon"];
  for (let ch of chain) {
    console.log(`📗Running test for %c${ch}: `, "blue");
    let path: string;
    const testsPath = join(__dirname, "../test", ch);
    await fs.access(testsPath);
    const availableTests = await fs.readdir(testsPath);
    if (availableTests.length !== 0) {
      path = availableTests.map(file => join(testsPath, file)).join(" ");
      await execScript(ch + " npx hardhat test " + path);
    }
  }
}

testRunner()
  .then(() => console.log("🙌 finished the test runner"))
  .catch(err => console.error("❌ failed due to error: ", err));
