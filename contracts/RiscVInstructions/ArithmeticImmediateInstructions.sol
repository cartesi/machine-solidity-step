/// @title ArithmeticImmediateInstructions
pragma solidity ^0.5.0;


library ArithmeticImmediateInstructions {
  // TO-DO: move XLEN to its own library
  uint constant XLEN = 64;

  // ADDI adds the sign extended 12 bits immediate to rs1. Overflow is ignored.
  // Reference: riscv-spec-v2.2.pdf -  Page 13
  function execute_ADDI(uint64 rs1, int32 imm) public returns (uint64){
    return rs1 + uint64(imm);
  }

  // ORI performs logical Or bitwise operation on register rs1 and the sign-extended
  // 12 bit immediate. It places the result in rd.
  // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
  function execute_ORI(uint64 rs1, int32 imm) public returns (uint64){
    return rs1 | uint64(imm);
  }

  // SLRI instructions is a logical shift right instruction. The variable to be 
  // shift is in rs1 and the amount of shift operations is encoded in the lower
  // 5 bits of the I-immediate field.
  function execute_SRLI(uint64 rs1, int32 imm) public returns (uint64){
    // Get imm's lower 5 bits
    int32 shiftAmount = imm & int32(XLEN - 1);
    return rs1 >> shiftAmount;
  }
}
