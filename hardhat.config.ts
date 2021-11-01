import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

import "./tasks/accounts";
import "./tasks/clean";

import { resolve } from "path";

import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";

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
};

// Ensure that we have all the environment variables we need.
const mnemonic = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}

const alchemyEthApiKey = process.env.ALCHEMY_ETH_API_KEY;
if (!alchemyEthApiKey) {
  throw new Error("Please set your ALCHEMY_ETH_API_KEY in a .env file");
}

const alchemyPolyApiKey = process.env.ALCHEMY_POLY_API_KEY;
if (!alchemyPolyApiKey) {
  throw new Error("Please set your ALCHEMY_POLY_API_KEY in a .env file");
}

const alchemyArbApiKey = process.env.ALCHEMY_ARB_API_KEY;
if (!alchemyArbApiKey) {
  throw new Error("Please set your ALCHEMY_ARB_API_KEY in a .env file");
}

function createTestnetConfig(network: keyof typeof chainIds): NetworkUserConfig {
  const url: string = "https://eth-" + network + ".alchemyapi.io/v2/" + alchemyEthApiKey;
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
        // Avalanche mainnet:
        // url: "https://api.avax.network/ext/bc/C/rpc",

        // Ethereum mainnet:
        url: `https://eth-mainnet.alchemyapi.io/v2/${alchemyEthApiKey}`,
        blockNumber: 12878959,

        // Polygon mainnet:
        // url: `https://polygon-mainnet.g.alchemy.com/v2/${alchemyPolyApiKey}`

        // Arbitrum mainnet:
        // url: `https://arb-mainnet.g.alchemy.com/v2/${alchemyArbApiKey}`
      },
    },
    goerli: createTestnetConfig("goerli"),
    kovan: createTestnetConfig("kovan"),
    rinkeby: createTestnetConfig("rinkeby"),
    ropsten: createTestnetConfig("ropsten"),
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
        version: "0.8.4",
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
    timeout: 100 * 1000,
  },
};

export default config;
