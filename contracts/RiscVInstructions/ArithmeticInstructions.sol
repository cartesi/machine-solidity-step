// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title ArithmeticInstructions

pragma solidity ^0.7.0;

// Overflow/Underflow behaviour in solidity is to allow them to happen freely.
// This mimics the RiscV behaviour, so we can use the arithmetic operators normally.
// RiscV-spec-v2.2 - Section 2.4:
// https://content.riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf
// Solidity docs Twos Complement/Underflow/Overflow:
// https://solidity.readthedocs.io/en/latest/security-considerations.html?highlight=overflow#two-s-complement-underflows-overflows
import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";
import "@cartesi/util/contracts/BitsManipulationLibrary.sol";


library ArithmeticInstructions {
    // TO-DO: move XLEN to its own library
    uint constant XLEN = 64;

    // event Print(string message);
    function getRs1Rs2(MemoryInteractor mi, uint32 insn) internal
    returns(uint64 rs1, uint64 rs2)
    {
        rs1 = mi.readX(RiscVDecoder.insnRs1(insn));
        rs2 = mi.readX(RiscVDecoder.insnRs2(insn));
    }

    function executeADD(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("ADD");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        //BuiltinAddOverflow(rs1, rs2, &val)
        return rs1 + rs2;
    }

    function executeSUB(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("SUB");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        //BuiltinSubOverflow(rs1, rs2, &val)
        return rs1 - rs2;
    }

    function executeSLL(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("SLL");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return rs1 << (rs2 & uint64(XLEN - 1));
    }

    function executeSLT(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("SLT");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return (int64(rs1) < int64(rs2))? 1:0;
    }

    function executeSLTU(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("SLTU");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return (rs1 < rs2)? 1:0;
    }

    function executeXOR(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("XOR");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return rs1 ^ rs2;
    }

    function executeSRL(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("SRL");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return rs1 >> (rs2 & (XLEN-1));
    }

    function executeSRA(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("SRA");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return uint64(int64(rs1) >> (rs2 & (XLEN-1)));
    }

    function executeOR(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("OR");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return rs1 | rs2;
    }

    function executeAND(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("AND");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return rs1 & rs2;
    }

    function executeMUL(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("MUL");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        int64 srs1 = int64(rs1);
        int64 srs2 = int64(rs2);
        //BuiltinMulOverflow(srs1, srs2, &val);

        return uint64(srs1 * srs2);
    }

    function executeMULH(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("MULH");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        int64 srs1 = int64(rs1);
        int64 srs2 = int64(rs2);

        return uint64((int128(srs1) * int128(srs2)) >> 64);
    }

    function executeMULHSU(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        int64 srs1 = int64(rs1);

        return uint64((int128(srs1) * int128(rs2)) >> 64);
    }

    function executeMULHU(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        return uint64((int128(rs1) * int128(rs2)) >> 64);
    }

    function executeDIV(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("DIV");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        int64 srs1 = int64(rs1);
        int64 srs2 = int64(rs2);

        if (srs2 == 0) {
            return uint64(-1);
        } else if (srs1 == (int64(1 << (XLEN - 1))) && srs2 == -1) {
            return uint64(srs1);
        } else {
            return uint64(srs1 / srs2);
        }
    }

    function executeDIVU(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        if (rs2 == 0) {
            return uint64(-1);
        } else {
            return rs1 / rs2;
        }
    }

    function executeREM(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        int64 srs1 = int64(rs1);
        int64 srs2 = int64(rs2);

        if (srs2 == 0) {
            return uint64(srs1);
        } else if (srs1 == (int64(1 << uint64(XLEN - 1))) && srs2 == -1) {
            return 0;
        } else {
            return uint64(srs1 % srs2);
        }
    }

    function executeREMU(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        if (rs2 == 0) {
            return rs1;
        } else {
            return rs1 % rs2;
        }
    }

    function executeADDW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        // emit Print("REMU");
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(rs1);
        int32 rs2w = int32(rs2);

        return uint64(rs1w + rs2w);
    }

    function executeSUBW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(rs1);
        int32 rs2w = int32(rs2);

        return uint64(rs1w - rs2w);
    }

    function executeSLLW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(uint32(rs1) << uint32(rs2 & 31));

        return uint64(rs1w);
    }

    function executeSRLW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(uint32(rs1) >> (rs2 & 31));

        return uint64(rs1w);
    }

    function executeSRAW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(rs1) >> (rs2 & 31);

        return uint64(rs1w);
    }

    function executeMULW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(rs1);
        int32 rs2w = int32(rs2);

        return uint64(rs1w * rs2w);
    }

    function executeDIVW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(rs1);
        int32 rs2w = int32(rs2);
        if (rs2w == 0) {
            return uint64(-1);
        } else if (rs1w == (int32(1) << (32 - 1)) && rs2w == -1) {
            return uint64(rs1w);
        } else {
            return uint64(rs1w / rs2w);
        }
    }

    function executeDIVUW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        uint32 rs1w = uint32(rs1);
        uint32 rs2w = uint32(rs2);
        if (rs2w == 0) {
            return uint64(-1);
        } else {
            return uint64(int32(rs1w / rs2w));
        }
    }

    function executeREMW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        int32 rs1w = int32(rs1);
        int32 rs2w = int32(rs2);

        if (rs2w == 0) {
            return uint64(rs1w);
        } else if (rs1w == (int32(1) << (32 - 1)) && rs2w == -1) {
            return uint64(0);
        } else {
            return uint64(rs1w % rs2w);
        }
    }

    function executeREMUW(MemoryInteractor mi, uint32 insn) public returns (uint64) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);

        uint32 rs1w = uint32(rs1);
        uint32 rs2w = uint32(rs2);

        if (rs2w == 0) {
            return uint64(int32(rs1w));
        } else {
            return uint64(int32(rs1w % rs2w));
        }
    }

    /// @notice Given a arithmetic funct3 funct7 insn, finds the func associated.
    //  Uses binary search for performance.
    //  @param insn for arithmetic 32 funct3 funct7 field.
    function arithmeticFunct3Funct7(MemoryInteractor mi, uint32 insn) public returns (uint64, bool) {
        uint32 funct3Funct7 = RiscVDecoder.insnFunct3Funct7(insn);
        if (funct3Funct7 < 0x0181) {
            if (funct3Funct7 < 0x0081) {
                if (funct3Funct7 < 0x0020) {
                    if (funct3Funct7 == 0x0000) {
                        /*funct3Funct7 == 0x0000*/
                        return (executeADD(mi, insn), true);
                    } else if (funct3Funct7 == 0x0001) {
                        /*funct3Funct7 == 0x0001*/
                        return (executeMUL(mi, insn), true);
                    }
                } else if (funct3Funct7 == 0x0080) {
                    /*funct3Funct7 == 0x0080*/
                    return (executeSLL(mi, insn), true);
                } else if (funct3Funct7 == 0x0020) {
                    /*funct3Funct7 == 0x0020*/
                    return (executeSUB(mi, insn), true);
                }
            } else if (funct3Funct7 > 0x0081) {
                if (funct3Funct7 == 0x0100) {
                    /*funct3Funct7 == 0x0100*/
                    return (executeSLT(mi, insn), true);
                } else if (funct3Funct7 == 0x0180) {
                    /*funct3Funct7 == 0x0180*/
                    return (executeSLTU(mi, insn), true);
                } else if (funct3Funct7 == 0x0101) {
                    /*funct3Funct7 == 0x0101*/
                    return (executeMULHSU(mi, insn), true);
                }
            } else if (funct3Funct7 == 0x0081) {
                /* funct3Funct7 == 0x0081*/
                return (executeMULH(mi, insn), true);
            }
        } else if (funct3Funct7 > 0x0181) {
            if (funct3Funct7 < 0x02a0) {
                if (funct3Funct7 == 0x0200) {
                    /*funct3Funct7 == 0x0200*/
                    return (executeXOR(mi, insn), true);
                } else if (funct3Funct7 > 0x0201) {
                    if (funct3Funct7 == 0x0280) {
                        /*funct3Funct7 == 0x0280*/
                        return (executeSRL(mi, insn), true);
                    } else if (funct3Funct7 == 0x0281) {
                        /*funct3Funct7 == 0x0281*/
                        return (executeDIVU(mi, insn), true);
                    }
                } else if (funct3Funct7 == 0x0201) {
                    /*funct3Funct7 == 0x0201*/
                    return (executeDIV(mi, insn), true);
                }
            }else if (funct3Funct7 > 0x02a0) {
                if (funct3Funct7 < 0x0380) {
                    if (funct3Funct7 == 0x0300) {
                        /*funct3Funct7 == 0x0300*/
                        return (executeOR(mi, insn), true);
                    } else if (funct3Funct7 == 0x0301) {
                        /*funct3Funct7 == 0x0301*/
                        return (executeREM(mi, insn), true);
                    }
                } else if (funct3Funct7 == 0x0381) {
                    /*funct3Funct7 == 0x0381*/
                    return (executeREMU(mi, insn), true);
                } else if (funct3Funct7 == 0x380) {
                    /*funct3Funct7 == 0x0380*/
                    return (executeAND(mi, insn), true);
                }
            } else if (funct3Funct7 == 0x02a0) {
                /*funct3Funct7 == 0x02a0*/
                return (executeSRA(mi, insn), true);
            }
        } else if (funct3Funct7 == 0x0181) {
            /*funct3Funct7 == 0x0181*/
            return (executeMULHU(mi, insn), true);
        }
        return (0, false);
    }

    /// @notice Given an arithmetic32 funct3 funct7 insn, finds the associated func.
    //  Uses binary search for performance.
    //  @param insn for arithmetic32 funct3 funct7 field.
    function arithmetic32Funct3Funct7(MemoryInteractor mi, uint32 insn)
    public returns (uint64, bool)
    {

        uint32 funct3Funct7 = RiscVDecoder.insnFunct3Funct7(insn);

        if (funct3Funct7 < 0x0280) {
            if (funct3Funct7 < 0x0020) {
                if (funct3Funct7 == 0x0000) {
                    /*funct3Funct7 == 0x0000*/
                    return (executeADDW(mi, insn), true);
                } else if (funct3Funct7 == 0x0001) {
                    /*funct3Funct7 == 0x0001*/
                    return (executeMULW(mi, insn), true);
                }
            } else if (funct3Funct7 > 0x0020) {
                if (funct3Funct7 == 0x0080) {
                    /*funct3Funct7 == 0x0080*/
                    return (executeSLLW(mi, insn), true);
                } else if (funct3Funct7 == 0x0201) {
                    /*funct3Funct7 == 0x0201*/
                    return (executeDIVW(mi, insn), true);
                }
            } else if (funct3Funct7 == 0x0020) {
                /*funct3Funct7 == 0x0020*/
                return (executeSUBW(mi, insn), true);
            }
        } else if (funct3Funct7 > 0x0280) {
            if (funct3Funct7 < 0x0301) {
                if (funct3Funct7 == 0x0281) {
                    /*funct3Funct7 == 0x0281*/
                    return (executeDIVUW(mi, insn), true);
                } else if (funct3Funct7 == 0x02a0) {
                    /*funct3Funct7 == 0x02a0*/
                    return (executeSRAW(mi, insn), true);
                }
            } else if (funct3Funct7 == 0x0381) {
                /*funct3Funct7 == 0x0381*/
                return (executeREMUW(mi, insn), true);
            } else if (funct3Funct7 == 0x0301) {
                /*funct3Funct7 == 0x0301*/
                //return "REMW";
                return (executeREMW(mi, insn), true);
            }
        } else if (funct3Funct7 == 0x0280) {
            /*funct3Funct7 == 0x0280*/
            //return "SRLW";
            return (executeSRLW(mi, insn), true);
        }
        //return "illegal insn";
        return (0, false);
    }
}
