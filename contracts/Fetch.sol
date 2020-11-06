// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./MemoryInteractor.sol";
import "./PMA.sol";
import "./VirtualMemory.sol";
import "./Exceptions.sol";

/// @title Fetch
/// @author Felipe Argento
/// @notice Implements main CSR read and write logic
library Fetch {

    /// @notice Finds and loads next insn.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @return Returns fetchStatus.success if load was successful, excpetion if not.
    /// @return Returns instructions
    /// @return Returns pc
    function fetchInsn(MemoryInteractor mi) public returns (fetchStatus, uint32, uint64) {
        bool translateBool;
        uint64 paddr;

        //readPc
        uint64 pc = mi.readPc();
        (translateBool, paddr) = VirtualMemory.translateVirtualAddress(
            mi,
            pc,
            RiscVConstants.getPteXwrCodeShift()
        );

        //translateVirtualAddress failed
        if (!translateBool) {
            Exceptions.raiseException(
                mi,
                Exceptions.getMcauseFetchPageFault(),
                pc
            );
            //returns fetchException and returns zero as insn and pc
            return (fetchStatus.exception, 0, 0);
        }

        // Finds the range in memory in which the physical address is located
        // Returns start and length words from pma
        uint64 pmaStart = PMA.findPmaEntry(mi, paddr);

        // M flag defines if the pma range is in memory
        // X flag defines if the pma is executable
        // If the pma is not memory or not executable - this is a pma violation
        // Reference: The Core of Cartesi, v1.02 - section 3.2 the board - page 5.
        if (!PMA.pmaGetIstartM(pmaStart) || !PMA.pmaGetIstartX(pmaStart)) {
            Exceptions.raiseException(
                mi,
                Exceptions.getMcauseInsnAccessFault(),
                paddr
            );
            return (fetchStatus.exception, 0, 0);
        }

        uint32 insn = 0;

        // Check if instruction is on first 32 bits or last 32 bits
        if ((paddr & 7) == 0) {
            insn = uint32(mi.memoryRead(paddr));
        } else {
            // If not aligned, read at the last addr and shift to get the correct insn
            uint64 fullMemory = mi.memoryRead(paddr - 4);
            insn = uint32(fullMemory >> 32);
        }

        return (fetchStatus.success, insn, pc);
    }

    enum fetchStatus {
        exception, //failed: exception raised
        success
    }
}
