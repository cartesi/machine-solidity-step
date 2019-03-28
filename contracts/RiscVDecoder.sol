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
}
