// Copyright 2019 Cartesi Pte. Ltd.

// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title S_Instructions
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";
import "../../contracts/VirtualMemory.sol";


library S_Instructions {
    function getRs1ImmRs2(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
    internal returns(uint64 rs1, int32 imm, uint64 val)
    {
        rs1 = mi.readX(mmIndex, RiscVDecoder.insnRs1(insn));
        imm = RiscVDecoder.insnSImm(insn);
        val = mi.readX(mmIndex, RiscVDecoder.insnRs2(insn));
    }

    function sb(
        MemoryInteractor mi,
        uint256 mmIndex,
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
