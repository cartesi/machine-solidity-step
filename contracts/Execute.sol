/// @title Execute
pragma solidity ^0.5.0;

import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "../contracts/MemoryInteractor.sol";
import "./RiscVInstructions/BranchInstructions.sol";
import "./RiscVInstructions/ArithmeticInstructions.sol";
import "./RiscVInstructions/ArithmeticImmediateInstructions.sol";

library Execute {
  event  Print(string a, uint b);
  function execute_insn(uint256 _mmIndex, address _miAddress, uint32 insn, uint64 pc) 
  public returns (execute_status) {
    MemoryInteractor mi = MemoryInteractor(_miAddress);
    uint256 mmIndex = _mmIndex;

    // Find instruction associated with that opcode
    // Sometimes the opcode fully defines the associated instructions, but most
    // of the times it only specifies which group it belongs to.
    // For example, an opcode of: 01100111 is always a LUI instruction but an
    // opcode of 1100011 might be BEQ, BNE, BLT etc
    // Reference: riscv-spec-v2.2.pdf - Table 19.2 - Page 104
     return opinsn(mi, mmIndex, insn, pc);
  }
  function execute_arithmetic_immediate(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns (execute_status){
    uint32 rd = RiscVDecoder.insn_rd(insn);
    if(rd != 0){
      uint64 rs1 = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
      int32 imm = RiscVDecoder.insn_I_imm(insn);

      mi.write_x(mmIndex, rd, arithmetic_immediate_funct3(insn, rs1, imm));
    }
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  function execute_arithmetic(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc) 
  public returns (execute_status){
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if(rd != 0){
      uint64 rs1 = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
      uint64 rs2 = mi.read_x(mmIndex, RiscVDecoder.insn_rs2(insn));

      mi.write_x(mmIndex, rd, arithmetic_funct3_funct7(insn, rs1, rs2));
    }
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  function execute_branch(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc) 
  public returns (execute_status){

    uint64 rs1 = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
    uint64 rs2 = mi.read_x(mmIndex, RiscVDecoder.insn_rs2(insn));

    if(branch_funct3(insn, rs1, rs2)){
      uint64 new_pc = uint64(int64(pc) + int64(RiscVDecoder.insn_B_imm(insn)));
      if((new_pc & 3) != 0) {
        return raise_misaligned_fetch_exception(new_pc);
      }else {
        return execute_jump(mi, mmIndex, new_pc);
      }
    }
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  // JAL (i.e Jump and Link). J_immediate encondes a signed offset in multiples
  // of 2 bytes. The offset is added to pc and JAL stores the address of the jump
  // (pc + 4) to the rd register.
  // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 16
  function execute_jal(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns (execute_status){
    uint64 new_pc = pc + uint64(RiscVDecoder.insn_J_imm(insn));

    if((new_pc & 3) != 0){
      return raise_misaligned_fetch_exception(new_pc);
    }
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if(rd != 0){
      mi.write_x(mmIndex, rd, pc + 4);
    }
    return execute_jump(mi, mmIndex, new_pc);
  }

  //AUIPC forms a 32-bit offset from the 20-bit U-immediate, filling in the 
  // lowest 12 bits with zeros, adds this offset to pc and store the result on rd.
  // Reference: riscv-spec-v2.2.pdf -  Page 14
  function execute_auipc(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns (execute_status){
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if(rd != 0){
      mi.write_x(mmIndex, rd, pc + uint64(RiscVDecoder.insn_U_imm(insn)));
    }
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  function execute_jump(MemoryInteractor mi, uint256 mmIndex, uint64 new_pc) public returns (execute_status){
    mi.memoryWrite(mmIndex, ShadowAddresses.get_pc(), new_pc);
    return execute_status.retired;
  }

  function raise_misaligned_fetch_exception(uint64 pc) public returns (execute_status){
    // TO-DO: Raise excecption - Misaligned fetch
    return execute_status.retired;
  }

  function advance_to_next_insn(MemoryInteractor mi, uint256 mmIndex, uint64 pc) 
  public returns (execute_status){
    mi.memoryWrite(mmIndex, ShadowAddresses.get_pc(), pc + 4);
    //emit Print("advance_to_next", 0);
    return execute_status.retired;
  }

  /// @notice Given a arithmetic funct3 funct7 insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for arithmetic 32 funct3 funct7 field.
  function arithmetic_funct3_funct7(uint32 insn, uint64 rs1, uint64 rs2) public returns (uint64) {
    uint32 funct3_funct7 = RiscVDecoder.insn_funct3_funct7(insn);
    if(funct3_funct7 < 0x0181){
      if(funct3_funct7 < 0x0081){
        if(funct3_funct7 < 0x0020){
          if(funct3_funct7 == 0x0000){
            /*funct3_funct7 == 0x0000*/
            // return "ADD";
            return ArithmeticInstructions.execute_ADD(rs1, rs2);
          }else if(funct3_funct7 == 0x0001){
            /*funct3_funct7 == 0x0001*/
            //return "MUL";
            return ArithmeticInstructions.execute_MUL(rs1, rs2);
          }
        }else if(funct3_funct7 == 0x0080){
          /*funct3_funct7 == 0x0080*/
          //return "SLL";
          return ArithmeticInstructions.execute_SLL(rs1, rs2);
        }else if(funct3_funct7 == 0x0020){
          /*funct3_funct7 == 0x0020*/
          //return "SUB";
          return ArithmeticInstructions.execute_SUB(rs1, rs2);
        }
      }else if(funct3_funct7 > 0x0081){
        if(funct3_funct7 == 0x0100){
          /*funct3_funct7 == 0x0100*/
          //return "SLT";
          return ArithmeticInstructions.execute_SLT(rs1, rs2);
        }else if(funct3_funct7 == 0x0180){
          /*funct3_funct7 == 0x0180*/
          //return "SLTU";
          return ArithmeticInstructions.execute_SLTU(rs1, rs2);
        }else if(funct3_funct7 == 0x0101){
          /*funct3_funct7 == 0x0101*/
          //return "MULHSU";
          return ArithmeticInstructions.execute_MULHSU(rs1, rs2);
        }
      }else if(funct3_funct7 == 0x0081){
        /* funct3_funct7 == 0x0081*/
        //return "MULH";
        return ArithmeticInstructions.execute_MULH(rs1, rs2);
      }
    }else if(funct3_funct7 > 0x0181){
      if(funct3_funct7 < 0x02a0){
        if(funct3_funct7 == 0x0200){
          /*funct3_funct7 == 0x0200*/
          //return "XOR";
          return ArithmeticInstructions.execute_XOR(rs1, rs2);
        }else if(funct3_funct7 > 0x0201){
          if(funct3_funct7 ==  0x0280){
            /*funct3_funct7 == 0x0280*/
            //return "SRL";
            return ArithmeticInstructions.execute_SRL(rs1, rs2);
          }else if(funct3_funct7 == 0x0281){
            /*funct3_funct7 == 0x0281*/
            //return "DIVU";
            return ArithmeticInstructions.execute_DIVU(rs1, rs2);
          }
        }else if(funct3_funct7 == 0x0201){
          /*funct3_funct7 == 0x0201*/
          //return "DIV";
          return ArithmeticInstructions.execute_DIV(rs1, rs2);
        }
      }else if(funct3_funct7 > 0x02a0){
        if(funct3_funct7 < 0x0380){
          if(funct3_funct7 == 0x0300){
            /*funct3_funct7 == 0x0300*/
            //return "OR";
            return ArithmeticInstructions.execute_OR(rs1, rs2);
          }else if(funct3_funct7 == 0x0301){
            /*funct3_funct7 == 0x0301*/
            //return "REM";
            return ArithmeticInstructions.execute_REM(rs1, rs2);
          }
        }else if(funct3_funct7 == 0x0381){
          /*funct3_funct7 == 0x0381*/
          //return "REMU";
          return ArithmeticInstructions.execute_REMU(rs1, rs2);
        }else if(funct3_funct7 == 0x380){
          /*funct3_funct7 == 0x0380*/
          //return "AND";
          return ArithmeticInstructions.execute_AND(rs1, rs2);
        }
      }else if(funct3_funct7 == 0x02a0){
        /*funct3_funct7 == 0x02a0*/
        //return "SRA";
        return ArithmeticInstructions.execute_SRA(rs1, rs2);
      }
    }else if(funct3_funct7 == 0x0181){
      /*funct3_funct7 == 0x0181*/
      //return "MULHU";
      return ArithmeticInstructions.execute_MULHU(rs1, rs2);
    }
    return 0;
    //return "illegal insn";
  }

  /// @notice Given a arithmetic immediate funct3 insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for arithmetic immediate funct3 field.
  function arithmetic_immediate_funct3(uint32 insn, uint64 rs1, int32 imm) public returns (uint64) {
    uint32 funct3 = RiscVDecoder.insn_funct3(insn);
    if(funct3 < 0x0003){
      if(funct3 == 0x0000){
        /*funct3 == 0x0000*/
//        return "ADDI";
        return ArithmeticImmediateInstructions.execute_ADDI(rs1, imm);

      }else if(funct3 == 0x0002){
        /*funct3 == 0x0002*/
//        return "SLTI";
      }else if(funct3 == 0x0001){
        /*funct3 == 0x0001*/
//        return "SLLI";
      }
    }else if(funct3 > 0x0003){
      if(funct3 < 0x0006){
        if(funct3 == 0x0004){
          /*funct3 == 0x0004*/
//          return "XORI";
        }else if(funct3 == 0x0005){
          /*funct3 == 0x0005*/
//          return "shift_right_immediate_group";
        }
      }else if(funct3 == 0x0007){
        /*funct3 == 0x0007*/
//        return "ANDU";
      }else if(funct3 == 0x0006){
        /*funct3 == 0x0006*/
//        return "ORI";
        return ArithmeticImmediateInstructions.execute_ORI(rs1, imm);
      }
    }else if(funct3 == 0x0003){
      /*funct3 == 0x0003*/
//      return "SLTIU";
    }
//    return "illegal insn";
    return 0;
  }


  /// @notice Given a branch funct3 group instruction, finds the function
  //  associated with it. Uses binary search for performance.
  //  @param insn for branch funct3 field.
  function branch_funct3(uint32 insn, uint64 rs1, uint64 rs2) public returns (bool){
    uint32 funct3 = RiscVDecoder.insn_funct3(insn);

    if(funct3 < 0x0005){
      if(funct3 == 0x0000){
        /*funct3 == 0x0000*/
        //return "BEQ";
        return BranchInstructions.execute_BEQ(rs1, rs2);
      }else if(funct3 == 0x0004){
        /*funct3 == 0x0004*/
        //return "BLT";
        return BranchInstructions.execute_BLT(rs1, rs2);
      }else if(funct3 == 0x0001){
        /*funct3 == 0x0001*/
        //return "BNE";
        return BranchInstructions.execute_BNE(rs1, rs2);
      }
    }else if(funct3 > 0x0005){
      if(funct3 == 0x0007){
        /*funct3 == 0x0007*/
        //return "BGEU";
        return BranchInstructions.execute_BGEU(rs1, rs2);
      }else if(funct3 == 0x0006){
        /*funct3 == 0x0006*/
        //return "BLTU";
        return BranchInstructions.execute_BLTU(rs1, rs2);
      }
    }else if(funct3 == 0x0005){
      /*funct3==0x0005*/
      //return "BGE";
      return BranchInstructions.execute_BGE(rs1, rs2);
    }
   //return "illegal insn";
   // TO-DO: this shouldnt be a return false
   return false;
  }

  /// @notice Given an op code, finds the group of instructions it belongs to
  //  using a binary search for performance.
  //  @param insn for opcode fields.
  function opinsn(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc) public returns (execute_status){
    // OPCODE is located on bit 0 - 6 of the following types of 32bits instructions:
    // R-Type, I-Type, S-Trype and U-Type
    // Reference: riscv-spec-v2.2.pdf - Figure 2.2 - Page 11
    uint32 opcode = RiscVDecoder.insn_opcode(insn);

    if(opcode < 0x002f){
      if(opcode < 0x0017){
        if(opcode == 0x0003){
          /*opcode is 0x0003*/
         // return "load_group";
          return execute_status.retired;
        }else if(opcode == 0x000f){
          /*insn is 0x000f*/
          //return "fence_group";
          return execute_status.retired;
        }else if(opcode == 0x0013){
          /*opcode is 0x0013*/
          return execute_arithmetic_immediate(mi, mmIndex, insn, pc);
        }
      }else if (opcode > 0x0017){
        if (opcode == 0x001b){
          /*opcode is 0x001b*/
          //return "arithmetic_immediate_32_group";
          return execute_status.retired;
        }else if(opcode == 0x0023){
          /*opcode is 0x0023*/
          //return "store_group";
          return execute_status.retired;
        }
      }else if(opcode == 0x0017){
        /*opcode == 0x0017*/
        return execute_auipc(mi, mmIndex, insn, pc);
      }
    }else if (opcode > 0x002f){
      if (opcode < 0x0063){
        if (opcode == 0x0033){
          /*opcode is 0x0033*/
          //return "arithmetic_group";
          return execute_status.retired;
        }else if (opcode == 0x003b){
          /*opcode is 0x003b*/
          //return "arithmetic_32_group";
          return execute_status.retired;
        }else if(opcode == 0x0037){
          /*opcode == 0x0037*/
          //return "LUI";
          return execute_status.retired;
        }
      }else if (opcode > 0x0063){
        if(opcode == 0x0067){
          /*opcode == 0x0067*/
          //return "JALR";
          return execute_status.retired;
        }else if(opcode == 0x0073){
          /*opcode == 0x0073*/
          //return "csr_env_trap_int_mm_group";
          return execute_status.retired;
        }else if(opcode == 0x006f){
          /*opcode == 0x006f*/
          //return "JAL";
          return execute_jal(mi, mmIndex, insn, pc);
        }
      }else if (opcode == 0x0063){
        /*opcode == 0x0063*/
        //return "branch_group";
        return execute_branch(mi, mmIndex, insn, pc);
      }
    }else if(opcode == 0x002f){
      /*opcode == 0x002f*/
      //return "atomic_group";
      return execute_status.retired;
    }
    //return "illegal insn";
    return execute_status.retired;
  }

  enum execute_status {
    illegal, // Exception was raised
    retired // Instruction retired - having raised or not an exception
  }
}
