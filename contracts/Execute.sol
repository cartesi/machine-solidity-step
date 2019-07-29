/// @title Execute
pragma solidity ^0.5.0;

import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./VirtualMemory.sol";
import "../contracts/MemoryInteractor.sol";
import "../contracts/CSRExecute.sol";
import "./RiscVInstructions/BranchInstructions.sol";
import "./RiscVInstructions/ArithmeticInstructions.sol";
import "./RiscVInstructions/ArithmeticImmediateInstructions.sol";
import "./RiscVInstructions/S_Instructions.sol";
import "./RiscVInstructions/StandAloneInstructions.sol";
import "./RiscVInstructions/AtomicInstructions.sol";
import "./RiscVInstructions/EnvTrapIntInstructions.sol";
import {Exceptions} from "../contracts/Exceptions.sol";


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


    // \brief Finds associated instruction and execute it.
    // \param mi Memory Interactor with which Step function is interacting.
    // \param mmIndex Index corresponding to the instance of Memory Manager that.
    // \param pc Current pc.
    // \param insn Instruction.
    // \return executeStatus.illegal if an illegal instruction exception was raised, or
    // executeStatus.retired if not (even if it raises other exceptions).
    function executeInsn(
        uint256 mmIndex,
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
                        mmIndex,
                        insn,
                        pc
                    );
                } else if (opcode == 0x000f) {
                    return fenceGroup(
                        mi,
                        mmIndex,
                        insn,
                        pc
                    );
                } else if (opcode == 0x0013) {
                    return executeArithmeticImmediate(
                        mi,
                        mmIndex,
                        insn,
                        pc,
                        ARITH_IMM_GROUP
                    );
                }
            } else if (opcode > 0x0017) {
                if (opcode == 0x001b) {
                    return executeArithmeticImmediate(
                        mi,
                        mmIndex,
                        insn,
                        pc,
                        ARITH_IMM_GROUP_32
                    );
                } else if (opcode == 0x0023) {
                    return storeFunct3(
                        mi,
                        mmIndex,
                        insn,
                        pc
                    );
                }
            } else if (opcode == 0x0017) {
                StandAloneInstructions.executeAuipc(
                    mi,
                    mmIndex,
                    insn,
                    pc
                );
                return advanceToNextInsn(mi, mmIndex, pc);
            }
        } else if (opcode > 0x002f) {
            if (opcode < 0x0063) {
                if (opcode == 0x0033) {
                    return executeArithmetic(
                        mi,
                        mmIndex,
                        insn,
                        pc,
                        ARITH_GROUP
                    );
                } else if (opcode == 0x003b) {
                    return executeArithmetic(
                        mi,
                        mmIndex,
                        insn,
                        pc,
                        ARITH_GROUP_32
                    );
                } else if (opcode == 0x0037) {
                    StandAloneInstructions.executeLui(
                        mi,
                        mmIndex,
                        insn
                    );
                    return advanceToNextInsn(mi, mmIndex, pc);
                }
            } else if (opcode > 0x0063) {
                if (opcode == 0x0067) {
                    (bool succ, uint64 newPc) = StandAloneInstructions.executeJalr(
                        mi,
                        mmIndex,
                        insn,
                        pc
                    );
                    if (succ) {
                        return executeJump(mi, mmIndex, newPc);
                    } else {
                        return raiseMisalignedFetchException(mi, mmIndex, newPc);
                    }
                } else if (opcode == 0x0073) {
                    return csrEnvTrapIntMmFunct3(
                        mi,
                        mmIndex,
                        insn,
                        pc
                    );
                } else if (opcode == 0x006f) {
                    (bool succ, uint64 newPc) = StandAloneInstructions.executeJal(
                        mi,
                        mmIndex,
                        insn,
                        pc
                    );
                    if (succ) {
                        return executeJump(mi, mmIndex, newPc);
                    } else {
                        return raiseMisalignedFetchException(mi, mmIndex, newPc);
                    }
                }
            } else if (opcode == 0x0063) {
                return executeBranch(
                    mi,
                    mmIndex,
                    insn,
                    pc
                );
            }
        } else if (opcode == 0x002f) {
            return atomicFunct3Funct5(
                mi,
                mmIndex,
                insn,
                pc
            );
        }
        return raiseIllegalInsnException(mi, mmIndex, insn);
    }

    function executeArithmeticImmediate(
        MemoryInteractor mi,
        uint256 mmIndex,
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
                (arithImmResult, insnValid) = ArithmeticImmediateInstructions.arithmeticImmediateFunct3(mi, mmIndex, insn);
            } else {
                //immGroup == ARITH_IMM_GROUP_32
                (arithImmResult, insnValid) = ArithmeticImmediateInstructions.arithmeticImmediate32Funct3(mi, mmIndex, insn);
            }

            if (!insnValid) {
                return raiseIllegalInsnException(mi, mmIndex, insn);
            }

            mi.writeX(mmIndex, rd, arithImmResult);
        }
        return advanceToNextInsn(mi, mmIndex, pc);
    }

    function executeArithmetic(
        MemoryInteractor mi,
        uint256 mmIndex,
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
                (arithResult, insnValid) = ArithmeticInstructions.arithmeticFunct3Funct7(mi, mmIndex, insn);
            } else {
                // groupCode == arith_32Group
                (arithResult, insnValid) = ArithmeticInstructions.arithmetic32Funct3Funct7(mi, mmIndex, insn);
            }

            if (!insnValid) {
                return raiseIllegalInsnException(mi, mmIndex, insn);
            }
            mi.writeX(mmIndex, rd, arithResult);
        }
        return advanceToNextInsn(mi, mmIndex, pc);
    }

    function executeBranch(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint64 pc)
    public returns (executeStatus)
    {

        (bool branchValuated, bool insnValid) = BranchInstructions.branchFunct3(mi, mmIndex, insn);

        if (!insnValid) {
            return raiseIllegalInsnException(mi, mmIndex, insn);
        }

        if (branchValuated) {
            uint64 newPc = uint64(int64(pc) + int64(RiscVDecoder.insnBImm(insn)));
            if ((newPc & 3) != 0) {
                return raiseMisalignedFetchException(mi, mmIndex, newPc);
            }else {
                return executeJump(mi, mmIndex, newPc);
            }
        }
        return advanceToNextInsn(mi, mmIndex, pc);
    }

    function executeLoad(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint64 pc,
        uint64 wordSize,
        bool isSigned
    )
    public returns (executeStatus)
    {
        uint64 vaddr = mi.readX(mmIndex, RiscVDecoder.insnRs1(insn));
        int32 imm = RiscVDecoder.insnIImm(insn);
        (bool succ, uint64 val) = VirtualMemory.readVirtualMemory(
            mi,
            mmIndex,
            wordSize,
            vaddr + uint64(imm)
        );

        if (succ) {
            if (isSigned) {
                val = BitsManipulationLibrary.uint64SignExtension(val, wordSize);
            }
            mi.writeX(mmIndex, RiscVDecoder.insnRd(insn), val);
            return advanceToNextInsn(mi, mmIndex, pc);
        } else {
            //return advanceToRaisedException()
            return executeStatus.retired;
        }
    }

    function executeSfenceVma(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        if ((insn & 0xFE007FFF) == 0x12000073) {
            uint64 priv = mi.readIflagsPrv(mmIndex);
            uint64 mstatus = mi.readMstatus(mmIndex);

            if (priv == RiscVConstants.getPrvU() || (priv == RiscVConstants.getPrvS() && ((mstatus & RiscVConstants.getMstatusTvmMask() != 0)))) {
                return raiseIllegalInsnException(mi, mmIndex, insn);
            }

            return advanceToNextInsn(mi, mmIndex, pc);
        } else {
            return raiseIllegalInsnException(mi, mmIndex, insn);
        }
    }

    function executeJump(MemoryInteractor mi, uint256 mmIndex, uint64 newPc)
    public returns (executeStatus)
    {
        mi.writePc(mmIndex, newPc);
        return executeStatus.retired;
    }

    function raiseMisalignedFetchException(MemoryInteractor mi, uint256 mmIndex, uint64 pc)
    public returns (executeStatus)
    {
        Exceptions.raiseException(
            mi,
            mmIndex,
            Exceptions.getMcauseInsnAddressMisaligned(),
            pc
        );
        return executeStatus.retired;
    }

    function raiseIllegalInsnException(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
    public returns (executeStatus)
    {
        Exceptions.raiseException(
            mi,
            mmIndex,
            Exceptions.getMcauseIllegalInsn(),
            insn
        );
        return executeStatus.illegal;
    }

    function advanceToNextInsn(MemoryInteractor mi, uint256 mmIndex, uint64 pc)
    public returns (executeStatus)
    {
        mi.writePc(mmIndex, pc + 4);
        return executeStatus.retired;
    }

    // \brief Given a fence funct3 insn, finds the func associated.
    // \param mi Memory Interactor with which Step function is interacting.
    // \param mmIndex Index corresponding to the instance of Memory Manager that.
    // \param insn for fence funct3 field.
    // \param pc.
    //  \details Uses binary search for performance.
    function fenceGroup(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint64 pc
    )
    public returns(executeStatus)
    {
        if (insn == 0x0000100f) {
            /*insn == 0x0000*/
            //return "FENCE";
            //really do nothing
            return advanceToNextInsn(mi, mmIndex, pc);
        } else if (insn & 0xf00fff80 != 0) {
            /*insn == 0x0001*/
            return raiseIllegalInsnException(mi, mmIndex, insn);
        }
        //return "FENCE_I";
        //really do nothing
        return advanceToNextInsn(mi, mmIndex, pc);
    }

    // \brief Given csr env trap int mm funct3 insn, finds the func associated.
    // \param mi Memory Interactor with which Step function is interacting.
    // \param mmIndex Index corresponding to the instance of Memory Manager that.
    // \param insn for fence funct3 field.
    // \param pc.
    //  \details Uses binary search for performance.
    function csrEnvTrapIntMmFunct3(
        MemoryInteractor mi,
        uint256 mmIndex,
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
                    mmIndex,
                    insn,
                    pc
                );
            } else if (funct3 == 0x0002) {
                /*funct3 == 0x0002*/
                //return "CSRRS";
                if (CSRExecute.executeCsrSC(
                    mi,
                    mmIndex,
                    insn,
                    CSRRS_CODE
                )) {
                    return advanceToNextInsn(mi, mmIndex, pc);
                } else {
                    return raiseIllegalInsnException(mi, mmIndex, insn);
                }
            } else if (funct3 == 0x0001) {
                /*funct3 == 0x0001*/
                //return "CSRRW";
                if (CSRExecute.executeCsrRW(
                    mi,
                    mmIndex,
                    insn,
                    CSRRW_CODE
                )) {
                    return advanceToNextInsn(mi, mmIndex, pc);
                } else {
                    return raiseIllegalInsnException(mi, mmIndex, insn);
                }
            }
        } else if (funct3 > 0x0003) {
            if (funct3 == 0x0005) {
                /*funct3 == 0x0005*/
                //return "CSRRWI";
                if (CSRExecute.executeCsrRW(
                    mi,
                    mmIndex,
                    insn,
                    CSRRWI_CODE
                )) {
                    return advanceToNextInsn(mi, mmIndex, pc);
                } else {
                    return raiseIllegalInsnException(mi, mmIndex, insn);
                }
            } else if (funct3 == 0x0007) {
                /*funct3 == 0x0007*/
                //return "CSRRCI";
                if (CSRExecute.executeCsrSCI(
                    mi,
                    mmIndex,
                    insn,
                    CSRRCI_CODE
                )) {
                    return advanceToNextInsn(mi, mmIndex, pc);
                } else {
                    return raiseIllegalInsnException(mi, mmIndex, insn);
                }
            } else if (funct3 == 0x0006) {
                /*funct3 == 0x0006*/
                //return "CSRRSI";
                if (CSRExecute.executeCsrSCI(
                    mi,
                    mmIndex,
                    insn,
                    CSRRSI_CODE
                )) {
                    return advanceToNextInsn(mi, mmIndex, pc);
                } else {
                    return raiseIllegalInsnException(mi, mmIndex, insn);
                }
            }
        } else if (funct3 == 0x0003) {
            /*funct3 == 0x0003*/
            //return "CSRRC";
            if (CSRExecute.executeCsrSC(
                mi,
                mmIndex,
                insn,
                CSRRC_CODE
            )) {
                return advanceToNextInsn(mi, mmIndex, pc);
            } else {
                return raiseIllegalInsnException(mi, mmIndex, insn);
            }
        }
        return raiseIllegalInsnException(mi, mmIndex, insn);
    }

    // \brief Given a store funct3 group insn, finds the function  associated.
    // \param mi Memory Interactor with which Step function is interacting.
    // \param mmIndex Index corresponding to the instance of Memory Manager that.
    // \param insn for store funct3 field
    // \param pc.
    //  \details Uses binary search for performance.
    function storeFunct3(
        MemoryInteractor mi,
        uint256 mmIndex,
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
                mmIndex,
                insn
            ) ? advanceToNextInsn(mi, mmIndex, pc) : executeStatus.retired;
        } else if (funct3 > 0x0001) {
            if (funct3 == 0x0002) {
                /*funct3 == 0x0002*/
                //return "SW";
                return S_Instructions.sw(
                    mi,
                    mmIndex,
                    insn
                ) ? advanceToNextInsn(mi, mmIndex, pc) : executeStatus.retired;
            } else if (funct3 == 0x0003) {
                /*funct3 == 0x0003*/
                //return "SD";
                return S_Instructions.sd(
                    mi,
                    mmIndex,
                    insn
                ) ? advanceToNextInsn(mi, mmIndex, pc) : executeStatus.retired;
            }
        } else if (funct3 == 0x0001) {
            /*funct3 == 0x0001*/
            //return "SH";
            return S_Instructions.sh(
                mi,
                mmIndex,
                insn
            ) ? advanceToNextInsn(mi, mmIndex, pc) : executeStatus.retired;
        }
        return raiseIllegalInsnException(mi, mmIndex, insn);
    }

    // \brief Given a env trap int group insn, finds the func associated.
    // \param mi Memory Interactor with which Step function is interacting.
    // \param mmIndex Index corresponding to the instance of Memory Manager that.
    // \param insn insn for env trap int group field.
    //  \details Uses binary search for performance.
    function envTrapIntGroup(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        if (insn < 0x10200073) {
            if (insn == 0x0073) {
                EnvTrapIntInstructions.executeECALL(
                    mi,
                    mmIndex
                );
                return executeStatus.retired;
            } else if (insn == 0x200073) {
                // No U-Mode traps
                raiseIllegalInsnException(mi, mmIndex, insn);
            } else if (insn == 0x100073) {
                EnvTrapIntInstructions.executeEBREAK(
                    mi,
                    mmIndex
                );
                return executeStatus.retired;
            }
        } else if (insn > 0x10200073) {
            if (insn == 0x10500073) {
                if (!EnvTrapIntInstructions.executeWFI(
                    mi,
                    mmIndex
                )) {
                    return raiseIllegalInsnException(mi, mmIndex, insn);
                }
                return advanceToNextInsn(mi, mmIndex, pc);
            } else if (insn == 0x30200073) {
                if (!EnvTrapIntInstructions.executeMRET(
                    mi,
                    mmIndex
                )) {
                    return raiseIllegalInsnException(mi, mmIndex, insn);
                }
                return executeStatus.retired;
            }
        } else if (insn == 0x10200073) {
            if (!EnvTrapIntInstructions.executeSRET(
                mi,
                mmIndex
                )
               ) {
                return raiseIllegalInsnException(mi, mmIndex, insn);
            }
            return executeStatus.retired;
        }
        return executeSfenceVma(
            mi,
            mmIndex,
            insn,
            pc
        );
    }

    // \brief Given a load funct3 group instruction, finds the function
    // \param mi Memory Interactor with which Step function is interacting.
    // \param mmIndex Index corresponding to the instance of Memory Manager that.
    // \param insn for load funct3 field
    // \param pc.
    //  \details Uses binary search for performance.
    function loadFunct3(
        MemoryInteractor mi,
        uint256 mmIndex,
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
                    mmIndex,
                    insn,
                    pc,
                    8,
                    true
                );

            } else if (funct3 == 0x0002) {
                //return "LW";
                return executeLoad(
                    mi,
                    mmIndex,
                    insn,
                    pc,
                    32,
                    true
                );
            } else if (funct3 == 0x0001) {
                //return "LH";
                return executeLoad(
                    mi,
                    mmIndex,
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
                    mmIndex,
                    insn,
                    pc,
                    8,
                    false
                );
            } else if (funct3 == 0x0006) {
                //return "LWU";
                return executeLoad(
                    mi,
                    mmIndex,
                    insn,
                    pc,
                    32,
                    false
                );
            } else if (funct3 == 0x0005) {
                //return "LHU";
                return executeLoad(
                    mi,
                    mmIndex,
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
                mmIndex,
                insn,
                pc,
                64,
                true
            );
        }
        return raiseIllegalInsnException(mi, mmIndex, insn);
    }

    //  @param insn for atomic funct3Funct5 field
    function atomicFunct3Funct5(
        MemoryInteractor mi,
        uint256 mmIndex,
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
                    mmIndex,
                    insn,
                    32
                );
            } else {
                return raiseIllegalInsnException(mi, mmIndex, insn);
            }
        } else if (funct3Funct5 == 0x43) {
            atomSucc = AtomicInstructions.executeSC(
                mi,
                mmIndex,
                insn,
                32
            );
        } else if (funct3Funct5 == 0x41) {
            atomSucc = AtomicInstructions.executeAMOSWAPW(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x40) {
            atomSucc = AtomicInstructions.executeAMOADDW(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x44) {
            atomSucc = AtomicInstructions.executeAMOXORW(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x4c) {
            atomSucc = AtomicInstructions.executeAMOANDW(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x48) {
            atomSucc = AtomicInstructions.executeAMOORW(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x50) {
            atomSucc = AtomicInstructions.executeAMOMINW(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x54) {
            atomSucc = AtomicInstructions.executeAMOMAXW(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x58) {
            atomSucc = AtomicInstructions.executeAMOMINUW(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x5c) {
            atomSucc = AtomicInstructions.executeAMOMAXUW(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x62) {
            if ((insn & 0x1f00000) == 0 ) {
                atomSucc = AtomicInstructions.executeLR(
                    mi,
                    mmIndex,
                    insn,
                    64
                );
            }
        } else if (funct3Funct5 == 0x63) {
            atomSucc = AtomicInstructions.executeSC(
                mi,
                mmIndex,
                insn,
                64
            );
        } else if (funct3Funct5 == 0x61) {
            atomSucc = AtomicInstructions.executeAMOSWAPD(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x60) {
            atomSucc = AtomicInstructions.executeAMOADDD(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x64) {
            atomSucc = AtomicInstructions.executeAMOXORD(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x6c) {
            atomSucc = AtomicInstructions.executeAMOANDD(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x68) {
            atomSucc = AtomicInstructions.executeAMOORD(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x70) {
            atomSucc = AtomicInstructions.executeAMOMIND(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x74) {
            atomSucc = AtomicInstructions.executeAMOMAXD(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x78) {
            atomSucc = AtomicInstructions.executeAMOMINUD(
                mi,
                mmIndex,
                insn
            );
        } else if (funct3Funct5 == 0x7c) {
            atomSucc = AtomicInstructions.executeAMOMAXUD(
                mi,
                mmIndex,
                insn
            );
        }
        if (atomSucc) {
            return advanceToNextInsn(mi, mmIndex, pc);
        } else {
            return executeStatus.retired;
        }
        return raiseIllegalInsnException(mi, mmIndex, insn);
    }

    enum executeStatus {
        illegal, // Exception was raised
        retired // Instruction retired - having raised or not an exception
    }
}
