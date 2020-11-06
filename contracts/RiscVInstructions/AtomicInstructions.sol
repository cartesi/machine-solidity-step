// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title Atomic instructions
pragma solidity ^0.7.0;

import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";
import "../VirtualMemory.sol";

library AtomicInstructions {

    function executeLR(
        MemoryInteractor mi,
        uint32 insn,
        uint64 wordSize
    )
    public returns (bool)
    {
        uint64 vaddr = mi.readX(RiscVDecoder.insnRs1(insn));
        (bool succ, uint64 val) = VirtualMemory.readVirtualMemory(
            mi,
            wordSize,
            vaddr
        );

        if (!succ) {
            //executeRetired / advance to raised expection
            return false;
        }
        mi.writeIlrsc(vaddr);

        uint32 rd = RiscVDecoder.insnRd(insn);
        if (rd != 0) {
            mi.writeX(rd, val);
        }
        // advance to next instruction
        return true;

    }

    function executeSC(
        MemoryInteractor mi,
        uint32 insn,
        uint64 wordSize
    )
    public returns (bool)
    {
        uint64 val = 0;
        uint64 vaddr = mi.readX(RiscVDecoder.insnRs1(insn));

        if (mi.readIlrsc() == vaddr) {
            if (!VirtualMemory.writeVirtualMemory(
                mi,
                wordSize,
                vaddr,
                mi.readX(RiscVDecoder.insnRs2(insn))
            )) {
                //advance to raised exception
                return false;
            }
            mi.writeIlrsc(uint64(-1));
        } else {
            val = 1;
        }
        uint32 rd = RiscVDecoder.insnRd(insn);
        if (rd != 0) {
            mi.writeX(rd, val);
        }
        //advance to next insn
        return true;
    }

    function executeAMOPart1(
        MemoryInteractor mi,
        uint32 insn,
        uint64 wordSize
    )
    internal returns (uint64, uint64, uint64, bool)
    {
        uint64 vaddr = mi.readX(RiscVDecoder.insnRs1(insn));

        (bool succ, uint64 tmpValm) = VirtualMemory.readVirtualMemory(
            mi,
            wordSize,
            vaddr
        );

        if (!succ) {
            return (0, 0, 0, false);
        }
        uint64 tmpValr = mi.readX(RiscVDecoder.insnRs2(insn));

        return (tmpValm, tmpValr, vaddr, true);
    }

    function executeAMODPart2(
        MemoryInteractor mi,
        uint32 insn,
        uint64 vaddr,
        int64 valr,
        int64 valm,
        uint64 wordSize
    )
    internal returns (bool)
    {
        if (!VirtualMemory.writeVirtualMemory(
            mi,
            wordSize,
            vaddr,
            uint64(valr)
        )) {
            return false;
        }
        uint32 rd = RiscVDecoder.insnRd(insn);
        if (rd != 0) {
            mi.writeX(rd, uint64(valm));
        }
        return true;
    }

    function executeAMOWPart2(
        MemoryInteractor mi,
        uint32 insn,
        uint64 vaddr,
        int32 valr,
        int32 valm,
        uint64 wordSize
    )
    internal returns (bool)
    {
        if (!VirtualMemory.writeVirtualMemory(
            mi,
            wordSize,
            vaddr,
            uint64(valr)
        )) {
            return false;
        }
        uint32 rd = RiscVDecoder.insnRd(insn);
        if (rd != 0) {
            mi.writeX(rd, uint64(valm));
        }
        return true;
    }

    function executeAMOSWAPW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(valr),
            int32(valm), 32
        );
    }

    function executeAMOADDW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(int32(valm) + int32(valr)),
            int32(valm), 32
        );
    }

    function executeAMOXORW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(valm ^ valr),
            int32(valm), 32
        );
    }

    function executeAMOANDW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(valm & valr),
            int32(valm),
            32
        );
    }

    function executeAMOORW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(valm | valr),
            int32(valm),
            32
        );

    }

    function executeAMOMINW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(valm) < int32(valr)? int32(valm) : int32(valr),
            int32(valm),
            32
        );
    }

    function executeAMOMAXW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(valm) > int32(valr)? int32(valm) : int32(valr),
            int32(valm),
            32
        );
    }

    function executeAMOMINUW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(uint32(valm) < uint32(valr)? valm : valr),
            int32(valm),
            32
        );
    }

    function executeAMOMAXUW(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            32
        );
        if (!succ)
            return succ;
        return executeAMOWPart2(
            mi,
            insn,
            vaddr,
            int32(uint32(valm) > uint32(valr)? valm : valr),
            int32(valm),
            32
        );
    }

    function executeAMOSWAPD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valr),
            int64(valm),
            64
        );
    }

    function executeAMOADDD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valm + valr),
            int64(valm),
            64
        );
    }

    function executeAMOXORD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valm ^ valr),
            int64(valm),
            64
        );
    }

    function executeAMOANDD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valm & valr),
            int64(valm),
            64
        );
    }

    function executeAMOORD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valm | valr),
            int64(valm),
            64
        );

    }

    function executeAMOMIND(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valm) < int64(valr)? int64(valm) : int64(valr),
            int64(valm),
            64
        );
    }

    function executeAMOMAXD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(valm) > int64(valr)? int64(valm) : int64(valr),
            int64(valm),
            64
        );
    }

    function executeAMOMINUD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        // TO-DO: this is uint not int
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(uint64(valm) < uint64(valr)? valm : valr),
            int64(valm),
            64
        );
    }

    // TO-DO: this is uint not int
    function executeAMOMAXUD(
        MemoryInteractor mi,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            insn,
            64
        );
        if (!succ)
            return succ;
        return executeAMODPart2(
            mi,
            insn,
            vaddr,
            int64(uint64(valm) > uint64(valr)? valm : valr),
            int64(valm),
            64
        );
    }
}

