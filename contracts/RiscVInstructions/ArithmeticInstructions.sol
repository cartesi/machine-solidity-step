/// @title ArithmeticInstructions

pragma solidity ^0.5.0;

// Overflow/Underflow behaviour in solidity is to allow them to happen freely.
// This mimics the RiscV behaviour, so we can use the arithmetic operators normally.
// RiscV-spec-v2.2 - Section 2.4:
// https://content.riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf
// Solidity docs Twos Complement/Underflow/Overflow: 
// https://solidity.readthedocs.io/en/latest/security-considerations.html?highlight=overflow#two-s-complement-underflows-overflows
import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";

library ArithmeticInstructions {
  // TO-DO: move XLEN to its own library
  uint constant XLEN = 64;

  // event Print(string message);
  function get_rs1_rs2(MemoryInteractor mi, uint256 mmIndex, uint32 insn) internal 
  returns(uint64 rs1, uint64 rs2) {
    rs1 = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
    rs2 = mi.read_x(mmIndex, RiscVDecoder.insn_rs2(insn));
  }

  function execute_ADD(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("ADD");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    //_builtin_add_overflow(rs1, rs2, &val)
    return rs1 + rs2;
  }

  function execute_SUB(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("SUB");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    //_builtin_sub_overflow(rs1, rs2, &val)
    return rs1 - rs2;
  }

  function execute_SLL(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("SLL");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return rs1 << (rs2 & (XLEN - 1));
  }

  function execute_SLT(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("SLT");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return (int64(rs1) < int64(rs2))? 1:0;
  }

  function execute_SLTU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("SLTU");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return (rs1 < rs2)? 1:0;
  }

  function execute_XOR(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("XOR");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return rs1 ^ rs2;
  }

  function execute_SRL(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("SRL");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return rs1 >> (rs2 & (XLEN-1));
  }

  function execute_SRA(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("SRA");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return uint64(int64(rs1) >> (rs2 & (XLEN-1)));
  }

  function execute_OR(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("OR");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return rs1 | rs2;
  }

  function execute_AND(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("AND");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return rs1 & rs2;
  }

  function execute_MUL(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("MUL");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    int64 srs1 = int64(rs1);
    int64 srs2 = int64(rs2);
    //_builtin_mul_overflow(srs1, srs2, &val);

    return uint64(srs1 * srs2);
  }

  //TO-DO: Use bitmanipulation library for shift
  function execute_MULH(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("MULH");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    int64 srs1 = int64(rs1);
    int64 srs2 = int64(rs2);

    //SHOULD BE ARITHMETIC SHIFT - >> of signed int
    return uint64((int128(srs1) * int128(srs2)) >> 64);
  }

  //TO-DO: Use bitmanipulation library for shift
  function execute_MULHSU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("MULHSU");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    int64 srs1 = int64(rs1);

    //SHOULD BE ARITHMETIC SHIFT - >> of signed int
    return uint64((int128(srs1) * int128(rs2)) >> 64);
  }

  //TO-DO: Use bitmanipulation library for shift
  function execute_MULHU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("MULHU");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    //SHOULD BE ARITHMETIC SHIFT - >> of signed int
    return uint64((int128(rs1) * int128(rs2)) >> 64);
  }

  //TO-DO: Ask Diego if the regular cast (chooses the first working cast) is unsafe
  function execute_DIV(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("DIV");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    int64 srs1 = int64(rs1);
    int64 srs2 = int64(rs2);

    if(srs2 == 0){
      return uint64(-1);
    //Why did the c++ used a regular cast vs static on int64(1)?
    //Also, pretty sure its supposed to be int64(1 << (xlen -1))
    //but if this is buggy - check this condition
    }else if (srs1 == (int64(1 << (XLEN - 1))) && srs2 == -1){
      return uint64(srs1);
    }else{
      return uint64(srs1 / srs2);
    }
  }

  function execute_DIVU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("DIVU");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    if(rs2 == 0){
      return uint64(-1);
    }else{
      return rs1 / rs2;
    }
  }

  //TO-DO: Make sure cast is not changing behaviour
  function execute_REM(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("REM");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    int64 srs1 = int64(rs1);
    int64 srs2 = int64(rs2);

    if(srs2 == 0){
      //implicit cast on C++ version - make sure this is the expected behaviour
      return uint64(srs1);
    }else if (srs1 == (int64(1 << (XLEN - 1))) && srs2 == -1){
      return 0;
    }else{
      return uint64(srs1 % srs2);
    }
  }

  function execute_REMU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("REMU");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    if(rs2 == 0){
      return rs1;
    }else{
      return rs1 % rs2;
    }
  }

  function execute_ADDW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    // emit Print("REMU");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    int32 rs1w = int32(rs1);
    int32 rs2w = int32(rs2);

    return uint64(rs1w + rs2w);
  }

  function execute_SUBW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    int32 rs1w = int32(rs1);
    int32 rs2w = int32(rs2);

    return uint64(rs1w - rs2w);
  }

  function execute_SLLW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    int32 rs1w = int32(rs1) << (rs2 & 31);

    return uint64(rs1w);
  }

  // TO-DO: make sure this is arithmetic shift
  function execute_SRLW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    int32 rs1w = int32(int32(rs1) >> (rs2 & 31));

    return uint64(rs1w);
  }

  function execute_SRAW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    int32 rs1w = int32(rs1) >> (rs2 & 31);

    return uint64(rs1w);
  }

  function execute_MULW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    int32 rs1w = int32(rs1);
    int32 rs2w = int32(rs2);

    return uint64(rs1w * rs2w);
  }

  function execute_DIVW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

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

  function execute_DIVUW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    uint32 rs1w = uint32(rs1);
    uint32 rs2w = uint32(rs2);
    if (rs2w == 0) {
      return uint64(-1);
    } else {
      return uint64(int32(rs1w / rs2w));
    }
  }

  function execute_REMW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

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

  function execute_REMUW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

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
  function arithmetic_funct3_funct7(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64, bool) {
    uint32 funct3_funct7 = RiscVDecoder.insn_funct3_funct7(insn);
    if(funct3_funct7 < 0x0181){
      if(funct3_funct7 < 0x0081){
        if(funct3_funct7 < 0x0020){
          if(funct3_funct7 == 0x0000){
            /*funct3_funct7 == 0x0000*/
            // return "ADD";
            return (execute_ADD(mi, mmIndex, insn), true);
          }else if(funct3_funct7 == 0x0001){
            /*funct3_funct7 == 0x0001*/
            //return "MUL";
            return (execute_MUL(mi, mmIndex, insn), true);
          }
        }else if(funct3_funct7 == 0x0080){
          /*funct3_funct7 == 0x0080*/
          //return "SLL";
          return (execute_SLL(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x0020){
          /*funct3_funct7 == 0x0020*/
          //return "SUB";
          return (execute_SUB(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 > 0x0081){
        if(funct3_funct7 == 0x0100){
          /*funct3_funct7 == 0x0100*/
          //return "SLT";
          return (execute_SLT(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x0180){
          /*funct3_funct7 == 0x0180*/
          //return "SLTU";
          return (execute_SLTU(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x0101){
          /*funct3_funct7 == 0x0101*/
          //return "MULHSU";
          return (execute_MULHSU(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 == 0x0081){
        /* funct3_funct7 == 0x0081*/
        //return "MULH";
        return (execute_MULH(mi, mmIndex, insn), true);
      }
    }else if(funct3_funct7 > 0x0181){
      if(funct3_funct7 < 0x02a0){
        if(funct3_funct7 == 0x0200){
          /*funct3_funct7 == 0x0200*/
          //return "XOR";
          return (execute_XOR(mi, mmIndex, insn), true);
        }else if(funct3_funct7 > 0x0201){
          if(funct3_funct7 ==  0x0280){
            /*funct3_funct7 == 0x0280*/
            //return "SRL";
            return (execute_SRL(mi, mmIndex, insn), true);
          }else if(funct3_funct7 == 0x0281){
            /*funct3_funct7 == 0x0281*/
            //return "DIVU";
            return (execute_DIVU(mi, mmIndex, insn), true);
          }
        }else if(funct3_funct7 == 0x0201){
          /*funct3_funct7 == 0x0201*/
          //return "DIV";
          return (execute_DIV(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 > 0x02a0){
        if(funct3_funct7 < 0x0380){
          if(funct3_funct7 == 0x0300){
            /*funct3_funct7 == 0x0300*/
            //return "OR";
            return (execute_OR(mi, mmIndex, insn), true);
          }else if(funct3_funct7 == 0x0301){
            /*funct3_funct7 == 0x0301*/
            //return "REM";
            return (execute_REM(mi, mmIndex, insn), true);
          }
        }else if(funct3_funct7 == 0x0381){
          /*funct3_funct7 == 0x0381*/
          //return "REMU";
          return (execute_REMU(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x380){
          /*funct3_funct7 == 0x0380*/
          //return "AND";
          return (execute_AND(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 == 0x02a0){
        /*funct3_funct7 == 0x02a0*/
        //return "SRA";
        return (execute_SRA(mi, mmIndex, insn), true);
      }
    }else if(funct3_funct7 == 0x0181){
      /*funct3_funct7 == 0x0181*/
      //return "MULHU";
      return (execute_MULHU(mi, mmIndex, insn), true);
    }
    return (0, false);
  }

  /// @notice Given an arithmetic32 funct3 funct7 insn, finds the associated func.
  //  Uses binary search for performance.
  //  @param insn for arithmetic32 funct3 funct7 field.
  function arithmetic_32_funct3_funct7(MemoryInteractor mi, uint256 mmIndex, uint32 insn) 
  public returns (uint64, bool) {

    uint32 funct3_funct7 = RiscVDecoder.insn_funct3_funct7(insn);

    if(funct3_funct7 < 0x0280){
      if(funct3_funct7 < 0x0020){
        if(funct3_funct7 == 0x0000){
          /*funct3_funct7 == 0x0000*/
          //return "ADDW";
          return (execute_ADDW(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x0001){
          /*funct3_funct7 == 0x0001*/
          //return "MULW";
          return (execute_MULW(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 > 0x0020){
        if(funct3_funct7 == 0x0080){
          /*funct3_funct7 == 0x0080*/
          //return "SLLW";
          return (execute_SLLW(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x0201){
          /*funct3_funct7 == 0x0201*/
          //return "DIVUW";
          return (execute_DIVUW(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 == 0x0020){
        /*funct3_funct7 == 0x0020*/
        //return "SUBW";
        return (execute_SUBW(mi, mmIndex, insn), true);
      }
    }else if(funct3_funct7 > 0x0280){
      if(funct3_funct7 < 0x0301){
        if(funct3_funct7 == 0x0281){
          /*funct3_funct7 == 0x0281*/
          //return "DIVUW";
          return (execute_DIVUW(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x02a0){
          /*funct3_funct7 == 0x02a0*/
          //return "SRAW";
          return (execute_SRAW(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 == 0x0381){
        /*funct3_funct7 == 0x0381*/
        //return "REMUW";
        return (execute_REMUW(mi, mmIndex, insn), true);
      }else if(funct3_funct7 == 0x0301){
        /*funct3_funct7 == 0x0301*/
        //return "REMW";
        return (execute_REMW(mi, mmIndex, insn), true);
      }
    }else if(funct3_funct7 == 0x0280) {
      /*funct3_funct7 == 0x0280*/
      //return "SRLW";
      return (execute_SRLW(mi, mmIndex, insn), true);
    }
    //return "illegal insn";
    return (0, false);
  }


}
