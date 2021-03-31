import * as hre from 'hardhat';
import { Wault } from '../types/ethers-contracts/Wault';
import { Wault__factory } from '../types/ethers-contracts/factories/Wault__factory';
require("dotenv").config();

const { ethers } = hre;

const sleep = (milliseconds, msg='') => {
    console.log(`Wait ${milliseconds} ms... (${msg})`);
    const date = Date.now();
    let currentDate = null;
    do {
      currentDate = Date.now();
    } while (currentDate - date < milliseconds);
}

const toEther = (val) => {
    return ethers.utils.formatEther(val);
}

async function deploy() {
    console.log((new Date()).toLocaleString());
    
    const [deployer] = await ethers.getSigners();
    
    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );

    const beforeBalance = await deployer.getBalance();
    console.log("Account balance:", (await deployer.getBalance()).toString());

    const mainnet = process.env.NETWORK == "mainnet" ? true : false;
    if (mainnet) {
        console.log("Already exist WAULT token =>", process.env.WAULT_MAIN);
    } else {
        const waultFactory: Wault__factory = new Wault__factory(deployer);
        const wault: Wault = await waultFactory.deploy();
        console.log(`Deployed WAULT... (${wault.address})`);
    }
    
    const afterBalance = await deployer.getBalance();
    console.log(
        "Deployed cost:",
         (beforeBalance.sub(afterBalance)).toString()
    );
}

deploy()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    })