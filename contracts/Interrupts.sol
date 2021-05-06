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
import "./Exceptions.sol";
import "./RealTimeClock.sol";

/// @title Interrupts
/// @author Felipe Argento
/// @notice Implements interrupt behaviour
library Interrupts {

    /// @notice At every tick, set interrupt as pending if the timer is expired
    /// @param mi Memory Interactor with which Step function is interacting.
    function setRtcInterrupt(MemoryInteractor mi, uint64 mcycle) public {
        if (RealTimeClock.rtcIsTick(mcycle)) {
            uint64 timecmp = mi.readClintMtimecmp();
            uint64 timecmpCycle = RealTimeClock.rtcTimeToCycle(timecmp);
            if (timecmpCycle <= mcycle && timecmpCycle != 0) {
                uint64 mip = mi.readMip();
                mi.writeMip(mip | RiscVConstants.getMipMtipMask());
            }
        }
    }

    /// @notice Raises an interrupt if any are enabled and pending.
    /// @param mi Memory Interactor with which Step function is interacting.
    function raiseInterruptIfAny(MemoryInteractor mi) public {
        uint32 mask = getPendingIrqMask(mi);
        if (mask != 0) {
            uint64 irqNum = ilog2(mask);
            Exceptions.raiseException(
                mi,
                irqNum | Exceptions.getMcauseInterruptFlag(),
                0
            );
        }
    }

    // Machine Interrupt Registers: mip and mie.
    // mip register contains information on pending interrupts.
    // mie register contains the interrupt enabled bits.
    // Reference: riscv-privileged-v1.10 - section 3.1.14 - page 28.
    function getPendingIrqMask(MemoryInteractor mi) internal returns (uint32) {
        uint64 mip = mi.readMip();
        uint64 mie = mi.readMie();

        uint32 pendingInts = uint32(mip & mie);
        // if there are no pending interrupts, return 0.
        if (pendingInts == 0) {
            return 0;
        }
        uint64 mstatus = 0;
        uint32 enabledInts = 0;

        // Read privilege level on iflags register.
        // The privilege level is represented by bits 2 and 3 on iflags register.
        // Reference: The Core of Cartesi, v1.02 - figure 1.
        uint64 priv = mi.readIflagsPrv();

        if (priv == RiscVConstants.getPrvM()) {
            // MSTATUS is the Machine Status Register - it controls the current
            // operating state. The MIE is an interrupt-enable bit for machine mode.
            // MIE for 64bit is stored on location 3 - according to:
            // Reference: riscv-privileged-v1.10 - figure 3.7 - page 20.
            mstatus = mi.readMstatus();

            if ((mstatus & RiscVConstants.getMstatusMieMask()) != 0) {
                enabledInts = uint32(~mi.readMideleg());
            }
        } else if (priv == RiscVConstants.getPrvS()) {
            // MIDELEG: Machine trap delegation register
            // mideleg defines if a interrupt can be proccessed by a lower privilege
            // level. If mideleg bit is set, the trap will delegated to the S-Mode.
            // Reference: riscv-privileged-v1.10 - Section 3.1.13 - page 27.
            mstatus = mi.readMstatus();
            uint64 mideleg = mi.readMideleg();
            enabledInts = uint32(~mideleg);

            // SIE: is the register contaning interrupt enabled bits for supervisor mode.
            // It is located on the first bit of mstatus register (RV64).
            // Reference: riscv-privileged-v1.10 - figure 3.7 - page 20.
            if ((mstatus & RiscVConstants.getMstatusSieMask()) != 0) {
                //TO-DO: make sure this is the correct cast
                enabledInts = enabledInts | uint32(mideleg);
            }
        } else {
            enabledInts = uint32(-1);
        }
        return pendingInts & enabledInts;
    }

    //TO-DO: optmize log2 function
    function ilog2(uint32 v) public pure returns(uint64) {
        //cpp emulator code:
        //return 31 - _BuiltinClz(v)

        uint leading = 32;
        while (v != 0) {
            v = v >> 1;
            leading--;
        }
        return uint64(31 - leading);
    }
}
