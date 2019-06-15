/// @title Atomic instructions
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";
import "../../contracts/VirtualMemory.sol";

library AtomicInstructions {

  function execute_LR(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn, uint256 wordSize)
  public returns (bool) {
    uint64 vaddr = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
    (bool succ, uint64 val) = VirtualMemory.read_virtual_memory(mi, mmIndex, wordSize, vaddr);
    if (!succ) {
      //execute_retired / advance to raised expection
      return false;
    }
    mi.write_ilrsc(mmIndex, vaddr);

    uint32 rd = RiscVDecoder.insn_rd(insn);
    if (rd != 0) {
      mi.write_x(mmIndex, rd, val);
    }
    // advance to next instruction
    return true;

  }

  function execute_SC(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn, uint64 wordSize)
  public returns (bool) {
    uint64 val = 0;
    uint64 vaddr = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));

    if (mi.read_ilrsc(mmIndex) == vaddr) {
      if (!VirtualMemory.write_virtual_memory(mi, mmIndex, wordSize, vaddr, mi.read_x(mmIndex, RiscVDecoder.insn_rs2(insn)))) {
        //advance to raised exception
        return false;
      }
      mi.write_ilrsc(mmIndex, uint64(-1));
    } else {
      val = 1;
    }
    uint32 rd = RiscVDecoder.insn_rd(insn);
    if (rd != 0) {
      mi.write_x(mmIndex, rd, val);
    }
    //advance to next insn
    return true;
  }

  function execute_AMO_part1(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn, uint256 wordSize)
  internal returns (uint64, uint64, uint64, bool){
    uint64 vaddr = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));

    (bool succ, uint64 tmp_valm) = VirtualMemory.read_virtual_memory(mi, mmIndex, wordSize, vaddr);

    if (!succ){
      return (0, 0, 0, false);
    }
    uint64 tmp_valr = mi.read_x(mmIndex, RiscVDecoder.insn_rs2(insn));

    return (tmp_valm, tmp_valr, vaddr, true);
  }

  function execute_AMO_D_part2(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn, uint64 vaddr, int64 valr, int64 valm, uint64 wordSize)
  internal returns (bool) {
    if (!VirtualMemory.write_virtual_memory(mi, mmIndex, wordSize, vaddr, uint64(valr))) {
      return false;
    }
    uint32 rd = RiscVDecoder.insn_rd(insn);
    if (rd != 0) {
      mi.write_x(mmIndex, rd, uint64(valm));
    }
    return true;
  }

  function execute_AMO_W_part2(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn, uint64 vaddr, int32 valr, int32 valm, uint64 wordSize)
  internal returns (bool) {
    if (!VirtualMemory.write_virtual_memory(mi, mmIndex, wordSize, vaddr, uint64(valr))) {
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
    return execute_AMO_W_part2(mi, mmIndex, pc, insn, vaddr, int32(valr), int32(valm), 32);
  }

  function execute_AMOADD_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_W_part2(mi, mmIndex, pc, insn, vaddr, int32(int32(valm) + int32(valr)), int32(valm), 32);
  }

  function execute_AMOXOR_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_W_part2(mi, mmIndex, pc, insn, vaddr, int32(valm ^ valr), int32(valm), 32);
  }

  function execute_AMOAND_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_W_part2(mi, mmIndex, pc, insn, vaddr, int32(valm & valr), int32(valm), 32);
  }

  function execute_AMOOR_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_W_part2(mi, mmIndex, pc, insn, vaddr, int32(valm | valr), int32(valm), 32);

  }

  function execute_AMOMIN_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_W_part2(mi, mmIndex, pc, insn, vaddr, int32( valm < valr? valm : valr), int32(valm), 32);
  }

  function execute_AMOMAX_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_W_part2(mi, mmIndex, pc, insn, vaddr, int32(valm > valr? valm : valr), int32(valm), 32);
  }

  function execute_AMOMINU_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_W_part2(mi, mmIndex, pc, insn, vaddr, int32(uint32(valm) < uint32(valr)? valm : valr), int32(valm), 32);
  }

  function execute_AMOMAXU_W(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 32);
    return execute_AMO_W_part2(mi, mmIndex, pc, insn, vaddr, int32(uint32(valm) > uint32(valr)? valm : valr), int32(valm), 32);
  }

  function execute_AMOSWAP_D(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 64);
    return execute_AMO_D_part2(mi, mmIndex, pc, insn, vaddr, int64(valr), int64(valm), 64);
  }

  function execute_AMOADD_D(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 64);
    return execute_AMO_D_part2(mi, mmIndex, pc, insn, vaddr, int64(valm + valr), int64(valm), 64);
  }

  function execute_AMOXOR_D(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 64);
    return execute_AMO_D_part2(mi, mmIndex, pc, insn, vaddr, int64(valm ^ valr), int64(valm), 64);
  }

  function execute_AMOAND_D(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 64);
    return execute_AMO_D_part2(mi, mmIndex, pc, insn, vaddr, int64(valm & valr), int64(valm), 64);
  }

  function execute_AMOOR_D(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 64);
    return execute_AMO_D_part2(mi, mmIndex, pc, insn, vaddr, int64(valm | valr), int64(valm), 64);

  }

  function execute_AMOMIN_D(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 64);
    return execute_AMO_D_part2(mi, mmIndex, pc, insn, vaddr, int64( valm < valr? valm : valr), int64(valm), 64);
  }

  function execute_AMOMAX_D(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 64);
    return execute_AMO_D_part2(mi, mmIndex, pc, insn, vaddr, int64(valm > valr? valm : valr), int64(valm), 64);
  }

  function execute_AMOMINU_D(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 64);
    // TO-DO: this is uint not int
    return execute_AMO_D_part2(mi, mmIndex, pc, insn, vaddr, int64(uint64(valm) < uint64(valr)? valm : valr), int64(valm), 64);
  }

  // TO-DO: this is uint not int
  function execute_AMOMAXU_D(MemoryInteractor mi, uint256 mmIndex, uint64 pc, uint32 insn)
  public returns(bool) {
    (uint64 valm, uint64 valr, uint64 vaddr, bool succ) = execute_AMO_part1(mi, mmIndex, pc, insn, 64);
    return execute_AMO_D_part2(mi, mmIndex, pc, insn, vaddr, int64(uint64(valm) > uint64(valr)? valm : valr), int64(valm), 64);
  }

}

