// Copyright (C) 2020 Cartesi Pte. Ltd.

// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Note: This component currently has dependencies that are licensed under the GNU
// GPL, version 3, and so you should treat this component as a whole as being under
// the GPL version 3. But all Cartesi-written code in this component is licensed
// under the Apache License, version 2, or a compatible permissive license, and can
// be used independently under the Apache v2 license. After this component is
// rewritten, the entire component will be released under the Apache v2 license.

import {
    BuidlerRuntimeEnvironment,
    DeployFunction
} from "@nomiclabs/buidler/types";
import { useOrDeploy } from "../src/helpers/useOrDeploy";

const func: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
    const { deployments, getNamedAccounts, network } = bre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    // use pre-deployed contracts, or deploy a new one (development/localhost)
    const BitsManipulationLibraryAddress = await useOrDeploy(
        bre,
        deployer,
        "BitsManipulationLibrary"
        );
    const MerkleAddress = await useOrDeploy(bre, deployer, "Merkle");
    const MMInstantiatorAddress = await useOrDeploy(
        bre,
        deployer,
        "MMInstantiator",
        { Merkle: MerkleAddress }
    );

    // deploy machine-solidity-step contracts
    const ShadowAddresses = await deploy("ShadowAddresses", {
        from: deployer,
        log: true
    });
    const RiscVConstants = await deploy("RiscVConstants", {
        from: deployer,
        log: true
    });
    const RiscVDecoder = await deploy("RiscVDecoder", {
        from: deployer,
        libraries: {
            BitsManipulationLibrary: BitsManipulationLibraryAddress
        },
        log: true
    });
    const RealTimeClock = await deploy("RealTimeClock", {
        from: deployer,
        log: true
    });
    const BranchInstructions = await deploy("BranchInstructions", {
        from: deployer,
        libraries: {
            RiscVDecoder: RiscVDecoder.address,
            RiscVConstants: RiscVConstants.address
        },
        log: true
    });
    const ArithmeticInstructions = await deploy("ArithmeticInstructions", {
        from: deployer,
        libraries: {
            RiscVDecoder: RiscVDecoder.address,
            RiscVConstants: RiscVConstants.address
        },
        log: true
    });
    const ArithmeticImmediateInstructions = await deploy(
        "ArithmeticImmediateInstructions",
        {
            from: deployer,
            libraries: {
                RiscVDecoder: RiscVDecoder.address,
                RiscVConstants: RiscVConstants.address
            },
            log: true
        }
    );
    const StandAloneInstructions = await deploy("StandAloneInstructions", {
        from: deployer,
        libraries: {
            RiscVDecoder: RiscVDecoder.address,
            RiscVConstants: RiscVConstants.address
        },
        log: true
    });
    const PMA = await deploy("PMA", {
        from: deployer,
        log: true
    });
    const CSRReads = await deploy("CSRReads", {
        from: deployer,
        libraries: {
            RiscVDecoder: RiscVDecoder.address,
            RiscVConstants: RiscVConstants.address,
            RealTimeClock: RealTimeClock.address
        },
        log: true
    });
    const CLINT = await deploy("CLINT", {
        from: deployer,
        libraries: {
            RiscVConstants: RiscVConstants.address,
            RealTimeClock: RealTimeClock.address
        },
        log: true
    });
    const HTIF = await deploy("HTIF", {
        from: deployer,
        libraries: {
            RiscVConstants: RiscVConstants.address,
            RealTimeClock: RealTimeClock.address
        },
        log: true
    });
    const CSR = await deploy("CSR", {
        from: deployer,
        libraries: {
            RiscVDecoder: RiscVDecoder.address,
            RiscVConstants: RiscVConstants.address,
            RealTimeClock: RealTimeClock.address,
            CSRReads: CSRReads.address
        },
        log: true
    });
    const CSRExecute = await deploy("CSRExecute", {
        from: deployer,
        libraries: {
            RiscVDecoder: RiscVDecoder.address,
            RiscVConstants: RiscVConstants.address,
            RealTimeClock: RealTimeClock.address,
            CSRReads: CSRReads.address,
            CSR: CSR.address
        },
        log: true
    });
    const Exceptions = await deploy("Exceptions", {
        from: deployer,
        libraries: {
            RiscVConstants: RiscVConstants.address
        },
        log: true
    });
    const EnvTrapIntInstructions = await deploy("EnvTrapIntInstructions", {
        from: deployer,
        libraries: {
            RiscVDecoder: RiscVDecoder.address,
            RiscVConstants: RiscVConstants.address,
            Exceptions: Exceptions.address
        },
        log: true
    });
    const VirtualMemory = await deploy("VirtualMemory", {
        from: deployer,
        libraries: {
            RiscVDecoder: RiscVDecoder.address,
            RiscVConstants: RiscVConstants.address,
            ShadowAddresses: ShadowAddresses.address,
            PMA: PMA.address,
            CLINT: CLINT.address,
            HTIF: HTIF.address,
            Exceptions: Exceptions.address
        },
        log: true
    });
    const S_Instructions = await deploy("S_Instructions", {
        from: deployer,
        libraries: {
            RiscVDecoder: RiscVDecoder.address,
            VirtualMemory: VirtualMemory.address
        },
        log: true
    });
    const AtomicInstructions = await deploy("AtomicInstructions", {
        from: deployer,
        libraries: {
            RiscVDecoder: RiscVDecoder.address,
            VirtualMemory: VirtualMemory.address
        },
        log: true
    });
    const Fetch = await deploy("Fetch", {
        from: deployer,
        libraries: {
            RiscVDecoder: RiscVDecoder.address,
            RiscVConstants: RiscVConstants.address,
            ShadowAddresses: ShadowAddresses.address,
            PMA: PMA.address,
            VirtualMemory: VirtualMemory.address,
            Exceptions: Exceptions.address
        },
        log: true
    });
    const Interrupts = await deploy("Interrupts", {
        from: deployer,
        libraries: {
            RiscVConstants: RiscVConstants.address,
            ShadowAddresses: ShadowAddresses.address,
            Exceptions: Exceptions.address
        },
        log: true
    });
    const Execute = await deploy("Execute", {
        from: deployer,
        libraries: {
            BitsManipulationLibrary: BitsManipulationLibraryAddress,
            RiscVDecoder: RiscVDecoder.address,
            RiscVConstants: RiscVConstants.address,
            ShadowAddresses: ShadowAddresses.address,
            BranchInstructions: BranchInstructions.address,
            ArithmeticInstructions: ArithmeticInstructions.address,
            ArithmeticImmediateInstructions:
                ArithmeticImmediateInstructions.address,
            AtomicInstructions: AtomicInstructions.address,
            EnvTrapIntInstructions: EnvTrapIntInstructions.address,
            StandAloneInstructions: StandAloneInstructions.address,
            CSRExecute: CSRExecute.address,
            CSR: CSR.address,
            Exceptions: Exceptions.address,
            S_Instructions: S_Instructions.address,
            VirtualMemory: VirtualMemory.address
        },
        log: true
    });

    // defines which MMInstantiator address to use for MemoryInteractor
    // - default: address of the already deployed MMInstantiator contract
    // - if on ramtest: deploys TestRamMMInstantiator and uses its address
    let mmInstantiatorAddress = MMInstantiatorAddress;
    if (network.name == "ramtest") {
        console.log("    Deploying TestRam contracts...");
        const TestRamMMInstantiator = await deploy("TestRamMMInstantiator", {
            from: deployer,
            libraries: {
                BitsManipulationLibrary: BitsManipulationLibraryAddress,
                Merkle: MerkleAddress
            },
            log: true
        });
        mmInstantiatorAddress = TestRamMMInstantiator.address;
    }


    const MemoryInteractor = await deploy("MemoryInteractor", {
        from: deployer,
        libraries: {
            BitsManipulationLibrary: BitsManipulationLibraryAddress,
            RiscVConstants: RiscVConstants.address,
            ShadowAddresses: ShadowAddresses.address,
            HTIF: HTIF.address,
            CLINT: CLINT.address
        },
        log: true,
    });

    // defines which MemoryInteractor address to use for step
    // - default: address of the already deployed MemoryInteractor contract
    // - if on ramtest: deploys TestMemoryInteractor and uses its address

    let miInstantiatorAddress = MemoryInteractor.address;
    if (network.name == "ramtest") {
        console.log("    Deploying TestRam contracts...");
        const TestMemoryInteractor = await deploy("TestMemoryInteractor", {
            from: deployer,
            libraries: {
                BitsManipulationLibrary: BitsManipulationLibraryAddress,
                Merkle: MerkleAddress
            },
            log: true
        });
        miInstantiatorAddress  = TestMemoryInteractor.address;
    }

    const Step = await deploy("Step", {
        from: deployer,
        libraries: {
            RiscVDecoder: RiscVDecoder.address,
            RiscVConstants: RiscVConstants.address,
            ShadowAddresses: ShadowAddresses.address,
            Fetch: Fetch.address,
            Interrupts: Interrupts.address,
            Execute: Execute.address
        },
        log: true,
        args: [miInstantiatorAddress]
    });
};

export default func;
export const tags = ["Libs"];
