// @title RiscVDecoder
pragma solidity ^0.5.0;

import "./lib/BitsManipulationLibrary.sol";


library RiscVDecoder {
    // Contract responsible for decoding the riscv's instructions
    // It applies different bitwise operations and masks to reach
    // specific positions and use that positions to identify the
    // correct function to be executed

    /// @notice Get the instruction's RD
    //  @param insn Instruction
    function insnRd(uint32 insn) public pure returns(uint32) {
        return (insn >> 7) & 0x1F;
    }

    /// @notice Get the instruction's RS1
    //  @param insn Instruction
    function insnRs1(uint32 insn) public pure returns(uint32) {
        return (insn >> 15) & 0x1F;
    }

    /// @notice Get the instruction's RS2
    //  @param insn Instruction
    function insnRs2(uint32 insn) public pure returns(uint32) {
        return (insn >> 20) & 0x1F;
    }

    /// @notice Get the I-type instruction's immediate value
    //  @param insn Instruction
    function insnIImm(uint32 insn) public pure returns(int32) {
        // TO-DO: Use new evm assembly operator instead of  Bits library
        return BitsManipulationLibrary.int32ArithShiftRight(int32(insn), 20);
    }

    /// @notice Get the I-type instruction's unsigned immediate value
    //  @param insn Instruction
    function insnIUimm(uint32 insn) public pure returns(uint32) {
        return insn >> 20;
    }

    /// @notice Get the U-type instruction's immediate value
    //  @param insn Instruction
    function insnUImm(uint32 insn) public pure returns(int32) {
        return int32(insn & 0xfffff000);
    }

    /// @notice Get the B-type instruction's immediate value
    //  @param insn Instruction
    function insnBImm(uint32 insn) public pure returns(int32) {
        int32 imm = int32(
            ((insn >> (31 - 12)) & (1 << 12)) |
            ((insn >> (25 - 5)) & 0x7e0) |
            ((insn >> (8 - 1)) & 0x1e) |
            ((insn << (11 - 7)) & (1 << 11))
        );
        //TO-DO: use arithmetic shift on BitManipulation library
        //int shift - cant do
        return BitsManipulationLibrary.int32SignExtension(imm, 13);
    }

    /// @notice Get the J-type instruction's immediate value
    //  @param insn Instruction
    function insnJImm(uint32 insn) public pure returns(int32) {
        int32 imm = int32(
            ((insn >> (31 - 20)) & (1 << 20)) |
            ((insn >> (21 - 1)) & 0x7fe) |
            ((insn >> (20 - 11)) & (1 << 11)) |
            (insn & 0xff000)
        );
        //TO-DO: use arithmetic shift on BitManipulation library
        //int shift - cant do
        return BitsManipulationLibrary.int32SignExtension(imm, 21);
    }

    /// @notice Get the S-type instruction's immediate value
    //  @param insn Instruction
    function insnSImm(uint32 insn) public pure returns(int32) {
        int32 imm = int32(((insn & 0xfe000000) >> (25 - 5)) | ((insn >> 7) & 0x1F));
        return BitsManipulationLibrary.int32SignExtension(imm, 12);
    }

    /// @notice Get the instruction's opcode field
    //  @param insn Instruction
    function insnOpcode(uint32 insn) public pure returns (uint32) {
        return insn & 0x7F;
    }

    /// @notice Get the instruction's funct3 field
    //  @param insn Instruction
    function insnFunct3(uint32 insn) public pure returns (uint32) {
        return (insn >> 12) & 0x07;
    }

    /// @notice Get the concatenation of instruction's funct3 and funct7 fields
    //  @param insn Instruction
    function insnFunct3Funct7(uint32 insn) public pure returns (uint32) {
        return ((insn >> 5) & 0x380) | (insn >> 25);
    }

    /// @notice Get the concatenation of instruction's funct3 and funct5 fields
    //  @param insn Instruction
    function insnFunct3Funct5(uint32 insn) public pure returns (uint32) {
        return ((insn >> 7) & 0xE0) | (insn >> 27);
    }

    /// @notice Get the instruction's funct7 field
    //  @param insn Instruction
    function insnFunct7(uint32 insn) public pure returns (uint32) {
        return (insn >> 25) & 0x7F;
    }

    /// @notice Get the instruction's funct6 field
    //  @param insn Instruction
    function insnFunct6(uint32 insn) public pure returns (uint32) {
        return (insn >> 26) & 0x3F;
    }
}
