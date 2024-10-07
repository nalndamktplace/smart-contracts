import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  networks: {
    hardhat: {},
    polygonAmoy: {
      url: "https://rpc.ankr.com/polygon_amoy",
      accounts: [
        `0x${process.env.PRIVATE_KEY}`,
        `0x${process.env.PRIVATE_KEY_AUTH}`,
      ],
    },
    blastSepolia: {
      url: "https://sepolia.blast.io",
      accounts: [
        `0x${process.env.PRIVATE_KEY}`,
        `0x${process.env.PRIVATE_KEY_AUTH}`,
      ],
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
    ],
  },
  etherscan: {
    apiKey: {
      polygonAmoy: process.env.POLYGONSCAN_API_KEY!,
      blastSepolia: "MQKRWIXNDYEHRPSIZDWMV4W9DWWUX3YVKY",
    },
    customChains: [
      {
        network: "polygonAmoy",
        chainId: 80002,
        urls: {
          apiURL: "https://api-amoy.polygonscan.com/api",
          browserURL: "https://amoy.polygonscan.com/",
        },
      },
      {
        network: "blastSepolia",
        chainId: 168587773,
        urls: {
          apiURL: "https://api-sepolia.blastscan.io/api",
          browserURL: "https://sepolia.blastscan.io/",
        },
      },
    ],
  },
};

export default config;
