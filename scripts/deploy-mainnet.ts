import * as hre from 'hardhat';
import { Controller } from '../types/ethers-contracts/Controller';
import { Controller__factory } from '../types/ethers-contracts/factories/Controller__factory';
import { WaultBusdVault } from '../types/ethers-contracts/WaultBusdVault';
import { WaultBusdVault__factory } from '../types/ethers-contracts/factories/WaultBusdVault__factory';
import { StrategyVenusBusd } from '../types/ethers-contracts/StrategyVenusBusd';
import { StrategyVenusBusd__factory } from '../types/ethers-contracts/factories/StrategyVenusBusd__factory';
import { ERC20__factory } from '../types/ethers-contracts/factories/ERC20__factory';
import { assert } from 'sinon';

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

const parseEther = (val) => {
    return ethers.utils.parseEther(val);
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
    const busdAddress = mainnet ? process.env.BUSD_MAIN : process.env.BUSD_TEST;
    const rewardsAddress = process.env.REWARDS_ADDR;
    const waultAddress = mainnet ? process.env.WAULT_MAIN : process.env.WAULT_TEST;
    
    const erc20Factory = new ERC20__factory(deployer);
    const busd = erc20Factory.attach(busdAddress).connect(deployer);
    const wault = erc20Factory.attach(waultAddress).connect(deployer);

    const controllerFactory: Controller__factory = new Controller__factory(deployer);
    const WaultBusdVaultFactory: WaultBusdVault__factory = new WaultBusdVault__factory(deployer);
    const strategyVenusFactory: StrategyVenusBusd__factory = new StrategyVenusBusd__factory(deployer);

    const controller: Controller = await controllerFactory.deploy();
    console.log("Deployed Controller...");
    const vault: WaultBusdVault = await WaultBusdVaultFactory.deploy(busd.address, controller.address);
    console.log("Deployed Vault...");
    const strategyVenus: StrategyVenusBusd = await strategyVenusFactory.deploy(controller.address);
    console.log("Deployed Strategy...");

    if (!mainnet) {
        await strategyVenus.enableTestnet();
        await controller.enableTestnet();
    }
    await strategyVenus.enterVenusMarket();

    console.log("Setting address to send rewards from strategy...");
    await controller.setRewards(rewardsAddress);
    console.log("Setting vault address to controller...");
    await controller.setVault(busdAddress, vault.address);
    console.log("Setting strategy address to controller...");
    await controller.setStrategy(busdAddress, strategyVenus.address);
    console.log("Send 1000 Wault to controller...");
    await wault.transfer(controller.address, parseEther('1000'));
    if (!mainnet) {
        console.log("Disable router of strategy...");
        await strategyVenus.disableRouter();
        console.log("Setting rewards to send as original BUSD...");
        await controller.setSendAsOrigin(true);
        console.log("Setting borrow limit...");
        await strategyVenus.setTargetBorrowLimit(parseEther('0.79'), parseEther('0.01'));
    }
    console.log("Setting minimum deposit amount to 5 BUSD...");
    await vault.setMin(5);
    console.log("Initialized Contracts...");

    // console.log("Setting strategist...");
    // await controller.setGovernance(deployer.address);
    // await vault.setGovernance(deployer.address);
    // await strategyVenus.setGovernance(deployer.address);
    
    console.log("BUSD Vault address:", vault.address);
    console.log("StrategyVenus address:", strategyVenus.address);
    console.log("Controller address:", controller.address);
    
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