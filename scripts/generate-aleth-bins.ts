import fs from "fs";
import path from "path";
import hre from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployOptions, DeployResult } from "hardhat-deploy/types";

import libDeploymentFn from "../deploy/01_libs";

const OUTDIR = process.env.OUTDIR || "./build";

async function saveFile(
    fileName: string,
    data: any,
    isJson = true
): Promise<string> {
    const parsedData = isJson ? JSON.stringify(data) : data;
    const p = new Promise<string>((resolve, reject) => {
        fs.writeFile(path.join(OUTDIR, fileName), parsedData, err => {
            if (err) return reject(err);
            resolve("done");
        });
    });
    return p;
}

function changeContract(
    contractList: Array<string>,
    target: string,
    newName: string
): Array<string> {
    const idx = contractList.findIndex(value => value === target);
    if (idx == -1) return contractList;
    const copy = [...contractList];
    copy[idx] = newName;
    return copy;
}

async function saveRunContractsConfig(contractList: Array<string>) {
    const list = changeContract(
        contractList,
        "MemoryInteractor",
        "TestMemoryInteractor"
    ).map(value => `${value}.bin`);
    const config = {
        path: path.resolve(OUTDIR) + "/",
        contracts: list
    };
    await saveFile("run_contracts.json", config);
}

async function saveSequenceContractsConfig(contractList: Array<string>) {
    const list = contractList.map(value => `${value}.bin`);
    const config = {
        path: path.resolve(OUTDIR) + "/",
        contracts: list
    };
    await saveFile("sequence_contracts.json", config);
}

async function getDataByHash(
    hre: HardhatRuntimeEnvironment,
    hash: string
): Promise<string> {
    const tx = await hre.ethers.provider.send("eth_getTransactionByHash", [
        hash
    ]);
    return tx.input;
}

async function main() {
    const breDeploy = hre.deployments.deploy;
    const contractsOrder: Array<string> = [];
    const addresses: { [key: string]: string } = {};
    const { deployer } = await hre.getNamedAccounts();
    addresses.sender = deployer;

    hre.deployments.deploy = async (
        name: string,
        options: DeployOptions
    ): Promise<DeployResult> => {
        const result = await breDeploy(name, options);

        contractsOrder.push(name);
        addresses[name] = result.address;
        if (!result.deployedBytecode || !result.transactionHash) {
            console.error(
                `Error trying to compile ${name}. No bytecode created.`
            );
            process.exit(-1);
        }
        const data = await getDataByHash(hre, result.transactionHash);
        await saveFile(`${name}.bin`, data.slice(2), false);
        console.log("saved", `${name}.bin`);

        return result;
    };
    await libDeploymentFn(hre);

    // save addresses file
    await saveFile("addresses.json", addresses);
    // build and save run_contracts.json
    await saveRunContractsConfig(contractsOrder);

    await saveSequenceContractsConfig(contractsOrder);

    // Deploy instrumental contracts
    await hre.deployments.deploy("TestMemoryInteractor", {
        from: deployer,
        libraries: {
            BitsManipulationLibrary: addresses.BitsManipulationLibrary,
            RiscVConstants: addresses.RiscVConstants,
            ShadowAddresses: addresses.ShadowAddresses,
            HTIF: addresses.HTIF,
            CLINT: addresses.CLINT
        },
        log: true
    });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
