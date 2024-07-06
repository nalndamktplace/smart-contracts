import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-verify";
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  networks: {
    hardhat: {},
    polygonAmoy: {
      url: "https://rpc.ankr.com/polygon_amoy",
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.25",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      },
      {
        version: "0.4.17",
        settings: {
          evmVersion: "byzantium",
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  etherscan: {
    apiKey: {
      polygonAmoy: process.env.POLYGONSCAN_API_KEY!,
    },
  },
};

export default config;
