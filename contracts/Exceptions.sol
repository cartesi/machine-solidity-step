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

import "./MemoryInteractor.sol";
import "./RiscVConstants.sol";

/// @title Exceptions
/// @author Felipe Argento
/// @notice Implements raise exception behavior and mcause getters
library Exceptions {

    /// @notice Raise an exception (or interrupt).
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param cause Exception (or interrupt) mcause (or scause).
    /// @param tval Associated tval.
    function raiseException(
        MemoryInteractor mi,
        uint64 cause,
        uint64 tval)
    public
    {
        // All traps are handled in machine-mode, by default. Mideleg or Medeleg provide
        // bits to indicate if the interruption/exception should be taken care of by
        // lower privilege levels.
        // Medeleg -> Machine Exception Delegation register
        // Mideleg -> Machine Interrupt Delegation register
        // Reference: riscv-privileged-v1.9.1.pdf - Section 3.1.12, page 28.
        uint64 deleg = 0;
        uint64 priv = mi.readIflagsPrv();

        if (priv <= RiscVConstants.getPrvS()) {
            if ((cause & getMcauseInterruptFlag()) != 0) {
                // If exception was caused by an interruption the delegated information is
                // stored on mideleg register.

                // Clear the MCAUSE_INTERRUPT_FLAG() bit before shifting
                deleg = (mi.readMideleg() >> (cause & uint64(RiscVConstants.getXlen() - 1))) & 1;
            } else {
                //If not, information is in the medeleg register
                deleg = (mi.readMedeleg() >> cause) & 1;
            }
        }
        if (deleg != 0) {
            //is in S mode

            // SCAUSE - Supervisor Cause Register
            // Register containg Interrupt bit (shows if the exception was cause by an interrupt
            // and the Exception code, that identifies the last exception
            // The execption codes can be seen at table 4.1
            // Reference: riscv-privileged-v1.9.1.pdf - Section 4.1.8, page 51.
            mi.writeScause(cause);

            // SEPC - Supervisor Exception Program Counter
            // When a trap is taken, sepc is written with the address of the instruction
            // the encountered the exception.
            // Reference: riscv-privileged-v1.9.1.pdf - Section 4.1.7, page 50.
            mi.writeSepc(mi.readPc());

            // STVAL - Supervisor Trap Value
            // stval is written with exception-specific information, when a trap is
            // taken into S-Mode. The specific values can be found in Reference.
            // Reference: riscv-privileged-v1.10.pdf - Section 4.1.11, page 55.
            mi.writeStval(tval);

            // MSTATUS - Machine Status Register
            // keeps track of and controls hart's current operating state.
            // Reference: riscv-privileged-v1.10.pdf - Section 3.1.16, page 19.
            uint64 mstatus = mi.readMstatus();

            // The SPIE bit indicates whether supervisor interrupts were enabled prior
            // to trapping into supervisor mode. When a trap is taken into supervisor
            // mode, SPIE is set to SIE, and SIE is set to 0. When an SRET instruction
            // is executed, SIE is set to SPIE, then SPIE is set to 1.
            // Reference: riscv-privileged-v1.10.pdf - Section 4.1.1, page 19.
            mstatus = (mstatus & ~RiscVConstants.getMstatusSpieMask()) | (((mstatus >> RiscVConstants.getPrvS()) & 1) << RiscVConstants.getMstatusSpieShift());

            // The SPP bit indicates the privilege level at which a hart was executing
            // before entering supervisor mode. When a trap is taken, SPP is set to 0
            // if the trap originated from user mode, or 1 otherwise.
            // Reference: riscv-privileged-v1.10.pdf - Section 4.1.1, page 49.
            mstatus = (mstatus & ~RiscVConstants.getMstatusSppMask()) | (priv << RiscVConstants.getMstatusSppShift());

            // The SIE bit enables or disables all interrupts in supervisor mode.
            // When SIE is clear, interrupts are not taken while in supervisor mode.
            // When the hart is running in user-mode, the value in SIE is ignored, and
            // supervisor-level interrupts are enabled. The supervisor can disable
            // indivdual interrupt sources using the sie register.
            // Reference: riscv-privileged-v1.10.pdf - Section 4.1.1, page 50.
            mstatus &= ~RiscVConstants.getMstatusSieMask();

            mi.writeMstatus(mstatus);

            // TO-DO: Check gas cost to delegate function to library - if its zero the
            // if check should move to setPriv()
            if (priv != RiscVConstants.getPrvS()) {
                mi.setPriv(RiscVConstants.getPrvS());
            }
            // SVEC - Supervisor Trap Vector Base Address Register
            mi.writePc(mi.readStvec());
        } else {
            // is in M mode
            mi.writeMcause(cause);
            mi.writeMepc(mi.readPc());
            mi.writeMtval(tval);
            uint64 mstatus = mi.readMstatus();

            mstatus = (mstatus & ~RiscVConstants.getMstatusMpieMask()) | (((mstatus >> RiscVConstants.getPrvM()) & 1) << RiscVConstants.getMstatusMpieShift());
            mstatus = (mstatus & ~RiscVConstants.getMstatusMppMask()) | (priv << RiscVConstants.getMstatusMppShift());

            mstatus &= ~RiscVConstants.getMstatusMieMask();
            mi.writeMstatus(mstatus);

            // TO-DO: Check gas cost to delegate function to library - if its zero the
            // if check should move to setPriv()
            if (priv != RiscVConstants.getPrvM()) {
                mi.setPriv(RiscVConstants.getPrvM());
            }
            mi.writePc(mi.readMtvec());
        }
    }

    function getMcauseInsnAddressMisaligned() public pure returns(uint64) {return 0x0;}
    function getMcauseInsnAccessFault() public pure returns(uint64) {return 0x1;}
    function getMcauseIllegalInsn() public pure returns(uint64) {return 0x2;}
    function getMcauseBreakpoint() public pure returns(uint64) {return 0x3;}
    function getMcauseLoadAddressMisaligned() public pure returns(uint64) {return 0x4;}
    function getMcauseLoadAccessFault() public pure returns(uint64) {return 0x5;}
    function getMcauseStoreAmoAddressMisaligned () public pure returns(uint64) {return 0x6;}
    function getMcauseStoreAmoAccessFault() public pure returns(uint64) {return 0x7;}
    function getMcauseEcallBase() public pure returns(uint64) {return 0x8;}
    function getMcauseFetchPageFault() public pure returns(uint64) {return 0xc;}
    function getMcauseLoadPageFault() public pure returns(uint64) {return 0xd;}
    function getMcauseStoreAmoPageFault() public pure returns(uint64) {return 0xf;}

    function getMcauseInterruptFlag() public pure returns(uint64) {return uint64(1) << uint64(RiscVConstants.getXlen() - 1);}

}
