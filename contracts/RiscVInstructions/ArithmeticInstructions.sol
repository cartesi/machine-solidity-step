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

  event Print(string message);
  function get_rs1_rs2(MemoryInteractor mi, uint256 mmIndex, uint32 insn) internal 
  returns(uint64 rs1, uint64 rs2) {
    rs1 = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
    rs2 = mi.read_x(mmIndex, RiscVDecoder.insn_rs2(insn));
  }

  function execute_ADD(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("ADD");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    //_builtin_add_overflow(rs1, rs2, &val)
    return rs1 + rs2;
  }

  function execute_SUB(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("SUB");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    //_builtin_sub_overflow(rs1, rs2, &val)
    return rs1 - rs2;
  }

  function execute_SLL(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("SLL");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return rs1 << (rs2 & (XLEN - 1));
  }

  function execute_SLT(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("SLT");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return (int64(rs1) < int64(rs2))? 1:0;
  }

  function execute_SLTU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("SLTU");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return (rs1 < rs2)? 1:0;
  }

  function execute_XOR(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("XOR");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return rs1 ^ rs2;
  }

  function execute_SRL(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("SRL");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return rs1 >> (rs2 & (XLEN-1));
  }

  function execute_SRA(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("SRA");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return uint64(int64(rs1) >> (rs2 & (XLEN-1)));
  }

  function execute_OR(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("OR");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return rs1 | rs2;
  }

  function execute_AND(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("AND");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    return rs1 & rs2;
  }

  function execute_MUL(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("MUL");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    int64 srs1 = int64(rs1);
    int64 srs2 = int64(rs2);
    //_builtin_mul_overflow(srs1, srs2, &val);

    return uint64(srs1 * srs2);
  }

  //TO-DO: Use bitmanipulation library for shift
  function execute_MULH(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("MULH");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    int64 srs1 = int64(rs1);
    int64 srs2 = int64(rs2);

    //SHOULD BE ARITHMETIC SHIFT - >> of signed int
    return uint64((int128(srs1) * int128(srs2)) >> 64);
  }

  //TO-DO: Use bitmanipulation library for shift
  function execute_MULHSU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("MULHSU");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    int64 srs1 = int64(rs1);

    //SHOULD BE ARITHMETIC SHIFT - >> of signed int
    return uint64((int128(srs1) * int128(rs2)) >> 64);
  }

  //TO-DO: Use bitmanipulation library for shift
  function execute_MULHU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("MULHU");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    //SHOULD BE ARITHMETIC SHIFT - >> of signed int
    return uint64((int128(rs1) * int128(rs2)) >> 64);
  }

  //TO-DO: Ask Diego if the regular cast (chooses the first working cast) is unsafe
  function execute_DIV(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("DIV");
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
    emit Print("DIVU");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    if(rs2 == 0){
      return uint64(-1);
    }else{
      return rs1 / rs2;
    }
  }

  //TO-DO: Make sure cast is not changing behaviour
  function execute_REM(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    emit Print("REM");
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
    emit Print("REMU");
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);

    if(rs2 == 0){
      return rs1;
    }else{
      return rs1 % rs2;
    }
  }
}
