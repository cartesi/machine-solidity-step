// @title CSR_writes
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/RiscVConstants.sol";
import "../contracts/RiscVDecoder.sol";
import "../contracts/RealTimeClock.sol";

library CSR_writes {
  // csr writes
  function write_csr_sstatus(MemoryInteractor mi, uint256 mmIndex, uint64 val)
  internal returns(bool){
    uint64 c_mstatus = mi.read_mstatus(mmIndex);
    return write_csr_mstatus(mi, mmIndex, (c_mstatus & ~RiscVConstants.SSTATUS_W_MASK()) | (val * RiscVConstants.SSTATUS_W_MASK()));
  }

  function write_csr_sie(MemoryInteractor mi, uint256 mmIndex, uint64 val)
  internal returns(bool){
    uint64 mask = mi.read_mideleg(mmIndex);
    uint64 c_mie = mi.read_mie(mmIndex);

    mi.write_mie(mmIndex, (c_mie & ~mask) | (val & mask));
    return true;
  }

  function write_csr_stvec(MemoryInteractor mi, uint256 mmIndex, uint64 val)
  internal returns(bool){
    mi.write_stvec(mmIndex, val & uint64(~3));
    return true;
  }

  function write_csr_scounteren(MemoryInteractor mi, uint256 mmIndex, uint64 val)
  internal returns(bool){
    mi.write_scounteren(mmIndex, val & RiscVConstants.SCOUNTEREN_RW_MASK());
    return true;
  }

  function write_csr_sscratch(MemoryInteractor mi, uint256 mmIndex, uint64 val)
  internal returns(bool){
    mi.write_sscratch(mmIndex, val);
    return true;
  }

  function write_csr_sepc(MemoryInteractor mi, uint256 mmIndex, uint64 val)
  internal returns(bool){
    mi.write_sepc(mmIndex, val & uint64(~3));
    return true;
  }

  function write_csr_scause(MemoryInteractor mi, uint256 mmIndex, uint64 val)
  internal returns(bool){
    mi.write_scause(mmIndex, val);
    return true;
  }

  function write_csr_stval(MemoryInteractor mi, uint256 mmIndex, uint64 val)
  internal returns(bool){
    mi.write_stval(mmIndex, val);
    return true;
  }

  function write_csr_sip(MemoryInteractor mi, uint256 mmIndex, uint64 val)
  internal returns(bool){
    uint64 c_mask = mi.read_mideleg(mmIndex);
    uint64 c_mip = mi.read_mip(mmIndex);

    c_mip = (c_mip & ~c_mask) | (val & c_mask);
    mi.write_mip(mmIndex, c_mip);
    return true;
  }

  function write_csr_satp(MemoryInteractor mi, uint256 mmIndex, uint64 val)
  internal returns(bool){
    uint64 c_satp = mi.read_satp(mmIndex);
    int mode = c_satp >> 60;
    int new_mode = (val >> 60) & 0xf;

    if (new_mode == 0 || (new_mode >= 8 && new_mode <= 9)) {
      mode = new_mode;
    }
    mi.write_satp(mmIndex, (val & ((uint64(1) << 44) - 1) | uint64(mode) << 60));
    return true;
  }

  function write_csr_mstatus(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    uint64 c_mstatus = mi.read_mstatus(mmIndex) & RiscVConstants.MSTATUS_R_MASK();
    // Modifiy only bits that can be written to
    c_mstatus = (c_mstatus & ~RiscVConstants.MSTATUS_W_MASK()) | (val & RiscVConstants.MSTATUS_W_MASK());
    //Update the SD bit
    if ((c_mstatus & RiscVConstants.MSTATUS_FS_MASK()) == RiscVConstants.MSTATUS_FS_MASK()){
      c_mstatus |= RiscVConstants.MSTATUS_SD_MASK();
    }
    mi.write_mstatus(mmIndex, c_mstatus);
    return true;
  }

  function write_csr_medeleg(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    uint64 mask = (uint64(1) << (RiscVConstants.MCAUSE_STORE_AMO_PAGE_FAULT() + 1) - 1);
    mi.write_medeleg(mmIndex, (mi.read_medeleg(mmIndex) & ~mask) | (val & mask));
    return true;
  }

  function write_csr_mideleg(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    uint64 mask = RiscVConstants.MIP_SSIP_MASK() | RiscVConstants.MIP_STIP_MASK() | RiscVConstants.MIP_SEIP_MASK(); 
    mi.write_mideleg(mmIndex, ((mi.read_mideleg(mmIndex) & ~mask) | (val & mask)));
    return true;
  }

  function write_csr_mie(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    uint64 mask = RiscVConstants.MIP_MSIP_MASK() | RiscVConstants.MIP_MTIP_MASK() | RiscVConstants.MIP_SSIP_MASK() | RiscVConstants.MIP_STIP_MASK() | RiscVConstants.MIP_SEIP_MASK();

    mi.write_mie(mmIndex, ((mi.read_mie(mmIndex) & ~mask) | (val & mask)));
    return true;
  }

  function write_csr_mtvec(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    mi.write_mtvec(mmIndex, val & uint64(~3));
    return true;
  }

  function write_csr_mcounteren(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    mi.write_mcounteren(mmIndex, val & RiscVConstants.MCOUNTEREN_RW_MASK());
    return true;
  }

  function write_csr_minstret(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    // In Spike, QEMU, and riscvemu, mcycle and minstret are the aliases for the same counter
    // QEMU calls exit (!) on writes to mcycle or minstret
    mi.write_minstret(mmIndex, val-1); // The value will be incremented after the instruction is executed
    return true;
  }

//  function write_csr_mcycle()
//  internal returns(bool){
//    // We can't allow writes to mcycle because we use it to measure the progress in machine execution.
//    // BBL enables all counters in both M- and S-modes
//    // We instead raise an exception.
//    return false;
//  }
  function write_csr_mscratch(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    mi.write_mscratch(mmIndex, val);
    return true;
  }

  function write_csr_mepc(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    mi.write_minstret(mmIndex, val & uint64(~3));
    return true;
  }

  function write_csr_mcause(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    mi.write_mcause(mmIndex, val);
    return true;
  }
  function write_csr_mtval(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    mi.write_mtval(mmIndex, val);
    return true;
  }

//  function write_csr_mip(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
//  internal returns(bool){
//    uint64 mask = RiscVConstants.MIP_SSIP_MASK() | RiscVConstants.MIP_STIP_MASK();
//    uint64 c_mip = mi.read_mip(mmIndex);
//
//    c_mip = (c_mip & ~mask) | (val & mask);
//
//    mi.write_mip(mmIndex, c_mip);
//    return true;
//  }
}

