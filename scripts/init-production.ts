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
        "Initialize contracts with the account:",
        deployer.address
    );

    const beforeBalance = await deployer.getBalance();
    console.log("Account balance:", (await deployer.getBalance()).toString());

    const mainnet = process.env.NETWORK == "mainnet" ? true : false;
    const busdAddress = mainnet ? process.env.BUSD_MAIN : process.env.BUSD_TEST;
    const waultAddress = mainnet ? process.env.WAULT_MAIN : process.env.WAULT_TEST;
    const controllerAddress = mainnet ? process.env.CONTROLLER_MAIN : process.env.CONTROLLER_TEST;
    const vaultAddress = mainnet ? process.env.VAULT_MAIN : process.env.VAULT_TEST;
    const strategyAddress = mainnet ? process.env.STRATEGY_MAIN : process.env.STRATEGY_TEST;
    
    const controllerFactory: Controller__factory = new Controller__factory(deployer);
    const WaultBusdVaultFactory: WaultBusdVault__factory = new WaultBusdVault__factory(deployer);
    const strategyVenusFactory: StrategyVenusBusd__factory = new StrategyVenusBusd__factory(deployer);

    const controller: Controller = controllerFactory.attach(controllerAddress).connect(deployer);
    const vault: WaultBusdVault = WaultBusdVaultFactory.attach(vaultAddress).connect(deployer);
    const strategyVenus: StrategyVenusBusd = strategyVenusFactory.attach(strategyAddress).connect(deployer);

    console.log("BUSD Vault address:", vault.address);
    console.log("StrategyVenus address:", strategyVenus.address);
    console.log("Controller address:", controller.address);
    
    console.log("Setting vault address to controller...");
    await controller.setVault(busdAddress, vault.address);
    console.log("Setting strategy address to controller...");
    await controller.setStrategy(busdAddress, strategyVenus.address);

    console.log("Entering to Venus market...");
    await strategyVenus.enterVenusMarket();
    
    console.log("Setting address to send rewards from strategy...");
    await controller.setRewards(process.env.REWARDS_ADDR);
    console.log("Setting marketer address...");
    await controller.setMarketer(process.env.MARKETER_ADDR);
    // console.log("Setting harvester address...");
    // await strategyVenus.setHarvester(process.env.HARVESTER_ADDR);
    // console.log("Setting governance...");
    // await controller.setGovernance(deployer.address);
    // await vault.setGovernance(deployer.address);
    // await strategyVenus.setGovernance(deployer.address);

    console.log("Initialized Controller...");
    
    const afterBalance = await deployer.getBalance();
    console.log(
        "Cost:",
         (beforeBalance.sub(afterBalance)).toString()
    );
}

deploy()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    })