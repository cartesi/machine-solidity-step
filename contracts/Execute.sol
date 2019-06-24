/// @title Execute
pragma solidity ^0.5.0;

import "./ShadowAddresses.sol";
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


    function executeInsn(
        uint256 mmIndex,
        address miAddress,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
        MemoryInteractor mi = MemoryInteractor(miAddress);

        // Find instruction associated with that opcode
        // Sometimes the opcode fully defines the associated instructions, but most
        // of the times it only specifies which group it belongs to.
        // For example, an opcode of: 01100111 is always a LUI instruction but an
        // opcode of 1100011 might be BEQ, BNE, BLT etc
        // Reference: riscv-spec-v2.2.pdf - Table 19.2 - Page 104
        return opinsn(
            mi,
            mmIndex,
            insn,
            pc
        );
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
                (arithImmResult, insnValid) = ArithmeticImmediateInstructions.arithmeticImmediate_32Funct3(mi, mmIndex, insn);
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
                (arithResult, insnValid) = ArithmeticInstructions.arithmetic_32Funct3Funct7(mi, mmIndex, insn);
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
            uint64 newPc = uint64(int64(pc) + int64(RiscVDecoder.insn_BImm(insn)));
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
        int32 imm = RiscVDecoder.insn_IImm(insn);
        (bool succ, uint64 val) = VirtualMemory.readVirtualMemory(
            mi,
            mmIndex,
            wordSize,
            vaddr + uint64(imm)
        );

        if (succ) {
            if (isSigned) {
                // TO-DO: make sure this is ok
                mi.writeX(mmIndex, RiscVDecoder.insnRd(insn), uint64(int64(val)));
            } else {
                mi.writeX(mmIndex, RiscVDecoder.insnRd(insn), val);
            }
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
            uint64 priv = mi.readIflags_PRV(mmIndex);
            uint64 mstatus = mi.readMstatus(mmIndex);

            if (priv == RiscVConstants.PRV_U() || (priv == RiscVConstants.PRV_S() && ((mstatus & RiscVConstants.MSTATUS_TVM_MASK() != 0)))) {
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
        mi.memoryWrite(mmIndex, ShadowAddresses.getPc(), newPc);
        return executeStatus.retired;
    }

    function raiseMisalignedFetchException(MemoryInteractor mi, uint256 mmIndex, uint64 pc)
    public returns (executeStatus)
    {
        Exceptions.raiseException(
            mi,
            mmIndex,
            Exceptions.MCAUSE_INSN_ADDRESS_MISALIGNED(),
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
            Exceptions.MCAUSE_ILLEGAL_INSN(),
            insn
        );
        return executeStatus.illegal;
    }

    function advanceToNextInsn(MemoryInteractor mi, uint256 mmIndex, uint64 pc)
    public returns (executeStatus)
    {
        mi.memoryWrite(mmIndex, ShadowAddresses.getPc(), pc + 4);
        //emit Print("advanceToNext", 0);
        return executeStatus.retired;
    }

    /// @notice Given a fence funct3 insn, finds the func associated.
    //  Uses binary search for performance.
    //  @param insn for fence funct3 field.
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

    /// @notice Given csr env trap int mm funct3 insn, finds the func associated.
    //  Uses binary search for performance.
    //  @param insn for csr env trap int mm funct3 field.
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
                if (CSRExecute.executeCsr_SC(
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
                if (CSRExecute.executeCsr_RW(
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
                if (CSRExecute.executeCsr_RW(
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
                if (CSRExecute.executeCsr_SCI(
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
                if (CSRExecute.executeCsr_SCI(
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
            if (CSRExecute.executeCsr_SC(
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

    /// @notice Given a store funct3 group insn, finds the function  associated.
    //  Uses binary search for performance
    //  @param insn for store funct3 field
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
            return S_Instructions.SB(
                mi,
                mmIndex,
                pc,
                insn
            ) ? advanceToNextInsn(mi, mmIndex, pc) : executeStatus.retired;
        } else if (funct3 > 0x0001) {
            if (funct3 == 0x0002) {
                /*funct3 == 0x0002*/
                //return "SW";
                return S_Instructions.SW(
                    mi,
                    mmIndex,
                    pc,
                    insn
                ) ? advanceToNextInsn(mi, mmIndex, pc) : executeStatus.retired;
            } else if (funct3 == 0x0003) {
                /*funct3 == 0x0003*/
                //return "SD";
                return S_Instructions.SD(
                    mi,
                    mmIndex,
                    pc,
                    insn
                ) ? advanceToNextInsn(mi, mmIndex, pc) : executeStatus.retired;
            }
        } else if (funct3 == 0x0001) {
            /*funct3 == 0x0001*/
            //return "SH";
            return S_Instructions.SH(
                mi,
                mmIndex,
                pc,
                insn
            ) ? advanceToNextInsn(mi, mmIndex, pc) : executeStatus.retired;
        }
        return raiseIllegalInsnException(mi, mmIndex, insn);
    }


    /// @notice Given a env trap int group insn, finds the func associated.
    //  Uses binary search for performance.
    //  @param insn for env trap int group field.
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
                    mmIndex,
                    insn,
                    pc
                );
                return executeStatus.retired;
            } else if (insn == 0x200073) {
                // No U-Mode traps
                raiseIllegalInsnException(mi, mmIndex, insn);
            } else if (insn == 0x100073) {
                EnvTrapIntInstructions.executeEBREAK(
                    mi,
                    mmIndex,
                    insn,
                    pc
                );
                return executeStatus.retired;
            }
        } else if (insn > 0x10200073) {
            if (insn == 0x10500073) {
                if (!EnvTrapIntInstructions.executeWFI(
                    mi,
                    mmIndex,
                    insn,
                    pc
                )) {
                    return raiseIllegalInsnException(mi, mmIndex, insn);
                }
                return advanceToNextInsn(mi, mmIndex, pc);
            } else if (insn == 0x30200073) {
                if (!EnvTrapIntInstructions.executeMRET(
                    mi,
                    mmIndex,
                    insn,
                    pc
                )) {
                    return raiseIllegalInsnException(mi, mmIndex, insn);
                }
                return executeStatus.retired;
            }
        } else if (insn == 0x10200073) {
            if (!EnvTrapIntInstructions.executeSRET(
                mi,
                mmIndex,
                insn,
                pc)
               ) {
                return raiseIllegalInsnException(mi, mmIndex, insn);
            }
            return executeStatus.retired;
        }
        return executeSFENCE_VMA(
            mi,
            mmIndex,
            insn,
            pc
        );
    }

    /// @notice Given a load funct3 group instruction, finds the function
    //  associated with it. Uses binary search for performance
    //  @param insn for load funct3 field
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
                    pc,
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
                pc,
                insn,
                32
            );
        } else if (funct3Funct5 == 0x41) {
            atomSucc = AtomicInstructions.executeAMOSWAP_W(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x40) {
            atomSucc = AtomicInstructions.executeAMOADD_W(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x44) {
            atomSucc = AtomicInstructions.executeAMOXOR_W(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x4c) {
            atomSucc = AtomicInstructions.executeAMOAND_W(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x48) {
            atomSucc = AtomicInstructions.executeAMOOR_W(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x50) {
            atomSucc = AtomicInstructions.executeAMOMIN_W(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x54) {
            atomSucc = AtomicInstructions.executeAMOMAX_W(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x58) {
            atomSucc = AtomicInstructions.executeAMOMINU_W(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x5c) {
            atomSucc = AtomicInstructions.executeAMOMAXU_W(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x62) {
            if ((insn & 0x1f00000) == 0 ) {
                atomSucc = AtomicInstructions.executeLR(
                    mi,
                    mmIndex,
                    pc,
                    insn,
                    64
                );
            }
        } else if (funct3Funct5 == 0x63) {
            atomSucc = AtomicInstructions.executeSC(
                mi,
                mmIndex,
                pc,
                insn,
                64
            );
        } else if (funct3Funct5 == 0x61) {
            atomSucc = AtomicInstructions.executeAMOSWAP_D(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x60) {
            atomSucc = AtomicInstructions.executeAMOADD_D(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x64) {
            atomSucc = AtomicInstructions.executeAMOXOR_D(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x6c) {
            atomSucc = AtomicInstructions.executeAMOAND_D(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x68) {
            atomSucc = AtomicInstructions.executeAMOOR_D(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x70) {
            atomSucc = AtomicInstructions.executeAMOMIN_D(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x74) {
            atomSucc = AtomicInstructions.executeAMOMAX_D(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x78) {
            atomSucc = AtomicInstructions.executeAMOMINU_D(
                mi,
                mmIndex,
                pc,
                insn
            );
        } else if (funct3Funct5 == 0x7c) {
            atomSucc = AtomicInstructions.executeAMOMAXU_D(
                mi,
                mmIndex,
                pc,
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

    /// @notice Given an op code, finds the group of instructions it belongs to
    //  using a binary search for performance.
    //  @param insn for opcode fields.
    function opinsn(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint64 pc
    )
    public returns (executeStatus)
    {
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
                }else if (opcode == 0x000f) {
                    return fenceGroup(
                        mi,
                        mmIndex,
                        insn,
                        pc
                    );
                }else if (opcode == 0x0013) {
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
                        insn,
                        pc
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

    enum executeStatus {
        illegal, // Exception was raised
        retired // Instruction retired - having raised or not an exception
    }
}
