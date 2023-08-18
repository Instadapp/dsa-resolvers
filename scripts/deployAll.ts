import { execScript } from "./command";
import inquirer from "inquirer";
import { connectors } from "./connectors";

let start: number, end: number, runchain: string;

// async function connectorSelect(chain: string) {
//   let { connector } = await inquirer.prompt([
//     {
//       name: "connector",
//       message: "Which connector do you want to deploy?",
//       type: "list",
//       choices: connectors[chain],
//     },
//   ]);

//   return connector;
// }

async function deployRunner() {
  const { chain } = await inquirer.prompt([
    {
      name: "chain",
      message: "What chain do you want to deploy on?",
      type: "list",
      choices: ["mainnet", "polygon", "avalanche", "arbitrum", "optimism", "fantom", "base"],
    },
  ]);

  const { choice } = await inquirer.prompt([
    {
      name: "choice",
      message: "Do you wanna try deploy on hardhat first?",
      type: "list",
      choices: ["yes", "no"],
    },
  ]);

  runchain = choice === "yes" ? "hardhat" : chain;

  console.log(`Deploying on ${runchain}, press (ctrl + c) to stop`);

  start = Date.now();
  for (let i = 0; i < connectors[chain].length; i++) {
    try {
      await execScript({
        cmd: "npx",
        args: ["hardhat", "run", "scripts/deployment/deploy.ts", "--network", `${runchain}`],
        env: {
          connectorName: connectors[chain][i],
          networkType: chain,
        },
      });
    } catch (e) {
      console.error(`Failed of ${connectors[chain][i]} connector`);
    }
  }
  end = Date.now();
}

deployRunner()
  .then(() => {
    console.log(`Done successfully, total time taken: ${(end - start) / 1000} sec`);
    process.exit(0);
  })
  .catch(err => {
    console.log("error:", err);
    process.exit(1);
  });
