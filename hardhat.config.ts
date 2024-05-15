import { HardhatUserConfig } from "hardhat/config";
import "hardhat-deploy";
import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";

require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  namedAccounts: {
    deployer: 0,
  },
  networks: {
    bscTestnet: {
      url: process.env.API_URL,
      accounts: [`${process.env.PRIVATE_KEY}`],
    },
  },
};

export default config;
