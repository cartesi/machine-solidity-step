/// @title ArithmeticImmediateInstructions
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";

library ArithmeticImmediateInstructions {

  function get_rs1_imm(MemoryInteractor mi, uint256 mmIndex, uint32 insn) internal 
  returns(uint64 rs1, int32 imm) {
    rs1 = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
    imm = RiscVDecoder.insn_I_imm(insn);
  }

  // ADDI adds the sign extended 12 bits immediate to rs1. Overflow is ignored.
  // Reference: riscv-spec-v2.2.pdf -  Page 13
  function execute_ADDI(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    return rs1 + uint64(imm);
  }

  // ORI performs logical Or bitwise operation on register rs1 and the sign-extended
  // 12 bit immediate. It places the result in rd.
  // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
  function execute_ORI(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    return rs1 | uint64(imm);
  }

  // SLLI performs the logical left shift. The operand to be shifted is in rs1
  // and the amount of shifts are encoded on the lower 6 bits of I-imm.(RV64)
  // Imm[11:6] must be zero for it to be SLLI.
  // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14

  // TO-DO: If imm[11:6] is not zero this should cause a illegal insn exception;
  // TO-DO: change 0x3F to XLEN - 1
  function execute_SLLI(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns(uint64){
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    return rs1 << (imm & 0x3F);
  }
}
