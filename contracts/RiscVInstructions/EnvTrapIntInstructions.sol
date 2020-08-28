// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



// TO-DO: Add documentation explaining each instruction

/// @title EnvTrapIntInstruction
pragma solidity ^0.7.0;

import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";
import "../RiscVConstants.sol";
import "../Exceptions.sol";


library EnvTrapIntInstructions {
    function executeECALL(
        MemoryInteractor mi,
        uint256 mmIndex
    ) public
    {
        uint64 priv = mi.readIflagsPrv(mmIndex);
        uint64 mtval = mi.readMtval(mmIndex);
        // TO-DO: Are parameter valuation order deterministic? If so, we dont need to allocate memory
        Exceptions.raiseException(
            mi,
            mmIndex,
            Exceptions.getMcauseEcallBase() + priv,
            mtval
        );
    }

    function executeEBREAK(
        MemoryInteractor mi,
        uint256 mmIndex
    ) public
    {
        Exceptions.raiseException(
            mi,
            mmIndex,
            Exceptions.getMcauseBreakpoint(),
            mi.readMtval(mmIndex)
        );
    }

    function executeSRET(
        MemoryInteractor mi,
        uint256 mmIndex
    )
    public returns (bool)
    {
        uint64 priv = mi.readIflagsPrv(mmIndex);
        uint64 mstatus = mi.readMstatus(mmIndex);

        if (priv < RiscVConstants.getPrvS() || (priv == RiscVConstants.getPrvS() && (mstatus & RiscVConstants.getMstatusTsrMask() != 0))) {
            return false;
        } else {
            uint64 spp = (mstatus & RiscVConstants.getMstatusSppMask()) >> RiscVConstants.getMstatusSppShift();
            // Set the IE state to previous IE state
            uint64 spie = (mstatus & RiscVConstants.getMstatusSpieMask()) >> RiscVConstants.getMstatusSpieShift();
            mstatus = (mstatus & ~RiscVConstants.getMstatusSieMask()) | (spie << RiscVConstants.getMstatusSieShift());

            // set SPIE to 1
            mstatus |= RiscVConstants.getMstatusSpieMask();
            // set SPP to U
            mstatus &= ~RiscVConstants.getMstatusSppMask();
            mi.writeMstatus(mmIndex, mstatus);
            if (priv != spp) {
                mi.setPriv(mmIndex, spp);
            }
            mi.writePc(mmIndex, mi.readSepc(mmIndex));
            return true;
        }
    }

    function executeMRET(
        MemoryInteractor mi,
        uint256 mmIndex
    )
    public returns(bool)
    {
        uint64 priv = mi.readIflagsPrv(mmIndex);

        if (priv < RiscVConstants.getPrvM()) {
            return false;
        } else {
            uint64 mstatus = mi.readMstatus(mmIndex);
            uint64 mpp = (mstatus & RiscVConstants.getMstatusMppMask()) >> RiscVConstants.getMstatusMppShift();
            // set IE state to previous IE state
            uint64 mpie = (mstatus & RiscVConstants.getMstatusMpieMask()) >> RiscVConstants.getMstatusMpieShift();
            mstatus = (mstatus & ~RiscVConstants.getMstatusMieMask()) | (mpie << RiscVConstants.getMstatusMieShift());

            // set MPIE to 1
            mstatus |= RiscVConstants.getMstatusMpieMask();
            // set MPP to U
            mstatus &= ~RiscVConstants.getMstatusMppMask();
            mi.writeMstatus(mmIndex, mstatus);

            if (priv != mpp) {
                mi.setPriv(mmIndex, mpp);
            }
            mi.writePc(mmIndex, mi.readMepc(mmIndex));
            return true;
        }
    }

    function executeWFI(
        MemoryInteractor mi,
        uint256 mmIndex
    )
    public returns(bool)
    {
        uint64 priv = mi.readIflagsPrv(mmIndex);
        uint64 mstatus = mi.readMstatus(mmIndex);

        if (priv == RiscVConstants.getPrvU() || (priv == RiscVConstants.getPrvS() && (mstatus & RiscVConstants.getMstatusTwMask() != 0))) {
            return false;
        } else {
            uint64 mip = mi.readMip(mmIndex);
            uint64 mie = mi.readMie(mmIndex);
            // Go to power down if no enable interrupts are pending
            if ((mip & mie) == 0) {
                mi.setIflagsI(mmIndex, true);
            }
            return true;
        }
    }
}
