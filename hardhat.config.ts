import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "@nomiclabs/hardhat-etherscan";

import "./tasks/accounts";
import "./tasks/clean";
import "hardhat-gas-reporter";

import { resolve } from "path";

import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";
import Web3 from "web3";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const chainIds = {
  ganache: 1337,
  goerli: 5,
  hardhat: 31337,
  kovan: 42,
  mainnet: 1,
  rinkeby: 4,
  ropsten: 3,
  avalanche: 43114,
  polygon: 137,
  optimism: 10,
  fantom: 250,
};

// Ensure that we have all the environment variables we need.
const mnemonic = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}

const alchemyApiKey = process.env.ALCHEMY_API_KEY;
if (!alchemyApiKey) {
  throw new Error("Please set your ALCHEMY_ETH_API_KEY in a .env file");
}
const ETHERSCAN_API = process.env.ETHERSCAN_API_KEY;
const POLYGONSCAN_API = process.env.POLYGON_API_KEY;
const ARBISCAN_API = process.env.ARBISCAN_API_KEY;
const OPTIMISM_API = process.env.OPTIMISM_API_KEY;
const SNOWTRACE_API = process.env.SNOWTRACE_API_KEY;
const FANTOMSCAN_API = process.env.FANTOM_API_KEY;

function createTestnetConfig(network: keyof typeof chainIds): NetworkUserConfig {
  const url: string = "https://eth-" + network + ".alchemyapi.io/v2/" + alchemyApiKey;
  return {
    accounts: {
      count: 10,
      initialIndex: 0,
      mnemonic,
      path: "m/44'/60'/0'/0",
    },
    chainId: chainIds[network],
    url,
  };
}
function getScanApiKey(networkType: string) {
  if (networkType === "avalanche") return SNOWTRACE_API;
  else if (networkType === "polygon") return POLYGONSCAN_API;
  else if (networkType === "arbitrum") return ARBISCAN_API;
  else if (networkType === "fantom") return FANTOMSCAN_API;
  else if (networkType === "optimism") return OPTIMISM_API;
  else return ETHERSCAN_API;
}

function getNetworkUrl(networkType: string) {
  //console.log(process.env);
  if (networkType === "avalanche") return "https://api.avax.network/ext/bc/C/rpc";
  else if (networkType === "polygon") return `https://polygon-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "arbitrum") return `https://arb-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "optimism") return `https://opt-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "fantom") return `https://rpc.ftm.tools/`;
  else return `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKey}`;
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: "./contracts",
  },
  networks: {
    hardhat: {
      accounts: {
        mnemonic,
      },
      chainId: chainIds.hardhat,
      forking: {
        url: String(getNetworkUrl(String(process.env.networkType))),
      },
    },
    goerli: createTestnetConfig("goerli"),
    kovan: createTestnetConfig("kovan"),
    rinkeby: createTestnetConfig("rinkeby"),
    ropsten: createTestnetConfig("ropsten"),
    optimism: {
      url: `https://opt-mainnet.g.alchemy.com/v2/${alchemyApiKey}`,
      chainId: 10,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 1000000, // 0.0001 GWEI
    },
    polygon: {
      url: `https://polygon-mainnet.g.alchemy.com/v2/${alchemyApiKey}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    arbitrum: {
      url: `https://arb-mainnet.g.alchemy.com/v2/${alchemyApiKey}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    fantom: {
      url: `https://rpc.ftm.tools/`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKey}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 10000000000,
    },
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.6",
        settings: {
          metadata: {
            bytecodeHash: "none",
          },
          optimizer: {
            enabled: true,
            runs: 800,
          },
        },
      },
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 800,
          },
        },
      },
    ],
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  mocha: {
    timeout: 10000 * 1000,
  },
  etherscan: {
    apiKey: getScanApiKey(String(process.env.networkType)),
  },
};

export default config;
