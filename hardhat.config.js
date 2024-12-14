require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const INFURA_PROJECT_ID = process.env.INFURA_PROJECT_ID;

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${INFURA_PROJECT_ID}`,
      accounts: [process.env.SEPOLIA_PRIVATE_KEY],
      chainId: 11155111,
    },
    polygonAmoy: {
      url: `https://polygon-amoy.infura.io/v3/${INFURA_PROJECT_ID}`,
      accounts: [process.env.POLYGON_PRIVATE_KEY],
      chainId: 80002,
    },
    arbitrum: {
      url: `https://arbitrum-sepolia.infura.io/v3/${INFURA_PROJECT_ID}`,
      accounts: [process.env.ARBITRUM_PRIVATE_KEY],
      chainId: 421614,
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};
