/// @title S_Instructions
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";
import "../../contracts/VirtualMemory.sol";

library S_Instructions {

  function get_rs1_imm_rs2(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
  internal returns(uint64 rs1, int32 imm, uint64 val){
    rs1 = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
    imm = RiscVDecoder.insn_I_imm(insn);
    val = mi.read_x(mmIndex, RiscVDecoder.insn_rs2(insn));
  }

  function SB(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool){
    (uint64 vaddr, int32 imm, uint64 val) = get_rs1_imm_rs2(mi, mmIndex, insn);
    // 1 == sizeof(uint8)
    return VirtualMemory.write_virtual_memory(mi, mmIndex, 1, vaddr + uint64(imm), val);
  }

  function SH(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool){
    (uint64 vaddr, int32 imm, uint64 val) = get_rs1_imm_rs2(mi, mmIndex, insn);
    // 2 == sizeof(uint16)
    return VirtualMemory.write_virtual_memory(mi, mmIndex, 2, vaddr + uint64(imm), val);
  }

  function SW(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool){
    (uint64 vaddr, int32 imm, uint64 val) = get_rs1_imm_rs2(mi, mmIndex, insn);
    // 4 == sizeof(uint32)
    return VirtualMemory.write_virtual_memory(mi, mmIndex, 4, vaddr + uint64(imm), val);
  }
  
  function SD(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool){
    (uint64 vaddr, int32 imm, uint64 val) = get_rs1_imm_rs2(mi, mmIndex, insn);
    // 8 == sizeof(uint64)
    return VirtualMemory.write_virtual_memory(mi, mmIndex, 8, vaddr + uint64(imm), val);
  }
}
