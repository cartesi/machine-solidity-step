// @title RiscVDecoder
pragma solidity ^0.5.0;

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
  function insn_opcode(uint32 insn) public returns (uint32){
    return insn & 0x7F;
  }

  /// @notice Get the instruction's funct3 field
  //  @param insn Instruction
  function insn_funct3(uint32 insn) public returns (uint32){
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
