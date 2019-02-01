/// @title BranchInstructions
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";

library BranchInstructions {

  function get_rs1_rs2(MemoryInteractor mi, uint256 mmIndex, uint32 insn) internal 
  returns(uint64 rs1, uint64 rs2) {
    rs1 = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
    rs2 = mi.read_x(mmIndex, RiscVDecoder.insn_rs2(insn));
  }

  function execute_BEQ(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    return rs1 == rs2;
  }

  function execute_BNE(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    return rs1 != rs2;
  }

  function execute_BLT(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    return int64(rs1) < int64(rs2);
  }

  function execute_BGE(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    return int64(rs1) >= int64(rs2);
  }

  function execute_BLTU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    return rs1 < rs2;
  }

  function execute_BGEU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    return rs1 >= rs2;
  }
}
