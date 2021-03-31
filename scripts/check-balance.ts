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

const parseEther = (val) => {
    return ethers.utils.parseEther(val);
}

const toEther = (val) => {
    return ethers.utils.formatEther(val);
}

async function deploy() {
    console.log((new Date()).toLocaleString());

    const [deployer] = await ethers.getSigners();
    
    console.log(
        "Testing contracts with the account:",
        deployer.address
    );

    const beforeBalance = await deployer.getBalance();
    console.log("Account balance:", toEther(await deployer.getBalance()).toString());

    const mainnet = process.env.NETWORK == "mainnet" ? true : false;
    const rewardsAddress = process.env.REWARDS_ADDR;
    const waultAddress = mainnet ? process.env.WAULT_MAIN : process.env.WAULT_TEST;
    const xvsAddress = mainnet ? process.env.XVS_MAIN : process.env.XVS_TEST;
    const busdAddress = mainnet ? process.env.BUSD_MAIN : process.env.BUSD_TEST;
    const controllerAddress = mainnet ? process.env.CONTROLLER_MAIN : process.env.CONTROLLER_TEST;
    const vaultAddress = mainnet ? process.env.VAULT_MAIN : process.env.VAULT_TEST;
    const strategyAddress = mainnet ? process.env.STRATEGY_MAIN : process.env.STRATEGY_TEST;

    const erc20Factory = new ERC20__factory(deployer);
    const busd = erc20Factory.attach(busdAddress).connect(deployer);
    const xvs = erc20Factory.attach(xvsAddress).connect(deployer);

    const controllerFactory: Controller__factory = new Controller__factory(deployer);
    const WaultBusdVaultFactory: WaultBusdVault__factory = new WaultBusdVault__factory(deployer);
    const strategyVenusFactory: StrategyVenusBusd__factory = new StrategyVenusBusd__factory(deployer);

    let controller: Controller = controllerFactory.attach(controllerAddress).connect(deployer);
    let wBUSD: WaultBusdVault = WaultBusdVaultFactory.attach(vaultAddress).connect(deployer);
    let strategyVenus: StrategyVenusBusd = strategyVenusFactory.attach(strategyAddress).connect(deployer);

    console.log("BUSD Vault address:", wBUSD.address);
    console.log("StrategyVenus address:", strategyVenus.address);
    console.log("Controller address:", controller.address);

    const _performanceFee = (await strategyVenus._performanceFee()).toString();
    console.log("Performance Fee: ", _performanceFee);
    console.log("Total Fee: ", (await strategyVenus.totalFee()).toString());

    const supplyRatePerBlock = (await strategyVenus.supplyRatePerBlock()).toString();
    console.log("Supply Rate per Block: ", supplyRatePerBlock);
    const borrowRatePerBlock = (await strategyVenus.borrowRatePerBlock()).toString();
    console.log("Borrow Rate per Block: ", borrowRatePerBlock);
    console.log("Supply Venus Rate per Block:", (await strategyVenus.supplyRewardRatePerBlock()).toString());
    console.log("Borrow Venus Rate per Block:", (await strategyVenus.borrowRewardRatePerBlock()).toString());
    console.log("Price of Venus:", (await strategyVenus.priceOfVenus()).toString());

    let balanceOf = (await strategyVenus.balanceOf()).toString();
    console.log("balanceOfStrategy: ", balanceOf);
    console.log('totalSupply: ', (await wBUSD.totalSupply()).toString());
    //console.log("userCount: ", (await controller.userCount(busdAddress)).toString());
    
    console.log("lastHarvestedTime: ", (await strategyVenus.lastHarvestedTime()).toString());
    console.log("lastHarvestedBlock: ", (await strategyVenus.lastHarvestedBlock()).toString());
    console.log("lastAvgSupplyBalance: ", (await strategyVenus.lastAvgSupplyBalance()).toString());
    console.log("harvestFee: ", (await strategyVenus.harvestFee()).toString());
    console.log("expectedHarvestRewards: ", (await strategyVenus.expectedHarvestRewards()).toString());
    console.log("XVS Balance of rewarder: ", (await xvs.balanceOf(rewardsAddress)).toString());

    console.log("currentWaultSupply: ", (await controller.currentWaultSupply()).toString());
    console.log("startForDistributeWault: ", (await controller.startForDistributeWault()).toString());
    console.log("endForDistributeWault: ", (await controller.endForDistributeWault()).toString());
    console.log("lastDistributedBlock: ", (await controller.lastDistributedBlock()).toString());
    console.log("Balance of Wault: ", (await controller.balanceOfWault()).toString());
    console.log("Balance of marketer rewards: ", (await controller.balanceOfMarketer(busdAddress)).toString());
    console.log("Balance of strategist rewards: ", (await controller.balanceOfStrategist(busdAddress)).toString());
    console.log("User List...");
    const users = await controller.userList(busdAddress);
    users.map(user => console.log(user));
    if ("CHECK USER" && true) {
        // const user = deployer.address;
        // const user = '0x3d09b0e96904c71afb02013641181aaf99927618';
        const user = '0xC627D743B1BfF30f853AE218396e6d47a4f34ceA';
        // const user = '0x999e77396e78e0b842f2b4622e3ef3164218b7a6';
        console.log(`Check user rewards... (${user})`);
        let userInfo = (await controller.userInfo(busd.address, user));
        //console.log("User reward info: ", userInfo);
        console.log("User reward info(shares): ", userInfo['_shares'].toString());
        console.log("User reward info(reward): ", userInfo['_reward'].toString());
        console.log("User reward info(wault): ", userInfo['_waultReward'].toString());
        console.log("User reward info(lastBlock): ", userInfo['_lastRewardedBlock'].toString());
        console.log("User reward info(lastSupplyRate): ", userInfo['_lastSupplyRate'].toString());
        console.log("User reward info(lastBorrowRate): ", userInfo['_lastBorrowRate'].toString());
        console.log("User reward info(lastSupplyRewardRate): ", userInfo['_lastSupplyRewardRate'].toString());
        console.log("User reward info(lastBorrowRewardRate): ", userInfo['_lastBorrowRewardRate'].toString());
        const rewards = await wBUSD.balanceOfRewards(user);
        console.log("User reward from Vault(_reards): ", rewards['_rewards'].toString());
        console.log("User reward from Vault(_waults): ", rewards['_waults'].toString());
    }
    const totalRewards = await controller.totalRewards(busdAddress);
    console.log("totalRewards(harvest): ", totalRewards['_harvestRewards'].toString());
    console.log("totalRewards(wault): ", totalRewards['_waultRewards'].toString());

    const afterBalance = await deployer.getBalance();
    console.log(
        "Tested cost:",
         (beforeBalance.sub(afterBalance)).toString()
    );
}

deploy()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    })