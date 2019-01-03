// @title RiscVDecoder
pragma solidity ^0.5.0;

import "./RiscVInstructions/BranchInstructions.sol";
import "./RiscVInstructions/ArithmeticInstructions.sol";

//TO-DO: Implement illegal instruction
library RiscVDecoder {
  // Contract responsible for decoding the riscv's instructions
  // It applies different bitwise operations and masks to reach
  // specific positions and use that positions to identify the
  // correct function to be executed

  /// @notice Get the instruction's RD
  //  @param insn Instruction
  function insn_rd(uint32 insn) public returns(uint32){
    return (insn >> 7) & 0x1F;
  }

  /// @notice Get the instruction's RS1
  //  @param insn Instruction
  function insn_rs1(uint32 insn) public returns(uint32){
    return (insn >> 15) & 0x1F;
  }

  /// @notice Get the instruction's RS2
  //  @param insn Instruction
  function insn_rs2(uint32 insn) public returns(uint32){
    return (insn >> 20) & 0x1F;
  }

  /// @notice Get the I-type instruction's immediate value
  //  @param insn Instruction
  function insn_I_imm(uint32 insn) public returns(int32){
     return int32(insn >> 20);
  }

  /// @notice Get the I-type instruction's unsigned immediate value
  //  @param insn Instruction
  function insn_I_uimm(uint32 insn) public returns(uint32){
    return insn >> 20;
  }

  /// @notice Get the U-type instruction's immediate value
  //  @param insn Instruction
  function insn_U_imm(uint32 insn) public returns(int32){
    return int32(insn & 0xfffff000);
  }

  /// @notice Get the B-type instruction's immediate value
  //  @param insn Instruction
  function insn_B_imm(uint32 insn) public returns(int32){
    int32 imm = int32(((insn >> (31 - 12)) & (1 << 12)) |
                  ((insn >> (25 - 5)) & 0x7e0) |
                  ((insn >> (8 - 1)) & 0x1e) |
                  ((insn << (11 - 7)) & (1 << 11)));
    //TO-DO: use arithmetic shift on BitManipulation library
    //int shift - cant do
    imm = (imm << 19) >> 19;
    return imm;
  }

  /// @notice Get the J-type instruction's immediate value
  //  @param insn Instruction
  function insn_J_imm(uint32 insn) public returns(int32){
    int32 imm = int32(((insn >> (31 - 20)) & (1 << 20)) |
                ((insn >> (21 - 1)) & 0x7fe) |
                ((insn >> (20 - 11)) & (1 << 11)) |
                (insn & 0xff000));
    //TO-DO: use arithmetic shift on BitManipulation library
    //int shift - cant do
    imm = (imm << 11) >> 11;
    return imm;
  }

  /// @notice Get the S-type instruction's immediate value
  //  @param insn Instruction
  function insn_S_imm(uint32 insn) public returns(int32){
    return int32(((insn & 0xfe000000) >> (25 - 5)) | ((insn>> 7) & 0x1F));
  }

  /// @notice Get the instruction's opcode field
  //  @param insn Instruction
  function inst_opcode(uint32 insn) public returns (uint32){
    return insn & 0x7F;
  }

  /// @notice Get the instruction's funct3 field
  //  @param insn Instruction
  function inst_funct3(uint32 insn) public returns (uint32){
    return (insn >> 12) & 0x07;
  }

  /// @notice Get the concatenation of instruction's funct3 and funct7 fields
  //  @param insn Instruction
  function insn_funct3_funct7(uint32 insn) public returns (uint32){
    return ((insn >> 5) & 0x380) | (insn >> 25);
  }

  /// @notice Get the concatenation of instruction's funct3 and funct5 fields
  //  @param insn Instruction
  function insn_funct3_funct5(uint32 insn) public returns (uint32){
    return ((insn >> 7) & 0xE0) | (insn >> 27);
  }

  /// @notice Get the instruction's funct7 field
  //  @param insn Instruction
  function insn_funct7(uint32 insn) public returns (uint32){
    return (insn >> 25) & 0x7F;
  }

  /// @notice Get the instruction's funct6 field
  //  @param insn Instruction
  function insn_funct6(uint32 insn) public returns (uint32){
    return (insn >> 26) & 0x3F;
  }

  /// @notice Given an op code, finds the group of instructions it belongs to
  //  using a binary search for performance.
  //  @param insn for opcode fields.
  function opinsn(uint32 insn) public returns (bytes32){
    if(insn < 0x002f){
      if(insn < 0x0017){
        if(insn == 0x0003){
          /*insn is 0x0003*/
          return "load_group";
        }else if(insn == 0x000f){
          /*insn is 0x000f*/
          return "fence_group";
        }else if(insn == 0x0013){
          /*insn is 0x0013*/
          return "arithmetic_immediate_group";
        }
      }else if (insn > 0x0017){
        if (insn == 0x001b){
          /*insn is 0x001b*/
          return "arithmetic_immediate_32_group";
        }else if(insn == 0x0023){
          /*insn is 0x0023*/
          return "store_group";
        }
      }else if(insn == 0x0017){
        /*insn == 0x0017*/
        return "AUIPC";
      }
    }else if (insn > 0x002f){
      if (insn < 0x0063){
        if (insn == 0x0033){
          /*insn is 0x0033*/
          return "arithmetic_group";
        }else if (insn == 0x003b){
          /*insn is 0x003b*/
          return "arithmetic_32_group";
        }else if(insn == 0x0037){
          /*insn == 0x0037*/
          return "LUI";
        }
      }else if (insn > 0x0063){
        if(insn == 0x0067){
          /*insn == 0x0067*/
          return "JALR";
        }else if(insn == 0x0073){
          /*insn == 0x0073*/
          return "csr_env_trap_int_mm_group";
        }else if(insn == 0x006f){
          /*insn == 0x006f*/
          return "JAL";
        }
      }else if (insn == 0x0063){
        /*insn == 0x0063*/
        return "branch_group";
      }
    }else if(insn == 0x002f){
      /*insn == 0x002f*/
      return "atomic_group";
    }
    return "illegal insn";
  }

  /// @notice Given a branch funct3 group instruction, finds the function
  //  associated with it. Uses binary search for performance.
  //  @param insn for branch funct3 field.
  function branch_funct3(uint32 insn, uint64 rs1, uint64 rs2) public returns (bool){
    if(insn < 0x0005){
      if(insn == 0x0000){
        /*insn == 0x0000*/
        //return "BEQ";
        return BranchInstructions.execute_BEQ(rs1, rs2);
      }else if(insn == 0x0004){
        /*insn == 0x0004*/
        //return "BLT";
        return BranchInstructions.execute_BLT(rs1, rs2);
      }else if(insn == 0x0001){
        /*insn == 0x0001*/
        //return "BNE";
        return BranchInstructions.execute_BNE(rs1, rs2);
      }
    }else if(insn > 0x0005){
      if(insn == 0x0007){
        /*insn == 0x0007*/
        //return "BGEU";
        return BranchInstructions.execute_BGEU(rs1, rs2);
      }else if(insn == 0x0006){
        /*insn == 0x0006*/
        //return "BLTU";
        return BranchInstructions.execute_BLTU(rs1, rs2);
      }
    }else if(insn == 0x0005){
      /*insn==0x0005*/
      //return "BGE";
      return BranchInstructions.execute_BGE(rs1, rs2);
    }
   //return "illegal insn";
   return false;
  }

  /// @notice Given a load funct3 group instruction, finds the function
  //  associated with it. Uses binary search for performance
  //  @param insn for load funct3 field
  function load_funct3(uint32 insn) public returns (bytes32){
    if(insn < 0x0003){
      if(insn == 0x0000){
        /*insn == 0x0000*/
        return "LB";
      }else if(insn == 0x0002){
        /*insn == 0x0002*/
        return "LW";
      }else if(insn == 0x0001){
        /*insn == 0x0001*/
        return "LH";
      }
    }else if(insn > 0x0003){
      if(insn == 0x0004){
        /*insn == 0x0004*/
        return "LBU";
      }else if(insn == 0x0006){
        /*insn == 0x0006*/
        return "LWU";
      }else if(insn == 0x0005){
        /*insn == 0x0005*/
        return "LHU";
      }
    }else if(insn == 0x0003){
      /*insn == 0x0003*/
      return "LD";
    }
    return "illegal insn";
  }

  /// @notice Given a store funct3 group insn, finds the function  associated.
  //  Uses binary search for performance
  //  @param insn for store funct3 field
  function store_funct3(uint32 insn) public returns (bytes32){
    if(insn == 0x0000){
      /*insn == 0x0000*/
      return "SB";
    }else if(insn > 0x0001){
      if(insn == 0x0002){
        /*insn == 0x0002*/
        return "SW";
      }else if(insn == 0x0003){
        /*insn == 0x0003*/
        return "SD";
      }
    }else if(insn == 0x0001){
      /*insn == 0x0001*/
      return "SH";
    }
    return "illegal insn";
  }

  /// @notice Given a arithmetic immediate funct3 insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for arithmetic immediate funct3 field.
  function arithmetic_immediate_funct3(uint32 insn) public returns (bytes32) {
    if(insn < 0x0003){
      if(insn == 0x0000){
        /*insn == 0x0000*/
        return "ADDI";
      }else if(insn == 0x0002){
        /*insn == 0x0002*/
        return "SLTI";
      }else if(insn == 0x0001){
        /*insn == 0x0001*/
        return "SLLI";
      }
    }else if(insn > 0x0003){
      if(insn < 0x0006){
        if(insn == 0x0004){
          /*insn == 0x0004*/
          return "XORI";
        }else if(insn == 0x0005){
          /*insn == 0x0005*/
          return "shift_right_immediate_group";
        }
      }else if(insn == 0x0007){
        /*insn == 0x0007*/
        return "ANDU";
      }else if(insn == 0x0006){
        /*insn == 0x0006*/
        return "ORI";
      }
    }else if(insn == 0x0003){
      /*insn == 0x0003*/
      return "SLTIU";
    }
    return "illegal insn";
  }

  /// @notice Given a right immediate funct6 insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for right immediate funct6 field.
  function shift_right_immediate_funct6(uint32 insn) public returns (bytes32) {
    if(insn == 0x0000){
      /*insn == 0x0000*/
      return "SRLI";
    }else if(insn == 0x0010){
      /*insn == 0x0010*/
      return "SRAI";
    }
    return "illegal insn";
  }

  /// @notice Given a arithmetic funct3 funct7 insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for arithmetic 32 funct3 funct7 field.
  function arithmetic_funct3_funct7(uint32 insn, uint64 rs1, uint64 rs2) public returns (uint64) {
    if(insn < 0x0181){
      if(insn < 0x0081){
        if(insn < 0x0020){
          if(insn == 0x0000){
            /*insn == 0x0000*/
            // return "ADD";
            return ArithmeticInstructions.execute_ADD(rs1, rs2);
          }else if(insn == 0x0001){
            /*insn == 0x0001*/
            //return "MUL";
            return ArithmeticInstructions.execute_MUL(rs1, rs2);
          }
        }else if(insn == 0x0080){
          /*insn == 0x0080*/
          //return "SLL";
          return ArithmeticInstructions.execute_SLL(rs1, rs2);
        }else if(insn == 0x0020){
          /*insn == 0x0020*/
          //return "SUB";
          return ArithmeticInstructions.execute_SUB(rs1, rs2);
        }
      }else if(insn > 0x0081){
        if(insn == 0x0100){
          /*insn == 0x0100*/
          //return "SLT";
          return ArithmeticInstructions.execute_SLT(rs1, rs2);
        }else if(insn == 0x0180){
          /*insn == 0x0180*/
          //return "SLTU";
          return ArithmeticInstructions.execute_SLTU(rs1, rs2);
        }else if(insn == 0x0101){
          /*insn == 0x0101*/
          //return "MULHSU";
          return ArithmeticInstructions.execute_MULHSU(rs1, rs2);
        }
      }else if(insn == 0x0081){
        /* insn == 0x0081*/
        //return "MULH";
        return ArithmeticInstructions.execute_MULH(rs1, rs2);
      }
    }else if(insn > 0x0181){
      if(insn < 0x02a0){
        if(insn == 0x0200){
          /*insn == 0x0200*/
          //return "XOR";
          return ArithmeticInstructions.execute_XOR(rs1, rs2);
        }else if(insn > 0x0201){
          if(insn ==  0x0280){
            /*insn == 0x0280*/
            //return "SRL";
            return ArithmeticInstructions.execute_SRL(rs1, rs2);
          }else if(insn == 0x0281){
            /*insn == 0x0281*/
            //return "DIVU";
            return ArithmeticInstructions.execute_DIVU(rs1, rs2);
          }
        }else if(insn == 0x0201){
          /*insn == 0x0201*/
          //return "DIV";
          return ArithmeticInstructions.execute_DIV(rs1, rs2);
        }
      }else if(insn > 0x02a0){
        if(insn < 0x0380){
          if(insn == 0x0300){
            /*insn == 0x0300*/
            //return "OR";
            return ArithmeticInstructions.execute_OR(rs1, rs2);
          }else if(insn == 0x0301){
            /*insn == 0x0301*/
            //return "REM";
            return ArithmeticInstructions.execute_REM(rs1, rs2);
          }
        }else if(insn == 0x0381){
          /*insn == 0x0381*/
          //return "REMU";
          return ArithmeticInstructions.execute_REMU(rs1, rs2);
        }else if(insn == 0x380){
          /*insn == 0x0380*/
          //return "AND";
          return ArithmeticInstructions.execute_AND(rs1, rs2);
        }
      }else if(insn == 0x02a0){
        /*insn == 0x02a0*/
        //return "SRA";
        return ArithmeticInstructions.execute_SRA(rs1, rs2);
      }
    }else if(insn == 0x0181){
      /*insn == 0x0181*/
      //return "MULHU";
      return ArithmeticInstructions.execute_MULHU(rs1, rs2);
    }
    return 0;
    //return "illegal insn";
  }

  /// @notice Given a fence funct3 insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for fence funct3 field.
  function fence_group_funct3(uint32 insn) public returns(bytes32){
    if(insn == 0x0000){
      /*insn == 0x0000*/
      return "FENCE";
    }else if(insn == 0x0001){
      /*insn == 0x0001*/
      return "FENCE_I";
    }
    return "illegal insn";
  }

  /// @notice Given a env trap int group insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for env trap int group field.
  function env_trap_int_group_insn(uint32 insn) public returns (bytes32){
    if(insn < 0x10200073){
      if(insn == 0x0073){
        /*insn == 0x0073*/
        return "ECALL";
      }else if(insn == 0x200073){
        /*insn == 0x200073*/
        return "URET";
      }else if(insn == 0x100073){
        /*insn == 0x100073*/
        return "EBREAK";
      }
    }else if(insn > 0x10200073){
      if(insn == 0x10500073){
        /*insn == 0x10500073*/
        return "WFI";
      }else if(insn == 0x30200073){
        /*insn == 0x30200073*/
        return "MRET";
      }
    }else if(insn == 0x10200073){
      /*insn = 0x10200073*/
      return "SRET";
    }
    return "illegal expression";
  }

  /// @notice Given csr env trap int mm funct3 insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for csr env trap int mm funct3 field.
  function csr_env_trap_int_mm_funct3(uint32 insn) public returns (bytes32){
    if(insn < 0x0003){
      if(insn == 0x0000){
        /*insn == 0x0000*/
        return "env_trap_int_mm_group";
      }else if(insn ==  0x0002){
        /*insn == 0x0002*/
        return "CSRRS";
      }else if(insn == 0x0001){
        /*insn == 0x0001*/
        return "CSRRW";
      }
    }else if(insn > 0x0003){
      if(insn == 0x0005){
        /*insn == 0x0005*/
        return "CSRRWI";
      }else if(insn == 0x0007){
        /*insn == 0x0007*/
        return "CSRRCI";
      }else if(insn == 0x0006){
        /*insn == 0x0006*/
        return "CSRRSI";
      }
    }else if(insn == 0x0003){
      /*insn == 0x0003*/
      return "CSRRC";
    }
    return "illegal insn";
  }

  /// @notice Given a arithmetic immediate32 funct3 insn, finds the associated func.
  //  Uses binary search for performance.
  //  @param insn for arithmetic immediate32 funct3 field.
  function arithmetic_immediate_32_funct3(uint32 insn) public returns (bytes32){
    if(insn == 0x0000){
      /*insn == 0x0000*/
      return "ADDI";
    }else if(insn ==  0x0005){
      /*insn == 0x0005*/
      return "shift_right_immediate_32_group";
    }else if(insn == 0x0001){
      /*insn == 0x0001*/
      return "SLLIW";
    }
    return "illegal insn";
  }

  /// @notice Given a shift right immediate32 funct3 insn, finds the associated func.
  //  Uses binary search for performance.
  //  @param insn for shift right immediate32 funct3 field.
  function shift_right_immediate_32_funct3(uint32 insn) public returns (bytes32){
    if(insn == 0x0000){
      /*insn == 0x0000*/
      return "SRLIW";
    }else if(insn == 0x0020){
      /*insn == 0x0020*/
      return "SRAIW";
    }
    return "illegal insn";
  }

  /// @notice Given an arithmetic32 funct3 funct7 insn, finds the associated func.
  //  Uses binary search for performance.
  //  @param insn for arithmetic32 funct3 funct7 field.
  function arithmetic_32_funct3_funct7(uint32 insn) public returns (bytes32){
    if(insn < 0x0280){
      if(insn < 0x0020){
        if(insn == 0x0000){
          /*insn == 0x0000*/
          return "ADDW";
        }else if(insn == 0x0001){
          /*insn == 0x0001*/
          return "MULW";
        }
      }else if(insn > 0x0020){
        if(insn == 0x0080){
          /*insn == 0x0080*/
          return "SLLW";
        }else if(insn == 0x0201){
          /*insn == 0x0201*/
          return "DIVUW";
        }
      }else if(insn == 0x0020){
        /*insn == 0x0020*/
        return "SUBW";
      }
    }else if(insn > 0x0280){
      if(insn < 0x0301){
        if(insn == 0x0281){
          /*insn == 0x0281*/
          return "DIVUW";
        }else if(insn == 0x02a0){
          /*insn == 0x02a0*/
          return "SRAW";
        }
      }else if(insn == 0x0381){
        /*insn == 0x0381*/
        return "REMUW";
      }else if(insn == 0x0301){
        /*insn == 0x0301*/
        return "REMW";
      }
    }else if(insn == 0x0280) {
      /*insn == 0x0280*/
      return "SRLW";
    }
    return "illegal insn";
  }
}
