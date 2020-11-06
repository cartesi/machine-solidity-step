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
import "./RealTimeClock.sol";


/// @title CLINT
/// @author Felipe Argento
/// @notice Implements the Core Local Interruptor functionalities
/// @dev CLINT active addresses are 0x0200bff8(mtime) and 0x02004000(mtimecmp)
/// Reference: The Core of Cartesi, v1.02 - Section 3.2 - The Board
library CLINT {

    uint64 constant CLINT_MSIP0_ADDR = 0x02000000;
    uint64 constant CLINT_MTIMECMP_ADDR = 0x02004000;
    uint64 constant CLINT_MTIME_ADDR = 0x0200bff8;

    /// @notice reads clint
    /// @param offset can be uint8, uint16, uint32 or uint64
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @return bool if read was successfull
    /// @return uint64 pval
    function clintRead(
        MemoryInteractor mi,
        uint64 offset,
        uint64 wordSize
    )
    public returns (bool, uint64)
    {

        if (offset == CLINT_MSIP0_ADDR) {
            return clintReadMsip(mi, wordSize);
        } else if (offset == CLINT_MTIMECMP_ADDR) {
            return clintReadMtime(mi, wordSize);
        } else if (offset == CLINT_MTIME_ADDR) {
            return clintReadMtimecmp(mi, wordSize);
        } else {
            return (false, 0);
        }
    }

    /// @notice write to clint
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param offset can be uint8, uint16, uint32 or uint64
    /// @param val to be written
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @return bool if write was successfull
    function clintWrite(
        MemoryInteractor mi,
        uint64 offset,
        uint64 val,
        uint64 wordSize)
    public returns (bool)
    {
        if (offset == CLINT_MSIP0_ADDR) {
            if (wordSize == 32) {
                if ((val & 1) != 0) {
                    mi.setMip(RiscVConstants.getMipMsipMask());
                } else {
                    mi.resetMip(RiscVConstants.getMipMsipMask());
                }
                return true;
            }
            return false;
        } else if (offset == CLINT_MTIMECMP_ADDR) {
            if (wordSize == 64) {
                mi.writeClintMtimecmp(val);
                mi.resetMip(RiscVConstants.getMipMsipMask());
                return true;
            }
            // partial mtimecmp is not supported
            return false;
        }
        return false;
    }

    // internal functions
    function clintReadMsip(MemoryInteractor mi, uint64 wordSize)
    internal returns (bool, uint64)
    {
        if (wordSize == 32) {
            if ((mi.readMip() & RiscVConstants.getMipMsipMask()) == RiscVConstants.getMipMsipMask()) {
                return(true, 1);
            } else {
                return (true, 0);
            }
        }
        return (false, 0);
    }

    function clintReadMtime(MemoryInteractor mi, uint64 wordSize)
    internal returns (bool, uint64)
    {
        if (wordSize == 64) {
            return (true, RealTimeClock.rtcCycleToTime(mi.readMcycle()));
        }
        return (false, 0);
    }

    function clintReadMtimecmp(MemoryInteractor mi, uint64 wordSize)
    internal returns (bool, uint64)
    {
        if (wordSize == 64) {
            return (true, mi.readClintMtimecmp());
        }
        return (false, 0);
    }

    // getters
    function getClintMtimecmp() public pure returns (uint64) {
        return CLINT_MTIMECMP_ADDR;
    }
}


