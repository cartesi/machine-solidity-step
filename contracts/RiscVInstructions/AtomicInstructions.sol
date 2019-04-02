/// @title Atomic instructions
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";
import "../../contracts/VirtualMemory.sol";

library AtomicInstructions {

  function execute_AMO_part1(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn, uint256 wordSize)
  internal returns (uint64, uint64, uint64, bool){
    uint64 vaddr = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
    bool succ;
    uint64 tmp_valm;

    if(wordSize == 32){
      (succ, tmp_valm) = VirtualMemory.read_virtual_memory(mi, mmIndex, 32, vaddr);
    } else {
      // wordSize == 64
      (succ, tmp_valm)  = VirtualMemory.read_virtual_memory(mi, mmIndex, 64, vaddr);
    }
    if(!succ){
      return (0, 0, 0, false);
    }
    uint64 tmp_valr = mi.read_x(mmIndex, RiscVDecoder.insn_rs2(insn));

    return (tmp_valm, tmp_valr, vaddr, true);
  }

  function execute_AMO_part2(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn, uint64 vaddr, int32 valr, int32 valm)
  internal returns (bool) {
    if (!VirtualMemory.write_virtual_memory(mi, mmIndex, 32, vaddr, uint64(valr))) {
      return false;
    }
    uint32 rd = RiscVDecoder.insn_rd(insn);
    if (rd != 0) {
      mi.write_x(mmIndex, rd, uint64(valm));
    }
    return true;
  }

  // TO-DO: valm should actually be zero?
  function execute_AMOSWAP_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_part2(mi, mmIndex, pc, insn, vaddr, int32(valr), int32(0));
  }

  function execute_AMOADD_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_part2(mi, mmIndex, pc, insn, vaddr, int32(valm + valr), int32(valm));
  }

  function execute_AMOXOR_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_part2(mi, mmIndex, pc, insn, vaddr, int32(valm ^ valr), int32(valm));
  }

  function execute_AMOAND_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_part2(mi, mmIndex, pc, insn, vaddr, int32(valm & valr), int32(valm));
  }

  function execute_AMOOR_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_part2(mi, mmIndex, pc, insn, vaddr, int32(valm | valr), int32(valm));

  }

  function execute_AMOMIN_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_part2(mi, mmIndex, pc, insn, vaddr, int32( valm < valr? valm : valr), int32(valm));
  }

  function execute_AMOMAX_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_part2(mi, mmIndex, pc, insn, vaddr, int32(valm > valr? valm : valr), int32(valm));
  }

  function execute_AMOMINU_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_part2(mi, mmIndex, pc, insn, vaddr, int32(uint32(valm) < uint32(valr)? valm : valr), int32(valm));
  }

  function execute_AMOMAXU_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_part2(mi, mmIndex, pc, insn, vaddr, int32(uint32(valm) > uint32(valr)? valm : valr), int32(valm));
  }
}

