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
        MemoryInteractor mi
    ) public
    {
        uint64 priv = mi.readIflagsPrv();
        uint64 mtval = mi.readMtval();
        // TO-DO: Are parameter valuation order deterministic? If so, we dont need to allocate memory
        Exceptions.raiseException(
            mi,
            Exceptions.getMcauseEcallBase() + priv,
            mtval
        );
    }

    function executeEBREAK(
        MemoryInteractor mi
    ) public
    {
        Exceptions.raiseException(
            mi,
            Exceptions.getMcauseBreakpoint(),
            mi.readMtval()
        );
    }

    function executeSRET(
        MemoryInteractor mi
    )
    public returns (bool)
    {
        uint64 priv = mi.readIflagsPrv();
        uint64 mstatus = mi.readMstatus();

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
            mi.writeMstatus(mstatus);
            if (priv != spp) {
                mi.setPriv(spp);
            }
            mi.writePc(mi.readSepc());
            return true;
        }
    }

    function executeMRET(
        MemoryInteractor mi
    )
    public returns(bool)
    {
        uint64 priv = mi.readIflagsPrv();

        if (priv < RiscVConstants.getPrvM()) {
            return false;
        } else {
            uint64 mstatus = mi.readMstatus();
            uint64 mpp = (mstatus & RiscVConstants.getMstatusMppMask()) >> RiscVConstants.getMstatusMppShift();
            // set IE state to previous IE state
            uint64 mpie = (mstatus & RiscVConstants.getMstatusMpieMask()) >> RiscVConstants.getMstatusMpieShift();
            mstatus = (mstatus & ~RiscVConstants.getMstatusMieMask()) | (mpie << RiscVConstants.getMstatusMieShift());

            // set MPIE to 1
            mstatus |= RiscVConstants.getMstatusMpieMask();
            // set MPP to U
            mstatus &= ~RiscVConstants.getMstatusMppMask();
            mi.writeMstatus(mstatus);

            if (priv != mpp) {
                mi.setPriv(mpp);
            }
            mi.writePc(mi.readMepc());
            return true;
        }
    }

    function executeWFI(
        MemoryInteractor mi
    )
    public returns(bool)
    {
        uint64 priv = mi.readIflagsPrv();
        uint64 mstatus = mi.readMstatus();

        return priv != RiscVConstants.getPrvU() &&
               (priv != RiscVConstants.getPrvS() ||
                (mstatus & RiscVConstants.getMstatusTwMask() == 0));
    }
}
