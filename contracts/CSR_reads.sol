// @title CSR_reads
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/RiscVConstants.sol";
import "../contracts/RiscVDecoder.sol";
import "../contracts/RealTimeClock.sol";

library CSR_reads {
  // csr reads
  function read_csr_cycle(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    if (rdcounteren(mi, mmIndex, csr_addr)) {
      return read_csr_success(mi.read_mcycle(mmIndex));
    } else {
      return read_csr_fail();
    }
  }

  function read_csr_instret(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    if (rdcounteren(mi, mmIndex, csr_addr)) {
      return read_csr_success(mi.read_minstret(mmIndex));
    } else {
      return read_csr_fail();
    }
  }

  function read_csr_time(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    if (rdcounteren(mi, mmIndex, csr_addr)) {
      uint64 mtime = RealTimeClock.rtc_cycle_to_time(mi.read_mcycle(mmIndex));
      return read_csr_success(mtime);
    } else {
      return read_csr_fail();
    }
  }

  function read_csr_sstatus(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mstatus(mmIndex) & RiscVConstants.SSTATUS_R_MASK());
  }

  function read_csr_sie(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    uint64 mie = mi.read_mie(mmIndex);
    uint64 mideleg = mi.read_mideleg(mmIndex);

    return read_csr_success(mie & mideleg);
  }

  function read_csr_stvec(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_stvec(mmIndex)); 
  }

  function read_csr_scounteren(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_scounteren(mmIndex)); 
  }

  function read_csr_sscratch(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_sscratch(mmIndex)); 
  }

  function read_csr_sepc(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_sepc(mmIndex)); 
  }

  function read_csr_scause(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_scause(mmIndex)); 
  }

  function read_csr_stval(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_stval(mmIndex));
  }

  function read_csr_sip(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    uint64 mip = mi.read_mip(mmIndex);
    uint64 mideleg = mi.read_mideleg(mmIndex);
    return read_csr_success(mip & mideleg);
  }

  function read_csr_satp(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    uint64 mstatus = mi.read_mstatus(mmIndex);
    uint64 priv = mi.read_iflags_PRV(mmIndex);

    if (priv == RiscVConstants.PRV_S() && (mstatus & RiscVConstants.MSTATUS_TVM_MASK() != 0)) {
      return read_csr_fail();
    } else {
      return read_csr_success(mi.read_satp(mmIndex));
    }
  }

  function read_csr_mstatus(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mstatus(mmIndex) & RiscVConstants.MSTATUS_R_MASK());
  }

  function read_csr_misa(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_misa(mmIndex));
  }

  function read_csr_medeleg(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_medeleg(mmIndex));
  }

  function read_csr_mideleg(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mideleg(mmIndex));
  }

  function read_csr_mie(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mie(mmIndex));
  }

  function read_csr_mtvec(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mtvec(mmIndex));
  }

  function read_csr_mcounteren(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mcounteren(mmIndex));
  }

  function read_csr_mscratch(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mscratch(mmIndex));
  }

  function read_csr_mepc(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mepc(mmIndex));
  }

  function read_csr_mcause(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mcause(mmIndex));
  }

  function read_csr_mtval(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mtval(mmIndex));
  }

  function read_csr_mip(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mip(mmIndex));
  }

  function read_csr_mcycle(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mcycle(mmIndex));
  }

  function read_csr_minstret(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_minstret(mmIndex));
  }

  function read_csr_mvendorid(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mvendorid(mmIndex));
  }

  function read_csr_marchid(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_marchid(mmIndex));
  }

  function read_csr_mimpid(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  internal returns(bool, uint64) {
    return read_csr_success(mi.read_mimpid(mmIndex));
  }

  // read_csr_success/fail make it easier to change behaviour if necessary.
  function read_csr_success(uint64 val) internal returns(bool, uint64){
    return (true, val); 
  }
  function read_csr_fail() internal returns(bool, uint64){
    return (false, 0); 
  }

  // Check if counter is enabled. mcounteren control the availability of the 
  // hardware performance monitoring counter to the next-lowest priv level.
  // Reference: riscv-privileged-v1.10 - section 3.1.17 - page 32.
  function rdcounteren(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr) 
  internal returns (bool){
    uint64 counteren = RiscVConstants.MCOUNTEREN_RW_MASK();
    uint64 priv = mi.read_iflags_PRV(mmIndex);

    if (priv < RiscVConstants.PRV_M()) {
      counteren &= mi.read_mcounteren(mmIndex);
      if (priv < RiscVConstants.PRV_S()) {
        counteren &= mi.read_scounteren(mmIndex);
      }
    }
    return (((counteren >> (csr_addr & 0x1f)) & 1) != 0);
  }
}
