// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title Step
pragma solidity ^0.7.0;

import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./MemoryInteractor.sol";
import {Fetch} from "./Fetch.sol";
import {Execute} from "./Execute.sol";
import {Interrupts} from "./Interrupts.sol";

/// @title Step
/// @author Felipe Argento
/// @notice State transiction function that takes the machine from state s[i] to s[i + 1]
contract Step {
    event StepGiven(uint8 exitCode);
    event StepStatus(uint64 cycle, bool halt);

    MemoryInteractor mi;

    constructor(address miAddress) {
        mi = MemoryInteractor(miAddress);
    }

    /// @notice Run step define by a MemoryManager instance.
    /// @return Returns an exit code.
    /// @param _rwPositions position of all read and writes
    /// @param _rwValues value of all read and writes
    /// @param _isRead bool specifying if access is a read
    /// @return Returns an exit code and the amount of memory accesses
    function step(
        uint64[] memory _rwPositions,
        bytes8[] memory _rwValues,
        bool[] memory _isRead
    ) public returns (uint8, uint256) {

        mi.initializeMemory(_rwPositions, _rwValues, _isRead);

        // Read mcycle register and make sure it is not about to overflow
        uint64 mcycle = mi.readMcycle();

        if (mcycle >= 2**64-1) {
            // machine can't go forward
            emit StepStatus(0, true);
            return endStep(0);
        }

        // Read iflags register and check its H flag, to see if machine is halted.
        // If machine is halted - nothing else to do. H flag is stored on the least
        // signficant bit on iflags register.
        // Reference: The Core of Cartesi, v1.02 - figure 1.
        uint64 halt = mi.readIflagsH();

        if (halt != 0) {
            //machine is halted
            emit StepStatus(0, true);
            return endStep(0);
        }

        uint64 yield = mi.readIflagsY();

        if (yield != 0) {
             //cpu is yielded
            emit StepStatus(0, true);
            return endStep(0);
        }

        // Just reset the automatic yield flag and continue
        mi.setIflagsX(false);

        // Set interrupt flag for RTC
        Interrupts.setRtcInterrupt(mi, mcycle);

	    //Raise the highest priority interrupt
        Interrupts.raiseInterruptIfAny(mi);

        //Fetch Instruction
        Fetch.fetchStatus fetchStatus;
        uint64 pc;
        uint32 insn;

        (fetchStatus, insn, pc) = Fetch.fetchInsn(mi);

        if (fetchStatus == Fetch.fetchStatus.success) {
            // If fetch was successfull, tries to execute instruction
            if (Execute.executeInsn(
                    mi,
                    insn,
                    pc
                ) == Execute.executeStatus.retired
               ) {
                // If executeInsn finishes successfully we need to update the number of
                // retired instructions. This number is stored on minstret CSR.
                // Reference: riscv-priv-spec-1.10.pdf - Table 2.5, page 12.
                uint64 minstret = mi.readMinstret();
                mi.writeMinstret(minstret + 1);
            }
        }
        // Last thing that has to be done in a step is to update the cycle counter.
        // The cycle counter is stored on mcycle CSR.
        // Reference: riscv-priv-spec-1.10.pdf - Table 2.5, page 12.
        mcycle = mi.readMcycle();
        mi.writeMcycle(mcycle + 1);
        emit StepStatus(mcycle + 1, false);

        return endStep(0);
    }

    function getMemoryInteractor() public view returns (address) {
        return address(mi);
    }

    function endStep(uint8 exitCode) internal returns (uint8, uint256) {
        emit StepGiven(exitCode);

        return (exitCode, mi.getRWIndex());
    }
}
