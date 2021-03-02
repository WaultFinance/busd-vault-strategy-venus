import { task } from 'hardhat/config';
import { tsGenerator } from 'ts-generator';
import { TypeChain } from 'typechain/dist/TypeChain';

task('compile', 'Compiles the entire project, building all artifacts and typechain', async function(taskArguments, hre, runSuper) {
    await runSuper();

    const cwd = process.cwd();

    await tsGenerator(
        { cwd },
        new TypeChain({
        cwd,
        rawConfig: {
            files: './artifacts/contracts/**//+([a-zA-Z0-9]).json',
            target: 'ethers-v5'
        }
        })
    );
});