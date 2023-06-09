// Copyright 2023 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title UArchExecuteInsn
/// @notice Execute instruction and return execution state
/// @dev This file is generated from translator/generate-UArchExecuteInsn.lua, one should not modify the content directly

pragma solidity ^0.8.0;

import "./UArchCompat.sol";

contract UArchExecuteInsn {
    // START OF AUTO-GENERATED CODE

    // Memory read/write access

    function readUint64(
        IUArchState.State memory a,
        uint64 paddr
    ) private returns (uint64) {
        require((paddr & 7) == 0, "misaligned readUint64 address");
        return UArchCompat.readWord(a, paddr);
    }

    function readUint32(
        IUArchState.State memory a,
        uint64 paddr
    ) internal returns (uint32) {
        require((paddr & 3) == 0, "misaligned readUint32 address");
        uint64 palign = paddr & ~uint64(7);
        uint32 bitoffset = UArchCompat.uint32ShiftLeft(
            uint32(paddr) & uint32(7),
            3
        );
        uint64 val64 = readUint64(a, palign);
        return uint32(UArchCompat.uint64ShiftRight(val64, bitoffset));
    }

    function readUint16(
        IUArchState.State memory a,
        uint64 paddr
    ) private returns (uint16) {
        require((paddr & 1) == 0, "misaligned readUint16 address");
        uint64 palign = paddr & ~uint64(7);
        uint32 bitoffset = UArchCompat.uint32ShiftLeft(
            uint32(paddr) & uint32(7),
            3
        );
        uint64 val64 = readUint64(a, palign);
        return uint16(UArchCompat.uint64ShiftRight(val64, bitoffset));
    }

    function readUint8(
        IUArchState.State memory a,
        uint64 paddr
    ) private returns (uint8) {
        uint64 palign = paddr & ~uint64(7);
        uint32 bitoffset = UArchCompat.uint32ShiftLeft(
            uint32(paddr) & uint32(7),
            3
        );
        uint64 val64 = readUint64(a, palign);
        return uint8(UArchCompat.uint64ShiftRight(val64, bitoffset));
    }

    function writeUint64(
        IUArchState.State memory a,
        uint64 paddr,
        uint64 val
    ) private {
        require((paddr & 7) == 0, "misaligned writeUint64 address");
        UArchCompat.writeWord(a, paddr, val);
    }

    /// \brief Copies bits from a uint64 word, starting at bit 0, to another uint64 word at the specified bit offset.
    /// \param from Source of bits to copy, starting at offset 0.
    /// \param count Number of bits to copy.
    /// \param to Destination of copy.
    /// \param offset Bit offset in destination to copy bits to.
    /// \return The uint64 word containing the copy result.
    function copyBits(
        uint32 from,
        uint32 count,
        uint64 to,
        uint32 offset
    ) private pure returns (uint64) {
        require(offset + count <= 64, "copyBits count exceeds limit of 64");
        uint64 eraseMask = UArchCompat.uint64ShiftLeft(1, count) - 1;
        eraseMask = ~UArchCompat.uint64ShiftLeft(eraseMask, offset);
        return UArchCompat.uint64ShiftLeft(from, offset) | (to & eraseMask);
    }

    function writeUint32(
        IUArchState.State memory a,
        uint64 paddr,
        uint32 val
    ) private {
        require((paddr & 3) == 0, "misaligned writeUint32 address");
        uint64 palign = paddr & ~uint64(7);

        uint32 bitoffset = UArchCompat.uint32ShiftLeft(
            uint32(paddr) & uint32(7),
            3
        );
        uint64 oldval64 = readUint64(a, palign);
        uint64 newval64 = copyBits(val, 32, oldval64, bitoffset);
        writeUint64(a, palign, newval64);
    }

    function writeUint16(
        IUArchState.State memory a,
        uint64 paddr,
        uint16 val
    ) private {
        require((paddr & 1) == 0, "misaligned writeUint16 address");
        uint64 palign = paddr & ~uint64(7);
        uint32 bitoffset = UArchCompat.uint32ShiftLeft(
            uint32(paddr) & uint32(7),
            3
        );
        uint64 oldval64 = readUint64(a, palign);
        uint64 newval64 = copyBits(val, 16, oldval64, bitoffset);
        writeUint64(a, palign, newval64);
    }

    function writeUint8(
        IUArchState.State memory a,
        uint64 paddr,
        uint8 val
    ) private {
        uint64 palign = paddr & ~uint64(7);
        uint32 bitoffset = UArchCompat.uint32ShiftLeft(
            uint32(paddr) & uint32(7),
            3
        );
        uint64 oldval64 = readUint64(a, palign);
        uint64 newval64 = copyBits(val, 8, oldval64, bitoffset);
        writeUint64(a, palign, newval64);
    }

    // Instruction operand decoders

    function operandRd(uint32 insn) private pure returns (uint8) {
        return
            uint8(
                UArchCompat.uint32ShiftRight(
                    UArchCompat.uint32ShiftLeft(insn, 20),
                    27
                )
            );
    }

    function operandRs1(uint32 insn) private pure returns (uint8) {
        return
            uint8(
                UArchCompat.uint32ShiftRight(
                    UArchCompat.uint32ShiftLeft(insn, 12),
                    27
                )
            );
    }

    function operandRs2(uint32 insn) private pure returns (uint8) {
        return
            uint8(
                UArchCompat.uint32ShiftRight(
                    UArchCompat.uint32ShiftLeft(insn, 7),
                    27
                )
            );
    }

    function operandImm12(uint32 insn) private pure returns (int32) {
        return UArchCompat.int32ShiftRight(int32(insn), 20);
    }

    function operandImm20(uint32 insn) private pure returns (int32) {
        return
            int32(
                UArchCompat.uint32ShiftLeft(
                    UArchCompat.uint32ShiftRight(insn, 12),
                    12
                )
            );
    }

    function operandJimm20(uint32 insn) private pure returns (int32) {
        int32 a = int32(
            UArchCompat.uint32ShiftLeft(
                uint32(UArchCompat.int32ShiftRight(int32(insn), 31)),
                20
            )
        );
        uint32 b = UArchCompat.uint32ShiftLeft(
            UArchCompat.uint32ShiftRight(
                UArchCompat.uint32ShiftLeft(insn, 1),
                22
            ),
            1
        );
        uint32 c = UArchCompat.uint32ShiftLeft(
            UArchCompat.uint32ShiftRight(
                UArchCompat.uint32ShiftLeft(insn, 11),
                31
            ),
            11
        );
        uint32 d = UArchCompat.uint32ShiftLeft(
            UArchCompat.uint32ShiftRight(
                UArchCompat.uint32ShiftLeft(insn, 12),
                24
            ),
            12
        );
        return int32(uint32(a) | b | c | d);
    }

    function operandShamt5(uint32 insn) private pure returns (int32) {
        return
            int32(
                UArchCompat.uint32ShiftRight(
                    UArchCompat.uint32ShiftLeft(insn, 7),
                    27
                )
            );
    }

    function operandShamt6(uint32 insn) private pure returns (int32) {
        return
            int32(
                UArchCompat.uint32ShiftRight(
                    UArchCompat.uint32ShiftLeft(insn, 6),
                    26
                )
            );
    }

    function operandSbimm12(uint32 insn) private pure returns (int32) {
        int32 a = int32(
            UArchCompat.uint32ShiftLeft(
                uint32(UArchCompat.int32ShiftRight(int32(insn), 31)),
                12
            )
        );
        uint32 b = UArchCompat.uint32ShiftLeft(
            UArchCompat.uint32ShiftRight(
                UArchCompat.uint32ShiftLeft(insn, 1),
                26
            ),
            5
        );
        uint32 c = UArchCompat.uint32ShiftLeft(
            UArchCompat.uint32ShiftRight(
                UArchCompat.uint32ShiftLeft(insn, 20),
                28
            ),
            1
        );
        uint32 d = UArchCompat.uint32ShiftLeft(
            UArchCompat.uint32ShiftRight(
                UArchCompat.uint32ShiftLeft(insn, 24),
                31
            ),
            11
        );
        return int32(uint32(a) | b | c | d);
    }

    function operandSimm12(uint32 insn) private pure returns (int32) {
        return
            int32(
                UArchCompat.uint32ShiftLeft(
                    uint32(UArchCompat.int32ShiftRight(int32(insn), 25)),
                    5
                ) |
                    UArchCompat.uint32ShiftRight(
                        UArchCompat.uint32ShiftLeft(insn, 20),
                        27
                    )
            );
    }

    // Execute instruction

    function advancePc(IUArchState.State memory a, uint64 pc) private {
        uint64 newPc = UArchCompat.uint64AddUint64(pc, 4);
        return UArchCompat.writePc(a, newPc);
    }

    function branch(IUArchState.State memory a, uint64 pc) private {
        return UArchCompat.writePc(a, pc);
    }

    function executeLUI(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        int32 imm = operandImm20(insn);
        if (rd != 0) {
            UArchCompat.writeX(a, rd, UArchCompat.int32ToUint64(imm));
        }
        return advancePc(a, pc);
    }

    function executeAUIPC(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm20(insn);
        uint8 rd = operandRd(insn);
        if (rd != 0) {
            UArchCompat.writeX(a, rd, UArchCompat.uint64AddInt32(pc, imm));
        }
        return advancePc(a, pc);
    }

    function executeJAL(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandJimm20(insn);
        uint8 rd = operandRd(insn);
        if (rd != 0) {
            UArchCompat.writeX(a, rd, UArchCompat.uint64AddUint64(pc, 4));
        }
        return branch(a, UArchCompat.uint64AddInt32(pc, imm));
    }

    function executeJALR(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        if (rd != 0) {
            UArchCompat.writeX(a, rd, UArchCompat.uint64AddUint64(pc, 4));
        }
        return
            branch(a, UArchCompat.uint64AddInt32(rs1val, imm) & (~uint64(1)));
    }

    function executeBEQ(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandSbimm12(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        uint64 rs2val = UArchCompat.readX(a, rs2);
        if (rs1val == rs2val) {
            return branch(a, UArchCompat.uint64AddInt32(pc, imm));
        }
        return advancePc(a, pc);
    }

    function executeBNE(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandSbimm12(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        uint64 rs2val = UArchCompat.readX(a, rs2);
        if (rs1val != rs2val) {
            return branch(a, UArchCompat.uint64AddInt32(pc, imm));
        }
        return advancePc(a, pc);
    }

    function executeBLT(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandSbimm12(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        int64 rs1val = int64(UArchCompat.readX(a, rs1));
        int64 rs2val = int64(UArchCompat.readX(a, rs2));
        if (rs1val < rs2val) {
            return branch(a, UArchCompat.uint64AddInt32(pc, imm));
        }
        return advancePc(a, pc);
    }

    function executeBGE(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandSbimm12(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        int64 rs1val = int64(UArchCompat.readX(a, rs1));
        int64 rs2val = int64(UArchCompat.readX(a, rs2));
        if (rs1val >= rs2val) {
            return branch(a, UArchCompat.uint64AddInt32(pc, imm));
        }
        return advancePc(a, pc);
    }

    function executeBLTU(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandSbimm12(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        uint64 rs2val = UArchCompat.readX(a, rs2);
        if (rs1val < rs2val) {
            return branch(a, UArchCompat.uint64AddInt32(pc, imm));
        }
        return advancePc(a, pc);
    }

    function executeBGEU(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandSbimm12(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        uint64 rs2val = UArchCompat.readX(a, rs2);
        if (rs1val >= rs2val) {
            return branch(a, UArchCompat.uint64AddInt32(pc, imm));
        }
        return advancePc(a, pc);
    }

    function executeLB(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        int8 i8 = int8(readUint8(a, UArchCompat.uint64AddInt32(rs1val, imm)));
        if (rd != 0) {
            UArchCompat.writeX(a, rd, UArchCompat.int8ToUint64(i8));
        }
        return advancePc(a, pc);
    }

    function executeLHU(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        uint16 u16 = readUint16(a, UArchCompat.uint64AddInt32(rs1val, imm));
        if (rd != 0) {
            UArchCompat.writeX(a, rd, u16);
        }
        return advancePc(a, pc);
    }

    function executeLH(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        int16 i16 = int16(
            readUint16(a, UArchCompat.uint64AddInt32(rs1val, imm))
        );
        if (rd != 0) {
            UArchCompat.writeX(a, rd, UArchCompat.int16ToUint64(i16));
        }
        return advancePc(a, pc);
    }

    function executeLW(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        int32 i32 = int32(
            readUint32(a, UArchCompat.uint64AddInt32(rs1val, imm))
        );
        if (rd != 0) {
            UArchCompat.writeX(a, rd, UArchCompat.int32ToUint64(i32));
        }
        return advancePc(a, pc);
    }

    function executeLBU(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        uint8 u8 = readUint8(a, UArchCompat.uint64AddInt32(rs1val, imm));
        if (rd != 0) {
            UArchCompat.writeX(a, rd, u8);
        }
        return advancePc(a, pc);
    }

    function executeSB(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandSimm12(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        uint64 rs2val = UArchCompat.readX(a, rs2);
        writeUint8(a, UArchCompat.uint64AddInt32(rs1val, imm), uint8(rs2val));
        return advancePc(a, pc);
    }

    function executeSH(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandSimm12(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        uint64 rs2val = UArchCompat.readX(a, rs2);
        writeUint16(a, UArchCompat.uint64AddInt32(rs1val, imm), uint16(rs2val));
        return advancePc(a, pc);
    }

    function executeSW(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandSimm12(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        uint32 rs2val = uint32(UArchCompat.readX(a, rs2));
        writeUint32(a, UArchCompat.uint64AddInt32(rs1val, imm), rs2val);
        return advancePc(a, pc);
    }

    function executeADDI(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            int64 val = UArchCompat.int64AddInt64(int64(rs1val), int64(imm));
            UArchCompat.writeX(a, rd, uint64(val));
        }
        return advancePc(a, pc);
    }

    function executeADDIW(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        int32 rs1val = UArchCompat.uint64ToInt32(UArchCompat.readX(a, rs1));
        if (rd != 0) {
            int32 val = UArchCompat.int32AddInt32(rs1val, imm);
            UArchCompat.writeX(a, rd, UArchCompat.int32ToUint64(val));
        }
        return advancePc(a, pc);
    }

    function executeSLTI(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            if (int64(rs1val) < imm) {
                UArchCompat.writeX(a, rd, 1);
            } else {
                UArchCompat.writeX(a, rd, 0);
            }
        }
        return advancePc(a, pc);
    }

    function executeSLTIU(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            if (rs1val < UArchCompat.int32ToUint64(imm)) {
                UArchCompat.writeX(a, rd, 1);
            } else {
                UArchCompat.writeX(a, rd, 0);
            }
        }
        return advancePc(a, pc);
    }

    function executeXORI(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            UArchCompat.writeX(a, rd, rs1val ^ UArchCompat.int32ToUint64(imm));
        }
        return advancePc(a, pc);
    }

    function executeORI(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            UArchCompat.writeX(a, rd, rs1val | UArchCompat.int32ToUint64(imm));
        }
        return advancePc(a, pc);
    }

    function executeANDI(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            UArchCompat.writeX(a, rd, rs1val & UArchCompat.int32ToUint64(imm));
        }
        return advancePc(a, pc);
    }

    function executeSLLI(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandShamt6(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            UArchCompat.writeX(
                a,
                rd,
                UArchCompat.uint64ShiftLeft(rs1val, uint32(imm))
            );
        }
        return advancePc(a, pc);
    }

    function executeSLLIW(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandShamt5(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint32 rs1val = uint32(UArchCompat.readX(a, rs1));
        if (rd != 0) {
            UArchCompat.writeX(
                a,
                rd,
                UArchCompat.int32ToUint64(
                    int32(UArchCompat.uint32ShiftLeft(rs1val, uint32(imm)))
                )
            );
        }
        return advancePc(a, pc);
    }

    function executeSRLI(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandShamt6(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            UArchCompat.writeX(
                a,
                rd,
                UArchCompat.uint64ShiftRight(rs1val, uint32(imm))
            );
        }
        return advancePc(a, pc);
    }

    function executeSRLW(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        uint32 rs1val = uint32(UArchCompat.readX(a, rs1));
        uint32 rs2val = uint32(UArchCompat.readX(a, rs2));
        int32 rdval = int32(UArchCompat.uint32ShiftRight(rs1val, rs2val));
        if (rd != 0) {
            UArchCompat.writeX(a, rd, UArchCompat.int32ToUint64(rdval));
        }
        return advancePc(a, pc);
    }

    function executeSRLIW(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandShamt5(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint32 rs1val = uint32(UArchCompat.readX(a, rs1));
        int32 rdval = int32(UArchCompat.uint32ShiftRight(rs1val, uint32(imm)));
        if (rd != 0) {
            UArchCompat.writeX(a, rd, UArchCompat.int32ToUint64(rdval));
        }
        return advancePc(a, pc);
    }

    function executeSRAI(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandShamt6(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            UArchCompat.writeX(
                a,
                rd,
                uint64(UArchCompat.int64ShiftRight(int64(rs1val), uint32(imm)))
            );
        }
        return advancePc(a, pc);
    }

    function executeSRAIW(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandShamt5(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        int32 rs1val = UArchCompat.uint64ToInt32(UArchCompat.readX(a, rs1));
        if (rd != 0) {
            UArchCompat.writeX(
                a,
                rd,
                UArchCompat.int32ToUint64(
                    UArchCompat.int32ShiftRight(rs1val, uint32(imm))
                )
            );
        }
        return advancePc(a, pc);
    }

    function executeADD(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            uint64 rs2val = UArchCompat.readX(a, rs2);
            UArchCompat.writeX(
                a,
                rd,
                UArchCompat.uint64AddUint64(rs1val, rs2val)
            );
        }
        return advancePc(a, pc);
    }

    function executeADDW(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        int32 rs1val = UArchCompat.uint64ToInt32(UArchCompat.readX(a, rs1));
        int32 rs2val = UArchCompat.uint64ToInt32(UArchCompat.readX(a, rs2));
        if (rd != 0) {
            int32 val = UArchCompat.int32AddInt32(rs1val, rs2val);
            UArchCompat.writeX(a, rd, UArchCompat.int32ToUint64(val));
        }
        return advancePc(a, pc);
    }

    function executeSUB(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            uint64 rs2val = UArchCompat.readX(a, rs2);
            UArchCompat.writeX(
                a,
                rd,
                UArchCompat.uint64SubUint64(rs1val, rs2val)
            );
        }
        return advancePc(a, pc);
    }

    function executeSUBW(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        int32 rs1val = UArchCompat.uint64ToInt32(UArchCompat.readX(a, rs1));
        int32 rs2val = UArchCompat.uint64ToInt32(UArchCompat.readX(a, rs2));
        if (rd != 0) {
            int32 val = UArchCompat.int32SubInt32(rs1val, rs2val);
            UArchCompat.writeX(a, rd, UArchCompat.int32ToUint64(val));
        }
        return advancePc(a, pc);
    }

    function executeSLL(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            uint32 rs2val = uint32(UArchCompat.readX(a, rs2));
            UArchCompat.writeX(
                a,
                rd,
                UArchCompat.uint64ShiftLeft(rs1val, rs2val)
            );
        }
        return advancePc(a, pc);
    }

    function executeSLLW(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        uint32 rs1val = uint32(UArchCompat.readX(a, rs1));
        uint32 rs2val = uint32(UArchCompat.readX(a, rs2));
        int32 rdval = int32(
            UArchCompat.uint32ShiftLeft(uint32(rs1val), rs2val)
        );
        if (rd != 0) {
            UArchCompat.writeX(a, rd, UArchCompat.int32ToUint64(rdval));
        }
        return advancePc(a, pc);
    }

    function executeSLT(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        if (rd != 0) {
            int64 rs1val = int64(UArchCompat.readX(a, rs1));
            int64 rs2val = int64(UArchCompat.readX(a, rs2));
            uint64 rdval = 0;
            if (rs1val < rs2val) {
                rdval = 1;
            }
            UArchCompat.writeX(a, rd, rdval);
        }
        return advancePc(a, pc);
    }

    function executeSLTU(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            uint64 rs2val = UArchCompat.readX(a, rs2);
            uint64 rdval = 0;
            if (rs1val < rs2val) {
                rdval = 1;
            }
            UArchCompat.writeX(a, rd, rdval);
        }
        return advancePc(a, pc);
    }

    function executeXOR(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            uint64 rs2val = UArchCompat.readX(a, rs2);
            UArchCompat.writeX(a, rd, rs1val ^ rs2val);
        }
        return advancePc(a, pc);
    }

    function executeSRL(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            uint64 rs2val = UArchCompat.readX(a, rs2);
            UArchCompat.writeX(
                a,
                rd,
                UArchCompat.uint64ShiftRight(rs1val, uint32(rs2val))
            );
        }
        return advancePc(a, pc);
    }

    function executeSRA(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        if (rd != 0) {
            int64 rs1val = int64(UArchCompat.readX(a, rs1));
            uint32 rs2val = uint32(UArchCompat.readX(a, rs2));
            UArchCompat.writeX(
                a,
                rd,
                uint64(UArchCompat.int64ShiftRight(rs1val, rs2val))
            );
        }
        return advancePc(a, pc);
    }

    function executeSRAW(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        int32 rs1val = UArchCompat.uint64ToInt32(UArchCompat.readX(a, rs1));
        uint32 rs2val = uint32(UArchCompat.readX(a, rs2));
        int32 rdval = UArchCompat.int32ShiftRight(rs1val, rs2val);
        if (rd != 0) {
            UArchCompat.writeX(a, rd, UArchCompat.int32ToUint64(rdval));
        }
        return advancePc(a, pc);
    }

    function executeOR(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            uint64 rs2val = UArchCompat.readX(a, rs2);
            UArchCompat.writeX(a, rd, rs1val | rs2val);
        }
        return advancePc(a, pc);
    }

    function executeAND(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        if (rd != 0) {
            uint64 rs1val = UArchCompat.readX(a, rs1);
            uint64 rs2val = UArchCompat.readX(a, rs2);
            UArchCompat.writeX(a, rd, rs1val & rs2val);
        }
        return advancePc(a, pc);
    }

    function executeFENCE(
        IUArchState.State memory a,
        uint32,
        uint64 pc
    ) private {
        return advancePc(a, pc);
    }

    function executeLWU(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        uint32 u32 = readUint32(a, UArchCompat.uint64AddInt32(rs1val, imm));
        if (rd != 0) {
            UArchCompat.writeX(a, rd, u32);
        }
        return advancePc(a, pc);
    }

    function executeLD(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandImm12(insn);
        uint8 rd = operandRd(insn);
        uint8 rs1 = operandRs1(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        uint64 u64 = readUint64(a, UArchCompat.uint64AddInt32(rs1val, imm));
        if (rd != 0) {
            UArchCompat.writeX(a, rd, u64);
        }
        return advancePc(a, pc);
    }

    function executeSD(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) private {
        int32 imm = operandSimm12(insn);
        uint8 rs1 = operandRs1(insn);
        uint8 rs2 = operandRs2(insn);
        uint64 rs1val = UArchCompat.readX(a, rs1);
        uint64 rs2val = UArchCompat.readX(a, rs2);
        writeUint64(a, UArchCompat.uint64AddInt32(rs1val, imm), rs2val);
        return advancePc(a, pc);
    }

    /// \brief Returns true if the opcode field of an instruction matches the provided argument
    function insnMatchOpcode(
        uint32 insn,
        uint32 opcode
    ) private pure returns (bool) {
        return ((insn & 0x7f)) == opcode;
    }

    /// \brief Returns true if the opcode and funct3 fields of an instruction match the provided arguments
    function insnMatchOpcodeFunct3(
        uint32 insn,
        uint32 opcode,
        uint32 funct3
    ) private pure returns (bool) {
        uint32 mask = (7 << 12) | 0x7f;
        return
            (insn & mask) == (UArchCompat.uint32ShiftLeft(funct3, 12) | opcode);
    }

    /// \brief Returns true if the opcode, funct3 and funct7 fields of an instruction match the provided arguments
    function insnMatchOpcodeFunct3Funct7(
        uint32 insn,
        uint32 opcode,
        uint32 funct3,
        uint32 funct7
    ) private pure returns (bool) {
        uint32 mask = (0x7f << 25) | (7 << 12) | 0x7f;
        return
            ((insn & mask)) ==
            (UArchCompat.uint32ShiftLeft(funct7, 25) |
                UArchCompat.uint32ShiftLeft(funct3, 12) |
                opcode);
    }

    /// \brief Returns true if the opcode, funct3 and 6 most significant bits of funct7 fields of an instruction match the
    /// provided arguments
    function insnMatchOpcodeFunct3Funct7Sr1(
        uint32 insn,
        uint32 opcode,
        uint32 funct3,
        uint32 funct7Sr1
    ) private pure returns (bool) {
        uint32 mask = (0x3f << 26) | (7 << 12) | 0x7f;
        return
            ((insn & mask)) ==
            (UArchCompat.uint32ShiftLeft(funct7Sr1, 26) |
                UArchCompat.uint32ShiftLeft(funct3, 12) |
                opcode);
    }

    // Decode and execute one instruction
    function uarchExecuteInsn(
        IUArchState.State memory a,
        uint32 insn,
        uint64 pc
    ) internal {
        if (insnMatchOpcodeFunct3(insn, 0x13, 0x0)) {
            return executeADDI(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x3, 0x3)) {
            return executeLD(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x63, 0x6)) {
            return executeBLTU(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x63, 0x0)) {
            return executeBEQ(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x13, 0x7)) {
            return executeANDI(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x33, 0x0, 0x0)) {
            return executeADD(a, insn, pc);
        } else if (insnMatchOpcode(insn, 0x6f)) {
            return executeJAL(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7Sr1(insn, 0x13, 0x1, 0x0)) {
            return executeSLLI(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x33, 0x7, 0x0)) {
            return executeAND(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x23, 0x3)) {
            return executeSD(a, insn, pc);
        } else if (insnMatchOpcode(insn, 0x37)) {
            return executeLUI(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x67, 0x0)) {
            return executeJALR(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x1b, 0x0)) {
            return executeADDIW(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7Sr1(insn, 0x13, 0x5, 0x0)) {
            return executeSRLI(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x1b, 0x5, 0x0)) {
            return executeSRLIW(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x63, 0x1)) {
            return executeBNE(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x3, 0x2)) {
            return executeLW(a, insn, pc);
        } else if (insnMatchOpcode(insn, 0x17)) {
            return executeAUIPC(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x63, 0x7)) {
            return executeBGEU(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x3b, 0x0, 0x0)) {
            return executeADDW(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7Sr1(insn, 0x13, 0x5, 0x10)) {
            return executeSRAI(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x33, 0x6, 0x0)) {
            return executeOR(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x1b, 0x5, 0x20)) {
            return executeSRAIW(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x63, 0x5)) {
            return executeBGE(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x33, 0x0, 0x20)) {
            return executeSUB(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x3, 0x4)) {
            return executeLBU(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x1b, 0x1, 0x0)) {
            return executeSLLIW(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x33, 0x5, 0x0)) {
            return executeSRL(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x33, 0x4, 0x0)) {
            return executeXOR(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x23, 0x2)) {
            return executeSW(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x33, 0x1, 0x0)) {
            return executeSLL(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x63, 0x4)) {
            return executeBLT(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x23, 0x0)) {
            return executeSB(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x3b, 0x0, 0x20)) {
            return executeSUBW(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x13, 0x4)) {
            return executeXORI(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x33, 0x5, 0x20)) {
            return executeSRA(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x3, 0x5)) {
            return executeLHU(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x23, 0x1)) {
            return executeSH(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x3b, 0x5, 0x0)) {
            return executeSRLW(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x3, 0x6)) {
            return executeLWU(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x3b, 0x1, 0x0)) {
            return executeSLLW(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x3, 0x0)) {
            return executeLB(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x33, 0x3, 0x0)) {
            return executeSLTU(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x3b, 0x5, 0x20)) {
            return executeSRAW(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x3, 0x1)) {
            return executeLH(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x13, 0x6)) {
            return executeORI(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x13, 0x3)) {
            return executeSLTIU(a, insn, pc);
        } else if (insnMatchOpcodeFunct3Funct7(insn, 0x33, 0x2, 0x0)) {
            return executeSLT(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0x13, 0x2)) {
            return executeSLTI(a, insn, pc);
        } else if (insnMatchOpcodeFunct3(insn, 0xf, 0x0)) {
            return executeFENCE(a, insn, pc);
        }
        revert("illegal instruction");
    }

    // END OF AUTO-GENERATED CODE
}
