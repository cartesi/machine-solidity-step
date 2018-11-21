/// @title ArithmeticInstructions

pragma solidity 0.4.24;

// Overflow/Underflow behaviour in solidity is to allow them to happen freely.
// This mimics the RiscV behaviour, so we can use the arithmetic operators normally.
// RiscV-spec-v2.2 - Section 2.4:
// https://content.riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf
// Solidity docs Twos Complement/Underflow/Overflow: 
// https://solidity.readthedocs.io/en/latest/security-considerations.html?highlight=overflow#two-s-complement-underflows-overflows

library ArithmeticInstructions {
  uint constant XLEN = 64;

  event Print(string message);

  function execute_ADD(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("ADD");
    //_builtin_add_overflow(rs1, rs2, &val)
    return rs1 + rs2;
  }

  function execute_SUB(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("SUB");
    //_builtin_sub_overflow(rs1, rs2, &val)
    return rs1 - rs2;
  }

  function execute_SLL(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("SLL");

    return rs1 << (rs2 & (XLEN - 1));
  }

  function execute_SLT(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("SLT");

    return (int64(rs1) < int64(rs2))? 1:0;
  }

  function execute_SLTU(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("SLTU");

    return (rs1 < rs2)? 1:0;
  }

  function execute_XOR(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("XOR");

    return rs1 ^ rs2;
  }

  function execute_SRL(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("SRL");

    return rs1 >> (rs2 & (XLEN-1));
  }

  function execute_SRA(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("SRA");

    return uint64(int64(rs1) >> (rs2 & (XLEN-1)));
  }

  function execute_OR(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("OR");

    return rs1 | rs2;
  }

  function execute_AND(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("AND");

    return rs1 & rs2;
  }

  function execute_MUL(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("MUL");
    int64 srs1 = int64(rs1);
    int64 srs2 = int64(rs2);
    //_builtin_mul_overflow(srs1, srs2, &val);

    return uint64(srs1 * srs2);
  }

  //TO-DO: Use bitmanipulation library for shift
  function execute_MULH(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("MULH");
    int64 srs1 = int64(rs1);
    int64 srs2 = int64(rs2);

    //SHOULD BE ARITHMETIC SHIFT - >> of signed int
    return uint64((int128(srs1) * int128(srs2)) >> 64);
  }

  //TO-DO: Use bitmanipulation library for shift
  function execute_MULHSU(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("MULHSU");
    int64 srs1 = int64(rs1);

    //SHOULD BE ARITHMETIC SHIFT - >> of signed int
    return uint64((int128(srs1) * int128(rs2)) >> 64);
  }

  //TO-DO: Use bitmanipulation library for shift
  function execute_MULHU(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("MULHU");

    //SHOULD BE ARITHMETIC SHIFT - >> of signed int
    return uint64((int128(rs1) * int128(rs2)) >> 64);
  }

  //TO-DO: Ask Diego if the regular cast (chooses the first working cast) is unsafe
  function execute_DIV(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("DIV");
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

  function execute_DIVU(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("DIVU");

    if(rs2 == 0){
      return uint64(-1);
    }else{
      return rs1 / rs2;
    }
  }

  //TO-DO: Make sure cast is not changing behaviour
  function execute_REM(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("REM");
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

  function execute_REMU(uint64 rs1, uint64 rs2) public returns (uint64){
    emit Print("REMU");

    if(rs2 == 0){
      return rs1;
    }else{
      return rs1 % rs2;
    }
  }
}
