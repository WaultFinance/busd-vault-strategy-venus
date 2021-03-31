import { task } from "hardhat/config";
import "./tasks/compile";
import "@nomiclabs/hardhat-waffle";
require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (args, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

// const MNEMONIC_DV_TEST_WALLET = "van stage squirrel urge birth junior advice build slab jelly captain curve";
const MNEMONIC_DV_TEST_WALLET = process.env.MNEMONIC_DV_TEST_WALLET;

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
    solidity: {
        version: "0.8.1",
        settings: {
            optimizer: {
                enabled: true,
            },
        },
    },
    networks: {
        testnet: {
            url: "https://data-seed-prebsc-2-s3.binance.org:8545/",
            chainId: 97,
            gas: 40000000,
            blockGasLimit: 9500000,
            gasPrice: 20000000000,
            accounts: { mnemonic: MNEMONIC_DV_TEST_WALLET },
        },
        hardhat: {
          forking: {
            url: "https://data-seed-prebsc-2-s3.binance.org:8545/"
          },
          accounts: { mnemonic: MNEMONIC_DV_TEST_WALLET },
        },
        mainnet: {
            // url: "https://bsc-dataseed.binance.org/",
            url: "https://bsc-dataseed1.ninicoin.io/",
            // url: "https://bsc-dataseed1.defibit.io/",
            chainId: 56,
            gas: 40000000,
            blockGasLimit: 9500000,
            gasPrice: 20000000000,
            accounts: { mnemonic: MNEMONIC_DV_TEST_WALLET },
        }
    },
    etherscan: {
        // Your API key for Etherscan
        // Obtain one at https://bscscan.com/
        apiKey: process.env.API_KEY,
    },
};