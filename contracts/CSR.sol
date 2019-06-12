// @title CSR
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/RiscVConstants.sol";
import "../contracts/CSR_reads.sol";

library CSR {

  //CSR addresses
  uint32 constant ucycle = 0xc00;
  uint32 constant utime = 0xc01;
  uint32 constant uinstret =  0xc02;

  uint32 constant sstatus = 0x100;
  uint32 constant sie = 0x104;
  uint32 constant stvec = 0x105;
  uint32 constant scounteren = 0x106;

  uint32 constant sscratch = 0x140;
  uint32 constant sepc = 0x141;
  uint32 constant scause = 0x142;
  uint32 constant stval = 0x143;
  uint32 constant sip = 0x144;

  uint32 constant satp = 0x180;

  uint32 constant mvendorid = 0xf11;
  uint32 constant marchid = 0xf12;
  uint32 constant mimpid = 0xf13;
  uint32 constant mhartid = 0xf14;

  uint32 constant mstatus = 0x300;
  uint32 constant misa = 0x301;
  uint32 constant medeleg = 0x302;
  uint32 constant mideleg = 0x303;
  uint32 constant mie = 0x304;
  uint32 constant mtvec = 0x305;
  uint32 constant mcounteren = 0x306;

  uint32 constant mscratch = 0x340;
  uint32 constant mepc = 0x341;
  uint32 constant mcause = 0x342;
  uint32 constant mtval = 0x343;
  uint32 constant mip = 0x344;

  uint32 constant mcycle = 0xb00;
  uint32 constant minstret = 0xb02;

  uint32 constant tselect = 0x7a0;
  uint32 constant tdata1 = 0x7a1;
  uint32 constant tdata2 = 0x7a2;
  uint32 constant tdata3 = 0x7a3;

  function read_csr(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  public returns (bool, uint64) {
    // Attemps to access a CSR without appropriate privilege level raises a
    // illegal instruction exception.
    // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
    if(csr_priv(csr_addr) > mi.read_iflags_PRV(mmIndex)){
      return(false, 0);
    }
    // TO-DO: Change this to binary search or mapping to increase performance
    // (in the meantime, pray for solidity devs to add switch statements)
    if(csr_addr == ucycle) {
      return CSR_reads.read_csr_cycle(mi, mmIndex, csr_addr);
    }else if(csr_addr == uinstret){
      return CSR_reads.read_csr_instret(mi, mmIndex, csr_addr);
    }else if(csr_addr == utime){
      return CSR_reads.read_csr_time(mi, mmIndex, csr_addr);
    }else if(csr_addr == sstatus){
      return CSR_reads.read_csr_sstatus(mi, mmIndex);
    }else if(csr_addr == sie){
      return CSR_reads.read_csr_sie(mi, mmIndex);
    }else if(csr_addr == stvec){
      return CSR_reads.read_csr_stvec(mi, mmIndex);
    }else if(csr_addr == scounteren){
      return CSR_reads.read_csr_scounteren(mi, mmIndex);
    }else if(csr_addr == sscratch){
      return CSR_reads.read_csr_sscratch(mi, mmIndex);
    }else if(csr_addr == sepc){
      return CSR_reads.read_csr_sepc(mi, mmIndex);
    }else if(csr_addr == scause){
      return CSR_reads.read_csr_scause(mi, mmIndex);
    }else if(csr_addr == stval){
      return CSR_reads.read_csr_stval(mi, mmIndex);
    }else if(csr_addr == sip){
      return CSR_reads.read_csr_sip(mi, mmIndex);
    }else if(csr_addr == satp){
      return CSR_reads.read_csr_satp(mi, mmIndex);
    }else if(csr_addr == mstatus){
      return CSR_reads.read_csr_mstatus(mi, mmIndex);
    }else if(csr_addr == misa){
      return CSR_reads.read_csr_misa(mi, mmIndex);
    }else if(csr_addr == medeleg){
      return CSR_reads.read_csr_medeleg(mi, mmIndex);
    }else if(csr_addr == mideleg){
      return CSR_reads.read_csr_mideleg(mi, mmIndex);
    }else if(csr_addr == mie){
      return CSR_reads.read_csr_mie(mi, mmIndex);
    }else if(csr_addr == mtvec){
      return CSR_reads.read_csr_mtvec(mi, mmIndex);
    }else if(csr_addr == mcounteren){
      return CSR_reads.read_csr_mcounteren(mi, mmIndex);
    }else if(csr_addr == mscratch){
      return CSR_reads.read_csr_mscratch(mi, mmIndex);
    }else if(csr_addr == mepc){
      return CSR_reads.read_csr_mepc(mi, mmIndex);
    }else if(csr_addr == mcause){
      return CSR_reads.read_csr_mcause(mi, mmIndex);
    }else if(csr_addr == mtval){
      return CSR_reads.read_csr_mtval(mi, mmIndex);
    }else if(csr_addr == mip){
      return CSR_reads.read_csr_mip(mi, mmIndex);
    }else if(csr_addr == mcycle){
      return CSR_reads.read_csr_mcycle(mi, mmIndex);
    }else if(csr_addr == minstret){
      return CSR_reads.read_csr_minstret(mi, mmIndex);
    }else if(csr_addr == mvendorid){
      return CSR_reads.read_csr_mvendorid(mi, mmIndex);
    }else if(csr_addr == marchid){
      return CSR_reads.read_csr_marchid(mi, mmIndex);
    }else if(csr_addr == mimpid){
      return CSR_reads.read_csr_mimpid(mi, mmIndex);
    }
    //All hardwired to zero
    else if(csr_addr == tselect || csr_addr == tdata1 || csr_addr == tdata2 || csr_addr == tdata3 ||  csr_addr == mhartid){
      return (true, 0);
    }

    return CSR_reads.read_csr_fail();
  }

  function write_csr(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr, uint64 val)
  public returns (bool) {
    // Attemps to access a CSR without appropriate privilege level raises a
    // illegal instruction exception.
    // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
    if(csr_priv(csr_addr) > mi.read_iflags_PRV(mmIndex)){
      return false;
    }
    if(csr_is_read_only(csr_addr)){
      return false;
    }

    // TO-DO: Change this to binary search or mapping to increase performance
    // (in the meantime, pray for solidity devs to add switch statements)
    if (csr_addr == sstatus){
      //return CSR_writes.write_csr_sstatus(mi, mmIndex, val);
      uint64 c_mstatus = mi.read_mstatus(mmIndex);
      return write_csr_mstatus(mi, mmIndex, (c_mstatus & ~RiscVConstants.SSTATUS_W_MASK()) | (val * RiscVConstants.SSTATUS_W_MASK()));

    }else if(csr_addr == sie){
      //return CSR_writes.write_csr_sie(mi, mmIndex, val);
      uint64 mask = mi.read_mideleg(mmIndex);
      uint64 c_mie = mi.read_mie(mmIndex);

      mi.write_mie(mmIndex, (c_mie & ~mask) | (val & mask));
      return true;
    }else if(csr_addr == stvec){
      //return CSR_writes.write_csr_stvec(mi, mmIndex, val);
      mi.write_stvec(mmIndex, val & uint64(~3));
      return true;
    }else if(csr_addr == scounteren){
      //return CSR_writes.write_csr_scounteren(mi, mmIndex, val);
      mi.write_scounteren(mmIndex, val & RiscVConstants.SCOUNTEREN_RW_MASK());
      return true;
    }else if(csr_addr == sscratch){
      //return CSR_writes.write_csr_sscratch(mi, mmIndex, val);
      mi.write_sscratch(mmIndex, val);
      return true;
    }else if(csr_addr == sepc){
      //return CSR_writes.write_csr_sepc(mi, mmIndex, val);
      mi.write_sepc(mmIndex, val & uint64(~3));
      return true;
    }else if(csr_addr == scause){
      //return CSR_writes.write_csr_scause(mi, mmIndex, val);
      mi.write_scause(mmIndex, val);
      return true;
    }else if(csr_addr == stval){
      //return CSR_writes.write_csr_stval(mi, mmIndex, val);
      mi.write_stval(mmIndex, val);
      return true;
    }else if(csr_addr == sip){
      //return CSR_writes.write_csr_sip(mi, mmIndex, val);
      uint64 c_mask = mi.read_mideleg(mmIndex);
      uint64 c_mip = mi.read_mip(mmIndex);

      c_mip = (c_mip & ~c_mask) | (val & c_mask);
      mi.write_mip(mmIndex, c_mip);
      return true;
    }else if(csr_addr == satp){
      //return CSR_writes.write_csr_satp(mi, mmIndex, val);
      uint64 c_satp = mi.read_satp(mmIndex);
      int mode = c_satp >> 60;
      int new_mode = (val >> 60) & 0xf;

      if (new_mode == 0 || (new_mode >= 8 && new_mode <= 9)) {
        mode = new_mode;
      }
      mi.write_satp(mmIndex, (val & ((uint64(1) << 44) - 1) | uint64(mode) << 60));
      return true;

    }else if(csr_addr == mstatus){
      return write_csr_mstatus(mi, mmIndex, val);
    }else if(csr_addr == medeleg){
      //return CSR_writes.write_csr_medeleg(mi, mmIndex, val);
      uint64 mask = (uint64(1) << (RiscVConstants.MCAUSE_STORE_AMO_PAGE_FAULT() + 1) - 1);
    mi.write_medeleg(mmIndex, (mi.read_medeleg(mmIndex) & ~mask) | (val & mask));
      return true;
    }else if(csr_addr == mideleg){
      //return CSR_writes.write_csr_mideleg(mi, mmIndex, val);
      uint64 mask = RiscVConstants.MIP_SSIP_MASK() | RiscVConstants.MIP_STIP_MASK() | RiscVConstants.MIP_SEIP_MASK(); 
      mi.write_mideleg(mmIndex, ((mi.read_mideleg(mmIndex) & ~mask) | (val & mask)));
      return true;
    }else if(csr_addr == mie){
      //return CSR_writes.write_csr_mie(mi, mmIndex, val);
      uint64 mask = RiscVConstants.MIP_MSIP_MASK() | RiscVConstants.MIP_MTIP_MASK() | RiscVConstants.MIP_SSIP_MASK() | RiscVConstants.MIP_STIP_MASK() | RiscVConstants.MIP_SEIP_MASK();

      mi.write_mie(mmIndex, ((mi.read_mie(mmIndex) & ~mask) | (val & mask)));
      return true;
    }else if(csr_addr == mtvec){
      //return CSR_writes.write_csr_mtvec(mi, mmIndex, val);
      mi.write_mtvec(mmIndex, val & uint64(~3));
      return true;
    }else if(csr_addr == mcounteren){
      //return CSR_writes.write_csr_mcounteren(mi, mmIndex, val);
      mi.write_mcounteren(mmIndex, val & RiscVConstants.MCOUNTEREN_RW_MASK());
      return true;
    }else if(csr_addr == mscratch){
      //return CSR_writes.write_csr_mscratch(mi, mmIndex, val);
      mi.write_mscratch(mmIndex, val);
      return true;
    }else if(csr_addr == mepc){
      //return CSR_writes.write_csr_mepc(mi, mmIndex, val);
      mi.write_minstret(mmIndex, val & uint64(~3));
      return true;
    }else if(csr_addr == mcause){
      //return CSR_writes.write_csr_mcause(mi, mmIndex, val);
      mi.write_mcause(mmIndex, val);
      return true;
    }else if(csr_addr == mtval){
      //return CSR_writes.write_csr_mtval(mi, mmIndex, val);
      mi.write_mtval(mmIndex, val);
      return true;
    }else if(csr_addr == mip){
      //return CSR_writes.write_csr_mip(mi, mmIndex, val);
       uint64 mask = RiscVConstants.MIP_SSIP_MASK() | RiscVConstants.MIP_STIP_MASK();
       uint64 c_mip = mi.read_mip(mmIndex);

       c_mip = (c_mip & ~mask) | (val & mask);

       mi.write_mip(mmIndex, c_mip);
       return true;
    }else if(csr_addr == mcycle){
      //return CSR_writes.write_csr_mcycle();
      return false;
    }else if(csr_addr == minstret){
      //return CSR_writes.write_csr_minstret(mi, mmIndex, val);
      // In Spike, QEMU, and riscvemu, mcycle and minstret are the aliases for the same counter
      // QEMU calls exit (!) on writes to mcycle or minstret
      mi.write_minstret(mmIndex, val-1); // The value will be incremented after the instruction is executed
      return true;
    }
    // Ignore writes
    else if(csr_addr == tselect || csr_addr == tdata1 || csr_addr == tdata2 || csr_addr == tdata3 ||  csr_addr == misa){
      return (true);
    }
    return false;
  }

  // Extract privilege level from CSR
  // Bits csr[9:8] encode the CSR's privilege level (i.e lowest privilege level
  // that can access that CSR.
  // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
  function csr_priv(uint32 csr_addr) internal returns(uint32) {
    return (csr_addr >> 8) & 3;
  }


  // The standard RISC-V ISA sets aside a 12-bit encoding space (csr[11:0])
  // The top two bits (csr[11:10]) indicate whether the register is 
  // read/write (00, 01, or 10) or read-only (11)
  // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
  function csr_is_read_only(uint32 csr_addr) internal returns(bool){
    return ((csr_addr & 0xc00) == 0xc00);
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
}

