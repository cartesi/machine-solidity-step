/// @title Atomic instructions
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";
import "../../contracts/VirtualMemory.sol";


library AtomicInstructions {

    function executeLR(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn,
        uint64 wordSize
    )
    public returns (bool)
    {
        uint64 vaddr = mi.readX(mmIndex, RiscVDecoder.insnRs1(insn));
        (bool succ, uint64 val) = VirtualMemory.readVirtualMemory(
            mi,
            mmIndex,
            wordSize,
            vaddr
        );

        if (!succ) {
            //executeRetired / advance to raised expection
            return false;
        }
        mi.writeIlrsc(mmIndex, vaddr);

        uint32 rd = RiscVDecoder.insnRd(insn);
        if (rd != 0) {
            mi.writeX(mmIndex, rd, val);
        }
        // advance to next instruction
        return true;

    }

    function executeSC(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn,
        uint64 wordSize
    )
    public returns (bool)
    {
        uint64 val = 0;
        uint64 vaddr = mi.readX(mmIndex, RiscVDecoder.insnRs1(insn));

        if (mi.readIlrsc(mmIndex) == vaddr) {
            if (!VirtualMemory.writeVirtualMemory(
                mi,
                mmIndex,
                wordSize,
                vaddr,
                mi.readX(mmIndex, RiscVDecoder.insnRs2(insn))
            )) {
                //advance to raised exception
                return false;
            }
            mi.writeIlrsc(mmIndex, uint64(-1));
        } else {
            val = 1;
        }
        uint32 rd = RiscVDecoder.insnRd(insn);
        if (rd != 0) {
            mi.writeX(mmIndex, rd, val);
        }
        //advance to next insn
        return true;
    }

    function executeAMOPart1(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn,
        uint64 wordSize
    )
    internal returns (uint64, uint64, uint64, bool)
    {
        uint64 vaddr = mi.readX(mmIndex, RiscVDecoder.insnRs1(insn));

        (bool succ, uint64 tmpValm) = VirtualMemory.readVirtualMemory(
            mi,
            mmIndex,
            wordSize,
            vaddr
        );

        if (!succ) {
            return (0, 0, 0, false);
        }
        uint64 tmpValr = mi.readX(mmIndex, RiscVDecoder.insnRs2(insn));

        return (tmpValm, tmpValr, vaddr, true);
    }

    function executeAMODPart2(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
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
            mmIndex,
            wordSize,
            vaddr,
            uint64(valr)
        )) {
            return false;
        }
        uint32 rd = RiscVDecoder.insnRd(insn);
        if (rd != 0) {
            mi.writeX(mmIndex, rd, uint64(valm));
        }
        return true;
    }

    function executeAMOWPart2(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
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
            mmIndex,
            wordSize,
            vaddr,
            uint64(valr)
        )) {
            return false;
        }
        uint32 rd = RiscVDecoder.insnRd(insn);
        if (rd != 0) {
            mi.writeX(mmIndex, rd, uint64(valm));
        }
        return true;
    }

    function executeAMOSWAPW(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            32
        );
        return executeAMOWPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int32(valr),
            int32(valm), 32
        );
    }

    function executeAMOADDW(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            32
        );
        return executeAMOWPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int32(int32(valm) + int32(valr)),
            int32(valm), 32
        );
    }

    function executeAMOXORW(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            32
        );
        return executeAMOWPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int32(valm ^ valr),
            int32(valm), 32
        );
    }

    function executeAMOANDW(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            32
        );
        return executeAMOWPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int32(valm & valr),
            int32(valm),
            32
        );
    }

    function executeAMOORW(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            32
        );
        return executeAMOWPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int32(valm | valr),
            int32(valm),
            32
        );

    }

    function executeAMOMINW(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            32
        );
        return executeAMOWPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int32(valm < valr? valm : valr),
            int32(valm),
            32
        );
    }

    function executeAMOMAXW(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            32
        );
        return executeAMOWPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int32(valm > valr? valm : valr),
            int32(valm),
            32
        );
    }

    function executeAMOMINUW(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            32
        );
        return executeAMOWPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int32(uint32(valm) < uint32(valr)? valm : valr),
            int32(valm),
            32
        );
    }

    function executeAMOMAXUW(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            32
        );
        return executeAMOWPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int32(uint32(valm) > uint32(valr)? valm : valr),
            int32(valm),
            32
        );
    }

    function executeAMOSWAPD(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            64
        );
        return executeAMODPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int64(valr),
            int64(valm),
            64
        );
    }

    function executeAMOADDD(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            64
        );
        return executeAMODPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int64(valm + valr),
            int64(valm),
            64
        );
    }

    function executeAMOXORD(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            64
        );
        return executeAMODPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int64(valm ^ valr),
            int64(valm),
            64
        );
    }

    function executeAMOANDD(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            64
        );
        return executeAMODPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int64(valm & valr),
            int64(valm),
            64
        );
    }

    function executeAMOORD(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            64
        );
        return executeAMODPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int64(valm | valr),
            int64(valm),
            64
        );

    }

    function executeAMOMIND(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            64
        );
        return executeAMODPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int64(valm < valr? valm : valr),
            int64(valm),
            64
        );
    }

    function executeAMOMAXD(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            64
        );
        return executeAMODPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int64(valm > valr? valm : valr),
            int64(valm),
            64
        );
    }

    function executeAMOMINUD(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            64
        );
        // TO-DO: this is uint not int
        return executeAMODPart2(
            mi,
            mmIndex,
            pc,
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
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = executeAMOPart1(
            mi,
            mmIndex,
            pc,
            insn,
            64
        );
        return executeAMODPart2(
            mi,
            mmIndex,
            pc,
            insn,
            vaddr,
            int64(uint64(valm) > uint64(valr)? valm : valr),
            int64(valm),
            64
        );
    }
}

