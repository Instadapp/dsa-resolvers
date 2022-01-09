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
};

// Ensure that we have all the environment variables we need.
const mnemonic = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}

const alchemyApiKey = process.env.ALCHEMY_API_KEY;
if (!alchemyApiKey) {
  throw new Error("Please set your ALCHEMY_API_KEY in a .env file");
}

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

function getNetworkUrl(networkType: string) {
  //console.log(process.env);
  if (networkType === "avalanche") return "https://api.avax.network/ext/bc/C/rpc";
  else if (networkType === "polygon") return `https://polygon-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "arbitrum") return `https://arb-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else return `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKey}`;
}

function getBlockNumber(networkType: string) {
  let web3 = new Web3(new Web3.providers.HttpProvider(getNetworkUrl(networkType)));
  let blockNumber;
  web3.eth.getBlockNumber().then((x: any) => {
    blockNumber = x;
  });

  return blockNumber;
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
        blockNumber: getBlockNumber(String(process.env.networkType)),
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
    timeout: 10000 * 1000,
  },
};

export default config;
