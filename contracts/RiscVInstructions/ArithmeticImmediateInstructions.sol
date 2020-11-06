// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title ArithmeticImmediateInstructions
pragma solidity ^0.7.0;

import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";
import "../RiscVConstants.sol";

library ArithmeticImmediateInstructions {

    function getRs1Imm(MemoryInteractor mi, uint32 insn) internal
    returns(uint64 rs1, int32 imm)
    {
        rs1 = mi.readX(RiscVDecoder.insnRs1(insn));
        imm = RiscVDecoder.insnIImm(insn);
    }

    // ADDI adds the sign extended 12 bits immediate to rs1. Overflow is ignored.
    // Reference: riscv-spec-v2.2.pdf -  Page 13
    function executeADDI(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        int64 val = int64(rs1) + int64(imm);
        return uint64(val);
    }

    // ADDIW adds the sign extended 12 bits immediate to rs1 and produces to correct
    // sign extension for 32 bits at rd. Overflow is ignored and the result is the
    // low 32 bits of the result sign extended to 64 bits.
    // Reference: riscv-spec-v2.2.pdf -  Page 30
    function executeADDIW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return uint64(int32(rs1) + imm);
    }

    // SLLIW is analogous to SLLI but operate on 32 bit values.
    // The amount of shifts are enconded on the lower 5 bits of I-imm.
    // Reference: riscv-spec-v2.2.pdf - Section 4.2 -  Page 30
    function executeSLLIW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        int32 rs1w = int32(rs1) << uint32(imm & 0x1F);
        return uint64(rs1w);
    }

    // ORI performs logical Or bitwise operation on register rs1 and the sign-extended
    // 12 bit immediate. It places the result in rd.
    // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
    function executeORI(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return rs1 | uint64(imm);
    }

    // SLLI performs the logical left shift. The operand to be shifted is in rs1
    // and the amount of shifts are encoded on the lower 6 bits of I-imm.(RV64)
    // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
    function executeSLLI(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return rs1 << uint32(imm & 0x3F);
    }

    // SLRI instructions is a logical shift right instruction. The variable to be
    // shift is in rs1 and the amount of shift operations is encoded in the lower
    // 6 bits of the I-immediate field.
    function executeSRLI(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        // Get imm's lower 6 bits
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        uint32 shiftAmount = uint32(imm & int32(RiscVConstants.getXlen() - 1));

        return rs1 >> shiftAmount;
    }

    // SRLIW instructions operates on a 32bit value and produce a signed results.
    // The variable to be shift is in rs1 and the amount of shift operations is
    // encoded in the lower 6 bits of the I-immediate field.
    function executeSRLIW(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        // Get imm's lower 6 bits
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        int32 rs1w = int32(uint32(rs1) >> uint32(imm & 0x1F));
        return uint64(rs1w);
    }

    // SLTI - Set less than immediate. Places value 1 in rd if rs1 is less than
    // the signed extended imm when both are signed. Else 0 is written.
    // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 13.
    function executeSLTI(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return (int64(rs1) < int64(imm))? 1 : 0;
    }

    // SLTIU is analogous to SLLTI but treats imm as unsigned.
    // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
    function executeSLTIU(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return (rs1 < uint64(imm))? 1 : 0;
    }

    // SRAIW instructions operates on a 32bit value and produce a signed results.
    // The variable to be shift is in rs1 and the amount of shift operations is
    // encoded in the lower 6 bits of the I-immediate field.
    function executeSRAIW(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        // Get imm's lower 6 bits
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        int32 rs1w = int32(rs1) >> uint32(imm & 0x1F);
        return uint64(rs1w);
    }

    // TO-DO: make sure that >> is now arithmetic shift and not logical shift
    // SRAI instruction is analogous to SRAIW but for RV64I
    function executeSRAI(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        // Get imm's lower 6 bits
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return uint64(int64(rs1) >> uint256(int64(imm) & int64((RiscVConstants.getXlen() - 1))));
    }

    // XORI instructions performs XOR operation on register rs1 and hhe sign extended
    // 12 bit immediate, placing result in rd.
    function executeXORI(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        // Get imm's lower 6 bits
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        return rs1 ^ uint64(imm);
    }

    // ANDI instructions performs AND operation on register rs1 and hhe sign extended
    // 12 bit immediate, placing result in rd.
    function executeANDI(MemoryInteractor mi, uint32 insn) public returns(uint64) {
        // Get imm's lower 6 bits
        (uint64 rs1, int32 imm) = getRs1Imm(mi, insn);
        //return (rs1 & uint64(imm) != 0)? 1 : 0;
        return rs1 & uint64(imm);
    }

    /// @notice Given a arithmetic immediate32 funct3 insn, finds the associated func.
    //  Uses binary search for performance.
    //  @param insn for arithmetic immediate32 funct3 field.
    function arithmeticImmediate32Funct3(MemoryInteractor mi, uint32 insn)
    public returns (uint64, bool)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);
        if (funct3 == 0x0000) {
            /*funct3 == 0x0000*/
            //return "ADDIW";
            return (executeADDIW(mi, insn), true);
        } else if (funct3 == 0x0005) {
            /*funct3 == 0x0005*/
            return shiftRightImmediate32Group(mi, insn);
        } else if (funct3 == 0x0001) {
            /*funct3 == 0x0001*/
            //return "SLLIW";
            return (executeSLLIW(mi, insn), true);
        }
        return (0, false);
    }

    /// @notice Given a arithmetic immediate funct3 insn, finds the func associated.
    //  Uses binary search for performance.
    //  @param insn for arithmetic immediate funct3 field.
    function arithmeticImmediateFunct3(MemoryInteractor mi, uint32 insn)
    public returns (uint64, bool)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);
        if (funct3 < 0x0003) {
            if (funct3 == 0x0000) {
                /*funct3 == 0x0000*/
                return (executeADDI(mi, insn), true);

            } else if (funct3 == 0x0002) {
                /*funct3 == 0x0002*/
                return (executeSLTI(mi, insn), true);
            } else if (funct3 == 0x0001) {
                // Imm[11:6] must be zero for it to be SLLI.
                // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
                if (( insn & (0x3F << 26)) != 0) {
                    return (0, false);
                }
                return (executeSLLI(mi, insn), true);
            }
        } else if (funct3 > 0x0003) {
            if (funct3 < 0x0006) {
                if (funct3 == 0x0004) {
                    /*funct3 == 0x0004*/
                    return (executeXORI(mi, insn), true);
                } else if (funct3 == 0x0005) {
                    /*funct3 == 0x0005*/
                    return shiftRightImmediateFunct6(mi, insn);
                }
            } else if (funct3 == 0x0007) {
                /*funct3 == 0x0007*/
                return (executeANDI(mi, insn), true);
            } else if (funct3 == 0x0006) {
                /*funct3 == 0x0006*/
                return (executeORI(mi, insn), true);
            }
        } else if (funct3 == 0x0003) {
            /*funct3 == 0x0003*/
            return (executeSLTIU(mi, insn), true);
        }
        return (0, false);
    }

    /// @notice Given a right immediate funct6 insn, finds the func associated.
    //  Uses binary search for performance.
    //  @param insn for right immediate funct6 field.
    function shiftRightImmediateFunct6(MemoryInteractor mi, uint32 insn)
    public returns (uint64, bool)
    {
        uint32 funct6 = RiscVDecoder.insnFunct6(insn);
        if (funct6 == 0x0000) {
            /*funct6 == 0x0000*/
            return (executeSRLI(mi, insn), true);
        } else if (funct6 == 0x0010) {
            /*funct6 == 0x0010*/
            return (executeSRAI(mi, insn), true);
        }
        //return "illegal insn";
        return (0, false);
    }

    /// @notice Given a shift right immediate32 funct3 insn, finds the associated func.
    //  Uses binary search for performance.
    //  @param insn for shift right immediate32 funct3 field.
    function shiftRightImmediate32Group(MemoryInteractor mi, uint32 insn)
    public returns (uint64, bool)
    {
        uint32 funct7 = RiscVDecoder.insnFunct7(insn);

        if (funct7 == 0x0000) {
            /*funct7 == 0x0000*/
            return (executeSRLIW(mi, insn), true);
        } else if (funct7 == 0x0020) {
            /*funct7 == 0x0020*/
            return (executeSRAIW(mi, insn), true);
        }
        return (0, false);
    }
}
