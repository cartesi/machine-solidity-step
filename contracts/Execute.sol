/// @title Execute
pragma solidity ^0.5.0;

import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./lib/BitsManipulationLibrary.sol";
import "../contracts/MemoryInteractor.sol";
import "./RiscVDecoder.sol";

contract Execute {
  MemoryInteractor mi;
  uint256 mmIndex;

  function execute_insn(uint256 _mmIndex, address _miAddress, uint32 insn, uint64 pc) public returns (execute_status) {
    mi = MemoryInteractor(_miAddress);
    mmIndex = _mmIndex;

    // OPCODE is located on bit 0 - 6 of the following types of 32bits instructions:
    // R-Type, I-Type, S-Trype and U-Type
    // Reference: riscv-spec-v2.2.pdf - Figure 2.2 - Page 11
    uint32 opcode = RiscVDecoder.inst_opcode(insn);

    // Find instruction associated with that opcode
    // Sometimes the opcode fully defines the associated instructions, but most
    // of the times it only specifies which group it belongs to.
    // For example, an opcode of: 01100111 is always a LUI instruction but an
    // opcode of 1100011 might be BEQ, BNE, BLT etc
    // Reference: riscv-spec-v2.2.pdf - Table 19.2 - Page 104
    bytes32 insn_or_group = RiscVDecoder.opinsn(opcode);

    // TO-DO: We have to find a way to do this - insn_or_group should return a
    // pointer to a function - that can be either a direct instrunction or a branch
    if(insn_or_group == bytes32("AUIPC")){
      //emit Print("opcode AUIPC", opcode);
      return execute_auipc(insn, pc);
    }
  }
    //AUIPC forms a 32-bit offset from the 20-bit U-immediate, filling in the 
    // lowest 12 bits with zeros, adds this offset to pc and store the result on rd.
    // Reference: riscv-spec-v2.2.pdf -  Page 14
  function execute_auipc(uint32 insn, uint64 pc) public returns (execute_status){
    uint32 rd = RiscVDecoder.insn_rd(insn) * 8; //8 = sizeOf(uint64)
    //emit Print("execute_auipc RD", uint(rd));
    if(rd != 0){
      mi.memoryWrite(mmIndex, rd, bytes8(BitsManipulationLibrary.uint64_swapEndian(
        pc + uint64(RiscVDecoder.insn_U_imm(insn)))
      ));
     // emit Print("pc", uint(pc));
     // emit Print("ins_u_imm", uint(RiscVDecoder.insn_U_imm(insn)));
    }
    return advance_to_next_insn(pc);
  }

  function advance_to_next_insn(uint64 pc) public returns (execute_status){
    pc = BitsManipulationLibrary.uint64_swapEndian(pc + 4);
    mi.memoryWrite(mmIndex, ShadowAddresses.get_pc(), bytes8(pc));
    //emit Print("advance_to_next", 0);
    return execute_status.retired;
  }
  enum execute_status {
    illegal, // Exception was raised
    retired // Instruction retired - having raised or not an exception
  }
}
