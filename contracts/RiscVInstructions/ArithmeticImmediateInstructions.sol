/// @title ArithmeticImmediateInstructions
pragma solidity ^0.5.0;


library ArithmeticImmediateInstructions {
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

}
