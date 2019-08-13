// Copyright 2019 Cartesi Pte. Ltd.

// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title Step
pragma solidity ^0.5.0;

import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "../contracts/MemoryInteractor.sol";
import {Fetch} from "../contracts/Fetch.sol";
import {Execute} from "../contracts/Execute.sol";
import {Interrupts} from "../contracts/Interrupts.sol";

/// @title Step
/// @author Felipe Argento
/// @notice State transiction function that takes the machine from state s[i] to s[i + 1]
contract Step {
    event StepGiven(uint8 exitCode);
    event StepStatus(uint64 cycle, bool halt);

    MemoryInteractor mi;

    constructor(address miAddress) public {
        mi = MemoryInteractor(miAddress);
    }

    /// @notice Run step define by a MemoryManager instance.
    /// @param mmIndex Specific index of the Memory Manager that contains this Step's access logs
    /// @return Returns an exit code.
    function step(uint mmIndex) public returns (uint8) {
        // Read iflags register and check its H flag, to see if machine is halted.
        // If machine is halted - nothing else to do. H flag is stored on the least
        // signficant bit on iflags register.
        // Reference: The Core of Cartesi, v1.02 - figure 1.
        uint64 iflags = mi.readIflags(mmIndex);

        if ((iflags & 1) != 0) {
            //machine is halted
            emit StepStatus(0, true);
            return endStep(mmIndex, 0);
        }
        //Raise the highest priority interrupt
        Interrupts.raiseInterruptIfAny(mmIndex, mi);

        //Fetch Instruction
        Fetch.fetchStatus fetchStatus;
        uint64 pc;
        uint32 insn;

        (fetchStatus, insn, pc) = Fetch.fetchInsn(mmIndex, mi);

        if (fetchStatus == Fetch.fetchStatus.success) {
            // If fetch was successfull, tries to execute instruction
            if (Execute.executeInsn(
                    mmIndex,
                    mi,
                    insn,
                    pc
                ) == Execute.executeStatus.retired
               ) {
                // If executeInsn finishes successfully we need to update the number of
                // retired instructions. This number is stored on minstret CSR.
                // Reference: riscv-priv-spec-1.10.pdf - Table 2.5, page 12.
                uint64 minstret = mi.readMinstret(mmIndex);
                mi.writeMinstret(mmIndex, minstret + 1);
            }
        }
        // Last thing that has to be done in a step is to update the cycle counter.
        // The cycle counter is stored on mcycle CSR.
        // Reference: riscv-priv-spec-1.10.pdf - Table 2.5, page 12.
        uint64 mcycle = mi.readMcycle(mmIndex);
        mi.writeMcycle(mmIndex, mcycle + 1);
        emit StepStatus(mcycle + 1, false);

        return endStep(mmIndex, 0);
    }

    function getMemoryInteractor() public view returns (address) {
        return address(mi);
    }

    function endStep(uint256 mmIndex, uint8 exitCode) internal returns (uint8) {
        mi.finishReplayPhase(mmIndex);
        emit StepGiven(exitCode);
        return exitCode;
    }

}
