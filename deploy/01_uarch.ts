// Copyright 2023 Cartesi Pte. Ltd.

// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction, DeployOptions } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts, network } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const deterministicDeployment = network.name !== "iotex_testnet";

    const opts: DeployOptions = {
        deterministicDeployment,
        from: deployer,
        log: true,
    }

    const AccessLogs = await deploy("AccessLogs", {
        ...opts,
    });

    const UArchState = await deploy("UArchState", {
        ...opts,
        libraries: {
            ["AccessLogs"]: AccessLogs.address,
        },
    });

    await deploy("UArchStep", {
        ...opts
    });
};

func.tags = ["UArch"];
export default func;
