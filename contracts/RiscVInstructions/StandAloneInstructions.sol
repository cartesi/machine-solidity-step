// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title StandAloneInstructions
pragma solidity ^0.7.0;

import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";


library StandAloneInstructions {
    //AUIPC forms a 32-bit offset from the 20-bit U-immediate, filling in the
    // lowest 12 bits with zeros, adds this offset to pc and store the result on rd.
    // Reference: riscv-spec-v2.2.pdf -  Page 14
    function executeAuipc(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    ) public
    {
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(rd, pc + uint64(RiscVDecoder.insnUImm(insn)));
        }
        //return advanceToNextInsn(mi, pc);
    }

    // LUI (i.e load upper immediate). Is used to build 32-bit constants and uses
    // the U-type format. LUI places the U-immediate value in the top 20 bits of
    // the destination register rd, filling in the lowest 12 bits with zeros
    // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 13
    function executeLui(
        MemoryInteractor mi,
        uint32 insn
    ) public
    {
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(rd, uint64(RiscVDecoder.insnUImm(insn)));
        }
        //return advanceToNextInsn(mi, pc);
    }

    // JALR (i.e Jump and Link Register). uses the I-type encoding. The target
    // address is obtained by adding the 12-bit signed I-immediate to the register
    // rs1, then setting the least-significant bit of the result to zero.
    // The address of the instruction following the jump (pc+4) is written to register rd
    // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 16
    function executeJalr(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (bool, uint64)
    {
        uint64 newPc = uint64(int64(mi.readX(RiscVDecoder.insnRs1(insn))) + int64(RiscVDecoder.insnIImm(insn))) & ~uint64(1);

        if ((newPc & 3) != 0) {
            return (false, newPc);
            //return raiseMisalignedFetchException(mi, newPc);
        }
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(rd, pc + 4);
        }
        return (true, newPc);
        //return executeJump(mi, newPc);
    }

    // JAL (i.e Jump and Link). JImmediate encondes a signed offset in multiples
    // of 2 bytes. The offset is added to pc and JAL stores the address of the jump
    // (pc + 4) to the rd register.
    // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 16
    function executeJal(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (bool, uint64)
    {
        uint64 newPc = pc + uint64(RiscVDecoder.insnJImm(insn));

        if ((newPc & 3) != 0) {
            return (false, newPc);
            //return raiseMisalignedFetchException(mi, newPc);
        }
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(rd, pc + 4);
        }
        return (true, newPc);
        //return executeJump(mi, newPc);
    }

}

