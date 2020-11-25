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

import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./VirtualMemory.sol";
import "./MemoryInteractor.sol";
import "./CSRExecute.sol";
import "./RiscVInstructions/BranchInstructions.sol";
import "./RiscVInstructions/ArithmeticInstructions.sol";
import "./RiscVInstructions/ArithmeticImmediateInstructions.sol";
import "./RiscVInstructions/S_Instructions.sol";
import "./RiscVInstructions/StandAloneInstructions.sol";
import "./RiscVInstructions/AtomicInstructions.sol";
import "./RiscVInstructions/EnvTrapIntInstructions.sol";
import {Exceptions} from "./Exceptions.sol";

/// @title Execute
/// @author Felipe Argento
/// @notice Finds instructions and execute them or delegate their execution to another library
library Execute {
    uint256 constant ARITH_IMM_GROUP = 0;
    uint256 constant ARITH_IMM_GROUP_32 = 1;

    uint256 constant ARITH_GROUP = 0;
    uint256 constant ARITH_GROUP_32 = 1;

    uint256 constant CSRRW_CODE = 0;
    uint256 constant CSRRWI_CODE = 1;

    uint256 constant CSRRS_CODE = 0;
    uint256 constant CSRRC_CODE = 1;

    uint256 constant CSRRSI_CODE = 0;
    uint256 constant CSRRCI_CODE = 1;


    /// @notice Finds associated instruction and execute it.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc Current pc
    /// @param insn Instruction.
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function executeInsn(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        // Finds instruction associated with that opcode
        // Sometimes the opcode fully defines the associated instruction, but most
        // of the times it only specifies which group it belongs to.
        // For example, an opcode of: 01100111 is always a LUI instruction but an
        // opcode of 1100011 might be BEQ, BNE, BLT etc
        // Reference: riscv-spec-v2.2.pdf - Table 19.2 - Page 104

        // OPCODE is located on bit 0 - 6 of the following types of 32bits instructions:
        // R-Type, I-Type, S-Trype and U-Type
        // Reference: riscv-spec-v2.2.pdf - Figure 2.2 - Page 11
        uint32 opcode = RiscVDecoder.insnOpcode(insn);

        if (opcode < 0x002f) {
            if (opcode < 0x0017) {
                if (opcode == 0x0003) {
                    return loadFunct3(
                        mi,
                        insn,
                        pc
                    );
                } else if (opcode == 0x000f) {
                    return fenceGroup(
                        mi,
                        insn,
                        pc
                    );
                } else if (opcode == 0x0013) {
                    return executeArithmeticImmediate(
                        mi,
                        insn,
                        pc,
                        ARITH_IMM_GROUP
                    );
                }
            } else if (opcode > 0x0017) {
                if (opcode == 0x001b) {
                    return executeArithmeticImmediate(
                        mi,
                        insn,
                        pc,
                        ARITH_IMM_GROUP_32
                    );
                } else if (opcode == 0x0023) {
                    return storeFunct3(
                        mi,
                        insn,
                        pc
                    );
                }
            } else if (opcode == 0x0017) {
                StandAloneInstructions.executeAuipc(
                    mi,
                    insn,
                    pc
                );
                return advanceToNextInsn(mi,  pc);
            }
        } else if (opcode > 0x002f) {
            if (opcode < 0x0063) {
                if (opcode == 0x0033) {
                    return executeArithmetic(
                        mi,
                        insn,
                        pc,
                        ARITH_GROUP
                    );
                } else if (opcode == 0x003b) {
                    return executeArithmetic(
                        mi,
                        insn,
                        pc,
                        ARITH_GROUP_32
                    );
                } else if (opcode == 0x0037) {
                    StandAloneInstructions.executeLui(
                        mi,
                        insn
                    );
                    return advanceToNextInsn(mi,  pc);
                }
            } else if (opcode > 0x0063) {
                if (opcode == 0x0067) {
                    (bool succ, uint64 newPc) = StandAloneInstructions.executeJalr(
                        mi,
                        insn,
                        pc
                    );
                    if (succ) {
                        return executeJump(mi,  newPc);
                    } else {
                        return raiseMisalignedFetchException(mi,  newPc);
                    }
                } else if (opcode == 0x0073) {
                    return csrEnvTrapIntMmFunct3(
                        mi,
                        insn,
                        pc
                    );
                } else if (opcode == 0x006f) {
                    (bool succ, uint64 newPc) = StandAloneInstructions.executeJal(
                        mi,
                        insn,
                        pc
                    );
                    if (succ) {
                        return executeJump(mi,  newPc);
                    } else {
                        return raiseMisalignedFetchException(mi,  newPc);
                    }
                }
            } else if (opcode == 0x0063) {
                return executeBranch(
                    mi,
                    insn,
                    pc
                );
            }
        } else if (opcode == 0x002f) {
            return atomicFunct3Funct5(
                mi,
                insn,
                pc
            );
        }
        return raiseIllegalInsnException(mi,  insn);
    }

    /// @notice Finds and execute Arithmetic Immediate instruction
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc Current pc
    /// @param insn Instruction.
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function executeArithmeticImmediate(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc,
        uint256 immGroup
    )
    public returns (executeStatus)
    {
        uint32 rd = RiscVDecoder.insnRd(insn);
        uint64 arithImmResult;
        bool insnValid;

        if (rd != 0) {
            if (immGroup == ARITH_IMM_GROUP) {
                (arithImmResult, insnValid) = ArithmeticImmediateInstructions.arithmeticImmediateFunct3(mi,  insn);
            } else {
                //immGroup == ARITH_IMM_GROUP_32
                (arithImmResult, insnValid) = ArithmeticImmediateInstructions.arithmeticImmediate32Funct3(mi,  insn);
            }

            if (!insnValid) {
                return raiseIllegalInsnException(mi,  insn);
            }

            mi.writeX(rd, arithImmResult);
        }
        return advanceToNextInsn(mi,  pc);
    }

    /// @notice Finds and execute Arithmetic instruction
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc Current pc
    /// @param insn Instruction.
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function executeArithmetic(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc,
        uint256 groupCode
    )
    public returns (executeStatus)
    {
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            uint64 arithResult = 0;
            bool insnValid = false;

            if (groupCode == ARITH_GROUP) {
                (arithResult, insnValid) = ArithmeticInstructions.arithmeticFunct3Funct7(mi,  insn);
            } else {
                // groupCode == arith_32Group
                (arithResult, insnValid) = ArithmeticInstructions.arithmetic32Funct3Funct7(mi,  insn);
            }

            if (!insnValid) {
                return raiseIllegalInsnException(mi,  insn);
            }
            mi.writeX( rd, arithResult);
        }
        return advanceToNextInsn(mi,  pc);
    }

    /// @notice Finds and execute Branch instruction
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc Current pc
    /// @param insn Instruction.
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function executeBranch(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc)
    public returns (executeStatus)
    {

        (bool branchValuated, bool insnValid) = BranchInstructions.branchFunct3(mi,  insn);

        if (!insnValid) {
            return raiseIllegalInsnException(mi,  insn);
        }

        if (branchValuated) {
            uint64 newPc = uint64(int64(pc) + int64(RiscVDecoder.insnBImm(insn)));
            if ((newPc & 3) != 0) {
                return raiseMisalignedFetchException(mi,  newPc);
            }else {
                return executeJump(mi,  newPc);
            }
        }
        return advanceToNextInsn(mi,  pc);
    }

    /// @notice Finds and execute Load instruction
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc Current pc
    /// @param insn Instruction.
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
   function executeLoad(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc,
        uint64 wordSize,
        bool isSigned
    )
    public returns (executeStatus)
    {
        uint64 vaddr = mi.readX( RiscVDecoder.insnRs1(insn));
        int32 imm = RiscVDecoder.insnIImm(insn);
        uint32 rd = RiscVDecoder.insnRd(insn);

        (bool succ, uint64 val) = VirtualMemory.readVirtualMemory(
            mi,
            wordSize,
            vaddr + uint64(imm)
        );

        if (succ) {
            if (isSigned) {
                val = BitsManipulationLibrary.uint64SignExtension(val, wordSize);
            }

            if (rd != 0) {
                mi.writeX(rd, val);
            }

            return advanceToNextInsn(mi, pc);

        } else {
            //return advanceToRaisedException()
            return executeStatus.retired;
        }
    }

    /// @notice Execute S_fence_VMA instruction
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc Current pc
    /// @param insn Instruction.
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function executeSfenceVma(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        if ((insn & 0xFE007FFF) == 0x12000073) {
            uint64 priv = mi.readIflagsPrv();
            uint64 mstatus = mi.readMstatus();

            if (priv == RiscVConstants.getPrvU() || (priv == RiscVConstants.getPrvS() && ((mstatus & RiscVConstants.getMstatusTvmMask() != 0)))) {
                return raiseIllegalInsnException(mi, insn);
            }

            return advanceToNextInsn(mi, pc);
        } else {
            return raiseIllegalInsnException(mi, insn);
        }
    }

    /// @notice Execute jump - writes a new pc
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param newPc pc to be written
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function executeJump(MemoryInteractor mi, uint64 newPc)
    public returns (executeStatus)
    {
        mi.writePc( newPc);
        return executeStatus.retired;
    }

    /// @notice Raises Misaligned Fetch Exception
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc current pc
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function raiseMisalignedFetchException(MemoryInteractor mi, uint64 pc)
    public returns (executeStatus)
    {
        Exceptions.raiseException(
            mi,
            Exceptions.getMcauseInsnAddressMisaligned(),
            pc
        );
        return executeStatus.retired;
    }

    /// @notice Raises Illegal Instruction Exception
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param insn instruction that was deemed illegal
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function raiseIllegalInsnException(MemoryInteractor mi, uint32 insn)
    public returns (executeStatus)
    {
        Exceptions.raiseException(
            mi,
            Exceptions.getMcauseIllegalInsn(),
            insn
        );
        return executeStatus.illegal;
    }

    /// @notice Advances to next instruction by increasing pc
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param pc current pc
    /// @return executeStatus.illegal if an illegal instruction exception was raised, or executeStatus.retired if not (even if it raises other exceptions).
    function advanceToNextInsn(MemoryInteractor mi, uint64 pc)
    public returns (executeStatus)
    {
        mi.writePc( pc + 4);
        return executeStatus.retired;
    }

    /// @notice Given a fence funct3 insn, finds the func associated.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param insn for fence funct3 field.
    /// @param pc Current pc
    /// @dev Uses binary search for performance.
    function fenceGroup(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns(executeStatus)
    {
        if (insn == 0x0000100f) {
            /*insn == 0x0000*/
            //return "FENCE";
            //really do nothing
            return advanceToNextInsn(mi, pc);
        } else if (insn & 0xf00fff80 != 0) {
            /*insn == 0x0001*/
            return raiseIllegalInsnException(mi, insn);
        }
        //return "FENCE_I";
        //really do nothing
        return advanceToNextInsn(mi, pc);
    }

    /// @notice Given csr env trap int mm funct3 insn, finds the func associated.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param insn for fence funct3 field.
    /// @param pc Current pc
    /// @dev Uses binary search for performance.
    function csrEnvTrapIntMmFunct3(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);

        if (funct3 < 0x0003) {
            if (funct3 == 0x0000) {
                /*funct3 == 0x0000*/
                return envTrapIntGroup(
                    mi,
                    insn,
                    pc
                );
            } else if (funct3 == 0x0002) {
                /*funct3 == 0x0002*/
                //return "CSRRS";
                if (CSRExecute.executeCsrSC(
                    mi,
                    insn,
                    CSRRS_CODE
                )) {
                    return advanceToNextInsn(mi, pc);
                } else {
                    return raiseIllegalInsnException(mi, insn);
                }
            } else if (funct3 == 0x0001) {
                /*funct3 == 0x0001*/
                //return "CSRRW";
                if (CSRExecute.executeCsrRW(
                    mi,
                    insn,
                    CSRRW_CODE
                )) {
                    return advanceToNextInsn(mi, pc);
                } else {
                    return raiseIllegalInsnException(mi, insn);
                }
            }
        } else if (funct3 > 0x0003) {
            if (funct3 == 0x0005) {
                /*funct3 == 0x0005*/
                //return "CSRRWI";
                if (CSRExecute.executeCsrRW(
                    mi,
                    insn,
                    CSRRWI_CODE
                )) {
                    return advanceToNextInsn(mi, pc);
                } else {
                    return raiseIllegalInsnException(mi, insn);
                }
            } else if (funct3 == 0x0007) {
                /*funct3 == 0x0007*/
                //return "CSRRCI";
                if (CSRExecute.executeCsrSCI(
                    mi,
                    insn,
                    CSRRCI_CODE
                )) {
                    return advanceToNextInsn(mi, pc);
                } else {
                    return raiseIllegalInsnException(mi, insn);
                }
            } else if (funct3 == 0x0006) {
                /*funct3 == 0x0006*/
                //return "CSRRSI";
                if (CSRExecute.executeCsrSCI(
                    mi,
                    insn,
                    CSRRSI_CODE
                )) {
                    return advanceToNextInsn(mi, pc);
                } else {
                    return raiseIllegalInsnException(mi, insn);
                }
            }
        } else if (funct3 == 0x0003) {
            /*funct3 == 0x0003*/
            //return "CSRRC";
            if (CSRExecute.executeCsrSC(
                mi,
                insn,
                CSRRC_CODE
            )) {
                return advanceToNextInsn(mi, pc);
            } else {
                return raiseIllegalInsnException(mi, insn);
            }
        }
        return raiseIllegalInsnException(mi, insn);
    }

    /// @notice Given a store funct3 group insn, finds the function associated.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param insn for store funct3 field
    /// @param pc Current pc
    /// @dev Uses binary search for performance.
    function storeFunct3(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);
        if (funct3 == 0x0000) {
            /*funct3 == 0x0000*/
            //return "SB";
            return S_Instructions.sb(
                mi,
                insn
            ) ? advanceToNextInsn(mi, pc) : executeStatus.retired;
        } else if (funct3 > 0x0001) {
            if (funct3 == 0x0002) {
                /*funct3 == 0x0002*/
                //return "SW";
                return S_Instructions.sw(
                    mi,
                    insn
                ) ? advanceToNextInsn(mi, pc) : executeStatus.retired;
            } else if (funct3 == 0x0003) {
                /*funct3 == 0x0003*/
                //return "SD";
                return S_Instructions.sd(
                    mi,
                    insn
                ) ? advanceToNextInsn(mi, pc) : executeStatus.retired;
            }
        } else if (funct3 == 0x0001) {
            /*funct3 == 0x0001*/
            //return "SH";
            return S_Instructions.sh(
                mi,
                insn
            ) ? advanceToNextInsn(mi, pc) : executeStatus.retired;
        }
        return raiseIllegalInsnException(mi, insn);
    }

    /// @notice Given a env trap int group insn, finds the func associated.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param insn insn for env trap int group field.
    /// @param pc Current pc
    /// @dev Uses binary search for performance.
    function envTrapIntGroup(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        if (insn < 0x10200073) {
            if (insn == 0x0073) {
                EnvTrapIntInstructions.executeECALL(
                    mi
                );
                return executeStatus.retired;
            } else if (insn == 0x200073) {
                // No U-Mode traps
                raiseIllegalInsnException(mi, insn);
            } else if (insn == 0x100073) {
                EnvTrapIntInstructions.executeEBREAK(
                    mi
                );
                return executeStatus.retired;
            }
        } else if (insn > 0x10200073) {
            if (insn == 0x10500073) {
                if (!EnvTrapIntInstructions.executeWFI(
                    mi
                )) {
                    return raiseIllegalInsnException(mi, insn);
                }
                return advanceToNextInsn(mi, pc);
            } else if (insn == 0x30200073) {
                if (!EnvTrapIntInstructions.executeMRET(
                    mi
                )) {
                    return raiseIllegalInsnException(mi, insn);
                }
                return executeStatus.retired;
            }
        } else if (insn == 0x10200073) {
            if (!EnvTrapIntInstructions.executeSRET(
                mi
                )
               ) {
                return raiseIllegalInsnException(mi, insn);
            }
            return executeStatus.retired;
        }
        return executeSfenceVma(
            mi,
            insn,
            pc
        );
    }

    /// @notice Given a load funct3 group instruction, finds the function
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param insn for load funct3 field
    /// @param pc Current pc
    /// @dev Uses binary search for performance.
    function loadFunct3(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);

        if (funct3 < 0x0003) {
            if (funct3 == 0x0000) {
                //return "LB";
                return executeLoad(
                    mi,
                    insn,
                    pc,
                    8,
                    true
                );

            } else if (funct3 == 0x0002) {
                //return "LW";
                return executeLoad(
                    mi,
                    insn,
                    pc,
                    32,
                    true
                );
            } else if (funct3 == 0x0001) {
                //return "LH";
                return executeLoad(
                    mi,
                    insn,
                    pc,
                    16,
                    true
                );
            }
        } else if (funct3 > 0x0003) {
            if (funct3 == 0x0004) {
                //return "LBU";
                return executeLoad(
                    mi,
                    insn,
                    pc,
                    8,
                    false
                );
            } else if (funct3 == 0x0006) {
                //return "LWU";
                return executeLoad(
                    mi,
                    insn,
                    pc,
                    32,
                    false
                );
            } else if (funct3 == 0x0005) {
                //return "LHU";
                return executeLoad(
                    mi,
                    insn,
                    pc,
                    16,
                    false
                );
            }
        } else if (funct3 == 0x0003) {
            //return "LD";
            return executeLoad(
                mi,
                insn,
                pc,
                64,
                true
            );
        }
        return raiseIllegalInsnException(mi, insn);
    }

    function atomicFunct3Funct5(
        MemoryInteractor mi,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        uint32 funct3Funct5 = RiscVDecoder.insnFunct3Funct5(insn);
        bool atomSucc;
        // TO-DO: transform in binary search for performance
        if (funct3Funct5 == 0x42) {
            if ((insn & 0x1f00000) == 0 ) {
                atomSucc = AtomicInstructions.executeLR(
                    mi,
                    insn,
                    32
                );
            } else {
                return raiseIllegalInsnException(mi, insn);
            }
        } else if (funct3Funct5 == 0x43) {
            atomSucc = AtomicInstructions.executeSC(
                mi,
                insn,
                32
            );
        } else if (funct3Funct5 == 0x41) {
            atomSucc = AtomicInstructions.executeAMOSWAPW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x40) {
            atomSucc = AtomicInstructions.executeAMOADDW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x44) {
            atomSucc = AtomicInstructions.executeAMOXORW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x4c) {
            atomSucc = AtomicInstructions.executeAMOANDW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x48) {
            atomSucc = AtomicInstructions.executeAMOORW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x50) {
            atomSucc = AtomicInstructions.executeAMOMINW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x54) {
            atomSucc = AtomicInstructions.executeAMOMAXW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x58) {
            atomSucc = AtomicInstructions.executeAMOMINUW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x5c) {
            atomSucc = AtomicInstructions.executeAMOMAXUW(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x62) {
            if ((insn & 0x1f00000) == 0 ) {
                atomSucc = AtomicInstructions.executeLR(
                    mi,
                    insn,
                    64
                );
            }
        } else if (funct3Funct5 == 0x63) {
            atomSucc = AtomicInstructions.executeSC(
                mi,
                insn,
                64
            );
        } else if (funct3Funct5 == 0x61) {
            atomSucc = AtomicInstructions.executeAMOSWAPD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x60) {
            atomSucc = AtomicInstructions.executeAMOADDD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x64) {
            atomSucc = AtomicInstructions.executeAMOXORD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x6c) {
            atomSucc = AtomicInstructions.executeAMOANDD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x68) {
            atomSucc = AtomicInstructions.executeAMOORD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x70) {
            atomSucc = AtomicInstructions.executeAMOMIND(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x74) {
            atomSucc = AtomicInstructions.executeAMOMAXD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x78) {
            atomSucc = AtomicInstructions.executeAMOMINUD(
                mi,
                insn
            );
        } else if (funct3Funct5 == 0x7c) {
            atomSucc = AtomicInstructions.executeAMOMAXUD(
                mi,
                insn
            );
        }
        if (atomSucc) {
            return advanceToNextInsn(mi, pc);
        } else {
            return executeStatus.retired;
        }
    }

    enum executeStatus {
        illegal, // Exception was raised
        retired // Instruction retired - having raised or not an exception
    }
}
