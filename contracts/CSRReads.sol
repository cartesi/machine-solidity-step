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
import "./RiscVDecoder.sol";
import "./RealTimeClock.sol";

/// @title CSRReads
/// @author Felipe Argento
/// @notice Implements CSR read logic
library CSRReads {
    function readCsrCycle(MemoryInteractor mi, uint32 csrAddr)
    internal returns(bool, uint64)
    {
        if (rdcounteren(mi, csrAddr)) {
            return (true, mi.readMcycle());
        } else {
            return (false, 0);
        }
    }

    function readCsrInstret(MemoryInteractor mi, uint32 csrAddr)
    internal returns(bool, uint64)
    {
        if (rdcounteren(mi, csrAddr)) {
            return (true, mi.readMinstret());
        } else {
            return (false, 0);
        }
    }

    function readCsrTime(MemoryInteractor mi, uint32 csrAddr)
    internal returns(bool, uint64)
    {
        if (rdcounteren(mi, csrAddr)) {
            uint64 mtime = RealTimeClock.rtcCycleToTime(mi.readMcycle());
            return (true, mtime);
        } else {
            return (false, 0);
        }
    }

    function readCsrSstatus(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMstatus() & RiscVConstants.getSstatusRMask());
    }

    function readCsrSie(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        uint64 mie = mi.readMie();
        uint64 mideleg = mi.readMideleg();

        return (true, mie & mideleg);
    }

    function readCsrStvec(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readStvec());
    }

    function readCsrScounteren(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readScounteren());
    }

    function readCsrSscratch(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readSscratch());
    }

    function readCsrSepc(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readSepc());
    }

    function readCsrScause(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readScause());
    }

    function readCsrStval(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readStval());
    }

    function readCsrSip(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        uint64 mip = mi.readMip();
        uint64 mideleg = mi.readMideleg();
        return (true, mip & mideleg);
    }

    function readCsrSatp(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        uint64 mstatus = mi.readMstatus();
        uint64 priv = mi.readIflagsPrv();

        if (priv == RiscVConstants.getPrvS() && (mstatus & RiscVConstants.getMstatusTvmMask() != 0)) {
            return (false, 0);
        } else {
            return (true, mi.readSatp());
        }
    }

    function readCsrMstatus(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMstatus() & RiscVConstants.getMstatusRMask());
    }

    function readCsrMisa(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMisa());
    }

    function readCsrMedeleg(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMedeleg());
    }

    function readCsrMideleg(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMideleg());
    }

    function readCsrMie(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMie());
    }

    function readCsrMtvec(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMtvec());
    }

    function readCsrMcounteren(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMcounteren());
    }

    function readCsrMscratch(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMscratch());
    }

    function readCsrMepc(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMepc());
    }

    function readCsrMcause(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMcause());
    }

    function readCsrMtval(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMtval());
    }

    function readCsrMip(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMip());
    }

    function readCsrMcycle(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMcycle());
    }

    function readCsrMinstret(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMinstret());
    }

    function readCsrMvendorid(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMvendorid());
    }

    function readCsrMarchid(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMarchid());
    }

    function readCsrMimpid(MemoryInteractor mi)
    internal returns(bool, uint64)
    {
        return (true, mi.readMimpid());
    }

    function readCsrFail() internal pure returns(bool, uint64) {
        return (false, 0);
    }

    // Check if counter is enabled. mcounteren control the availability of the
    // hardware performance monitoring counter to the next-lowest priv level.
    // Reference: riscv-privileged-v1.10 - section 3.1.17 - page 32.
    function rdcounteren(MemoryInteractor mi, uint32 csrAddr)
    internal returns (bool)
    {
        uint64 counteren = RiscVConstants.getMcounterenRwMask();
        uint64 priv = mi.readIflagsPrv();

        if (priv < RiscVConstants.getPrvM()) {
            counteren &= mi.readMcounteren();
            if (priv < RiscVConstants.getPrvS()) {
                counteren &= mi.readScounteren();
            }
        }
        return (((counteren >> (csrAddr & 0x1f)) & 1) != 0);
    }
}
