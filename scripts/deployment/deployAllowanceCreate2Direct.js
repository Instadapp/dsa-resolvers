// Standalone CREATE2 deployment driver for InstaAllowanceResolver.
// Uses public RPCs + the PRIVATE_KEY from .env, no hardhat runtime required.
// Usage: CHAIN=mainnet node scripts/deployment/deployAllowanceCreate2Direct.js
require("dotenv").config();
const { ethers } = require("ethers");
const artifact = require("../../artifacts/contracts/protocols/mainnet/allowance/main.sol/InstaAllowanceResolver.json");

const FACTORY = "0x4e59b44847b379578588920cA78FbF26c0B4956C";
const SALT = process.env.SALT;

if (!SALT) throw new Error("SALT missing in .env");

const CHAINS = {
  mainnet: { chainId: 1,     rpcs: ["https://ethereum-rpc.publicnode.com", "https://rpc.ankr.com/eth", "https://cloudflare-eth.com"] },
  arbitrum:{ chainId: 42161, rpcs: ["https://arb1.arbitrum.io/rpc", "https://arbitrum-one-rpc.publicnode.com"] },
  base:    { chainId: 8453,  rpcs: ["https://mainnet.base.org", "https://base-rpc.publicnode.com"] },
};

async function getProvider(chain) {
  const cfg = CHAINS[chain];
  if (!cfg) throw new Error(`Unknown chain: ${chain}`);
  let lastErr;
  for (const url of cfg.rpcs) {
    try {
      const p = new ethers.providers.StaticJsonRpcProvider({ url, skipFetchSetup: true }, cfg.chainId);
      await p.getBlockNumber();
      return p;
    } catch (e) {
      lastErr = e;
    }
  }
  throw new Error(`All RPCs failed for ${chain}: ${lastErr && lastErr.message}`);
}

async function main() {
  const chain = process.env.CHAIN;
  if (!chain) throw new Error("Set CHAIN env var: mainnet | arbitrum | base");

  const pkRaw = process.env.PRIVATE_KEY;
  if (!pkRaw) throw new Error("PRIVATE_KEY missing in .env");
  const pk = pkRaw.startsWith("0x") ? pkRaw : "0x" + pkRaw;

  const provider = await getProvider(chain);
  const wallet = new ethers.Wallet(pk, provider);

  const initCode = artifact.bytecode;
  const initCodeHash = ethers.utils.keccak256(initCode);
  const predicted = ethers.utils.getCreate2Address(FACTORY, SALT, initCodeHash);

  console.log(`Chain:          ${chain}`);
  console.log(`Deployer:       ${wallet.address}`);
  console.log(`Factory:        ${FACTORY}`);
  console.log(`Salt:           ${SALT}`);
  console.log(`InitCode hash:  ${initCodeHash}`);
  console.log(`Predicted addr: ${predicted}`);

  const [factoryCode, existing, bal, feeData] = await Promise.all([
    provider.getCode(FACTORY),
    provider.getCode(predicted),
    provider.getBalance(wallet.address),
    provider.getFeeData(),
  ]);

  if (factoryCode === "0x") throw new Error(`Factory not deployed on ${chain}`);
  console.log(`Deployer balance: ${ethers.utils.formatEther(bal)} ETH`);

  if (existing !== "0x") {
    console.log(`\nAlready deployed at ${predicted} on ${chain} — skipping.`);
    return predicted;
  }

  const data = ethers.utils.hexConcat([SALT, initCode]);

  const feeOverrides =
    feeData.maxFeePerGas && feeData.maxPriorityFeePerGas
      ? {
          maxFeePerGas: feeData.maxFeePerGas,
          maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
        }
      : { gasPrice: feeData.gasPrice };

  if (feeOverrides.maxFeePerGas) {
    console.log(`maxFeePerGas:         ${ethers.utils.formatUnits(feeOverrides.maxFeePerGas, "gwei")} gwei`);
    console.log(`maxPriorityFeePerGas: ${ethers.utils.formatUnits(feeOverrides.maxPriorityFeePerGas, "gwei")} gwei`);
  } else {
    console.log(`gasPrice:             ${ethers.utils.formatUnits(feeOverrides.gasPrice, "gwei")} gwei`);
  }

  console.log(`\nSending deploy tx...`);
  const tx = await wallet.sendTransaction({ to: FACTORY, data, ...feeOverrides });
  console.log(`Tx hash: ${tx.hash}`);
  const receipt = await tx.wait(1);
  console.log(`Mined in block ${receipt.blockNumber}, gas used: ${receipt.gasUsed.toString()}`);

  const codeAfter = await provider.getCode(predicted);
  if (codeAfter === "0x") throw new Error(`No code at ${predicted} after deploy`);
  console.log(`\nDeployed: ${predicted} on ${chain}`);
  return predicted;
}

main().then(() => process.exit(0)).catch((e) => { console.error(e); process.exit(1); });
