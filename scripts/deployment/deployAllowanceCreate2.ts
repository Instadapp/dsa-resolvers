import hre, { ethers } from "hardhat";
import { execScript } from "../command";

// Arachnid's deterministic-deployment-proxy. Same address on every major EVM chain.
// See: https://github.com/Arachnid/deterministic-deployment-proxy
const DEFAULT_FACTORY = "0x4e59b44847b379578588920cA78FbF26c0B4956C";
const CONTRACT_NAME = "InstaAllowanceResolver";
const CONTRACT_FQN = "contracts/protocols/mainnet/allowance/main.sol:InstaAllowanceResolver";

async function main() {
  const [signer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const chainName = hre.network.name;

  console.log(`Network: ${chainName} (chainId=${network.chainId})`);
  console.log(`Deployer EOA: ${signer.address}`);

  const factory = (process.env.CREATE2_FACTORY ?? DEFAULT_FACTORY).toLowerCase();
  const saltInput = process.env.SALT;

  if (!saltInput) throw new Error("SALT missing in .env");
  
  const salt = saltInput.startsWith("0x") && saltInput.length === 66
    ? saltInput
    : ethers.utils.keccak256(ethers.utils.toUtf8Bytes(saltInput));

  const factoryCode = await ethers.provider.getCode(factory);
  if (factoryCode === "0x") {
    throw new Error(
      `CREATE2 factory ${factory} is not deployed on ${chainName}. ` +
      `Either deploy Arachnid's proxy first (see https://github.com/Arachnid/deterministic-deployment-proxy) ` +
      `or pass a different CREATE2_FACTORY env var.`,
    );
  }

  const artifact = await hre.artifacts.readArtifact(CONTRACT_NAME);
  const initCode = artifact.bytecode;
  if (!initCode || initCode === "0x") {
    throw new Error(`Empty bytecode for ${CONTRACT_NAME}. Did you run 'npx hardhat compile'?`);
  }
  const initCodeHash = ethers.utils.keccak256(initCode);

  const predicted = ethers.utils.getCreate2Address(factory, salt, initCodeHash);

  console.log(`Factory:        ${factory}`);
  console.log(`Salt (bytes32): ${salt}`);
  console.log(`Salt (input):   ${saltInput}`);
  console.log(`InitCode hash:  ${initCodeHash}`);
  console.log(`Predicted addr: ${predicted}`);

  const existing = await ethers.provider.getCode(predicted);
  if (existing !== "0x") {
    console.log(`\nAlready deployed at ${predicted} on ${chainName} — skipping.`);
    await verify(predicted, chainName);
    return;
  }

  // Arachnid factory calling convention: tx.data = salt(32) ++ initCode
  const data = ethers.utils.hexConcat([salt, initCode]);

  // Use live fee data instead of the hardhat config's hard-coded gasPrice,
  // which can be stale (e.g. mainnet config has 0.045 gwei, far below current).
  const feeData = await ethers.provider.getFeeData();
  const feeOverrides =
    feeData.maxFeePerGas && feeData.maxPriorityFeePerGas
      ? {
          maxFeePerGas: feeData.maxFeePerGas,
          maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
        }
      : { gasPrice: feeData.gasPrice ?? undefined };

  console.log(`\nSending deploy tx...`);
  const tx = await signer.sendTransaction({ to: factory, data, ...feeOverrides });
  console.log(`Tx hash: ${tx.hash}`);
  const receipt = await tx.wait();
  console.log(`Mined in block ${receipt.blockNumber}, gas used: ${receipt.gasUsed.toString()}`);

  const codeAfter = await ethers.provider.getCode(predicted);
  if (codeAfter === "0x") {
    throw new Error(`Deploy tx succeeded but no code found at ${predicted}.`);
  }
  console.log(`\n${CONTRACT_NAME} deployed at: ${predicted}`);

  await verify(predicted, chainName);
}

async function verify(address: string, chainName: string) {
  if (chainName === "hardhat" || chainName === "localhost") return;
  try {
    await execScript({
      cmd: "npx",
      args: ["hardhat", "verify", "--network", chainName, address, "--contract", CONTRACT_FQN],
      env: { networkType: chainName },
    });
  } catch (error) {
    console.log(`Failed to verify ${CONTRACT_NAME}@${address}`);
    console.log(error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
