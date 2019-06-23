/// @title S_Instructions
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";
import "../../contracts/VirtualMemory.sol";


library S_Instructions {
    // event Print(string a, uint64 b);
    function getRs1ImmRs2(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
    internal returns(uint64 rs1, int32 imm, uint64 val)
    {
        rs1 = mi.readX(mmIndex, RiscVDecoder.insnRs1(insn));
        imm = RiscVDecoder.insn_SImm(insn);
        val = mi.readX(mmIndex, RiscVDecoder.insnRs2(insn));
    }

    function sb(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 vaddr, int32 imm, uint64 val) = getRs1ImmRs2(mi, mmIndex, insn);
        // 8 == uint8
        return VirtualMemory.writeVirtualMemory(
            mi,
            mmIndex,
            8,
            vaddr + uint64(imm),
            val
        );
    }

    function sh(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
        )
    public returns(bool)
    {
        (uint64 vaddr, int32 imm, uint64 val) = getRs1ImmRs2(mi, mmIndex, insn);
        // 16 == uint16
        return VirtualMemory.writeVirtualMemory(
            mi,
            mmIndex,
            16,
            vaddr + uint64(imm),
            val
        );
    }

    function sw(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 vaddr, int32 imm, uint64 val) = getRs1ImmRs2(mi, mmIndex, insn);
        // 32 == uint32
        return VirtualMemory.writeVirtualMemory(
            mi,
            mmIndex,
            32,
            vaddr + uint64(imm),
            val
        );
    }

    function sd(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pc,
        uint32 insn
    )
    public returns(bool)
    {
        (uint64 vaddr, int32 imm, uint64 val) = getRs1ImmRs2(mi, mmIndex, insn);
        // 64 == uint64
        return VirtualMemory.writeVirtualMemory(
            mi,
            mmIndex,
            64,
            vaddr + uint64(imm),
            val
        );
    }
}
