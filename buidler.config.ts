import fs from "fs";
import { Wallet } from "@ethersproject/wallet";
import { BuidlerConfig, task, usePlugin } from "@nomiclabs/buidler/config";
import { HttpNetworkConfig } from "@nomiclabs/buidler/types";

usePlugin("@nomiclabs/buidler-ethers");
usePlugin("@nomiclabs/buidler-waffle");
usePlugin("@nodefactory/buidler-typechain");
usePlugin("buidler-deploy");

// This is a sample Buidler task. To learn how to create your own go to
// https://buidler.dev/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, bre) => {
    const accounts = await bre.ethers.getSigners();

    for (const account of accounts) {
        console.log(await account.getAddress());
    }
});

// read MNEMONIC from file or from env variable
let mnemonic = process.env.MNEMONIC;
try {
    mnemonic = fs
        .readFileSync(process.env.MNEMONIC_PATH || ".mnemonic")
        .toString();
} catch (e) {}

// create a Buidler EVM account array from mnemonic
const mnemonicAccounts = (n = 10) => {
    return mnemonic
        ? Array.from(Array(n).keys()).map(i => {
              const wallet = Wallet.fromMnemonic(
                  mnemonic as string,
                  `m/44'/60'/0'/0/${i}`
              );
              return {
                  privateKey: wallet.privateKey,
                  balance: "1000000000000000000000"
              };
          })
        : undefined;
};

const infuraNetwork = (
    network: string,
    chainId?: number,
    gas?: number
): HttpNetworkConfig => {
    return {
        url: `https://${network}.infura.io/v3/${process.env.PROJECT_ID}`,
        chainId,
        gas,
        accounts: mnemonic ? { mnemonic } : undefined
    };
};

const config: BuidlerConfig = {
    networks: {
        buidlerevm: mnemonic ? { accounts: mnemonicAccounts() } : {},
        localhost: {
            url: "http://localhost:8545",
            accounts: mnemonic ? { mnemonic } : undefined
        },
        ropsten: infuraNetwork("ropsten", 3, 6283185),
        rinkeby: infuraNetwork("rinkeby", 4, 6283185),
        kovan: infuraNetwork("kovan", 42, 6283185),
        goerli: infuraNetwork("goerli", 5, 6283185),
        matic_testnet: {
            url: "https://rpc-mumbai.matic.today",
            chainId: 80001,
            accounts: mnemonic ? { mnemonic } : undefined
        },
        bsc_testnet: {
            url: "https://data-seed-prebsc-1-s1.binance.org:8545",
            chainId: 97,
            accounts: mnemonic ? { mnemonic } : undefined
        }   
    },
    solc: {
        version: "0.7.1",
        optimizer: {
            enabled: true
        }
    },
    paths: {
        artifacts: "artifacts",
        deploy: "deploy",
        deployments: "deployments"
    },
    external: {
        artifacts: ["node_modules/@cartesi/util/artifacts"],
        deployments: {
            localhost: ["node_modules/@cartesi/util/deployments/localhost"],
            ropsten: ["node_modules/@cartesi/util/deployments/ropsten"],
            rinkeby: ["node_modules/@cartesi/util/deployments/rinkeby"],
            kovan: ["node_modules/@cartesi/util/deployments/kovan"],
            goerli: ["node_modules/@cartesi/util/deployments/goerli"],
            matic_testnet: ["node_modules/@cartesi/util/deployments/matic_testnet"],
            bsc_testnet: ["node_modules/@cartesi/util/deployments/bsc_testnet"]
        }
    },    
    typechain: {
        outDir: "src/types",
        target: "ethers-v5"
    },
    namedAccounts: {
        deployer: {
            default: 0
        },
        alice: {
            default: 0
        },
        proxy: {
            default: 1
        }
    }
};

export default config;
