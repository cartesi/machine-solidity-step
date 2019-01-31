// @title CSR
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/RiscVConstants.sol";
import "../contracts/RiscVDecoder.sol";
import "../contracts/RealTimeClock.sol";

library CSR {

  //CSR addresses
  uint32 constant ustatus = 0x000;
  uint32 constant uie = 0x004;
  uint32 constant utvec = 0x005;

  uint32 constant uscratch = 0x040;
  uint32 constant uepc = 0x041;
  uint32 constant ucause = 0x042;
  uint32 constant utval = 0x043;
  uint32 constant uip = 0x044;

  uint32 constant ucycle = 0xc00;
  uint32 constant utime = 0xc01;
  uint32 constant uinstret =  0xc02;
  uint32 constant ucycleh = 0xc80;
  uint32 constant utimeh = 0xc81;
  uint32 constant uinstreth = 0xc82;

  uint32 constant sstatus = 0x100;
  uint32 constant sedeleg = 0x102;
  uint32 constant sideleg = 0x103;
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
  uint32 constant mcycleh = 0xb80;
  uint32 constant minstreth = 0xb82;

  uint32 constant tselect = 0x7a0;
  uint32 constant tdata1 = 0x7a1;
  uint32 constant tdata2 = 0x7a2;
  uint32 constant tdata3 = 0x7a3;

  function execute_CSRRW(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
  public returns(uint64) {
    return mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn)); 
  }

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
      return read_csr_cycle(mi, mmIndex, csr_addr);
    }else if(csr_addr == uinstret){
      return read_csr_instret(mi, mmIndex, csr_addr);
    }else if(csr_addr == utime){
      return read_csr_time(mi, mmIndex, csr_addr);
    }else if(csr_addr == sstatus){
      return read_csr_sstatus(mi, mmIndex, csr_addr);
    }else if(csr_addr == sie){
      return read_csr_sie(mi, mmIndex, csr_addr);
    }else if(csr_addr == stvec){
      return read_csr_stvec(mi, mmIndex, csr_addr);
    }else if(csr_addr == scounteren){
      return read_csr_scounteren(mi, mmIndex, csr_addr);
    }else if(csr_addr == sscratch){
      return read_csr_sscratch(mi, mmIndex, csr_addr);
    }else if(csr_addr == sepc){
      return read_csr_sepc(mi, mmIndex, csr_addr);
    }else if(csr_addr == scause){
      return read_csr_scause(mi, mmIndex, csr_addr);
    }else if(csr_addr == stval){
      return read_csr_stval(mi, mmIndex, csr_addr);
    }else if(csr_addr == sip){
      return read_csr_sip(mi, mmIndex, csr_addr);
    }else if(csr_addr == satp){
      return read_csr_satp(mi, mmIndex, csr_addr);
    }else if(csr_addr == mstatus){
      return read_csr_mstatus(mi, mmIndex, csr_addr);
    }else if(csr_addr == misa){
      return read_csr_misa(mi, mmIndex, csr_addr);
    }else if(csr_addr == medeleg){
      return read_csr_medeleg(mi, mmIndex, csr_addr);
    }else if(csr_addr == mideleg){
      return read_csr_mideleg(mi, mmIndex, csr_addr);
    }else if(csr_addr == mie){
      return read_csr_mie(mi, mmIndex, csr_addr);
    }else if(csr_addr == mtvec){
      return read_csr_mtvec(mi, mmIndex, csr_addr);
    }else if(csr_addr == mcounteren){
      return read_csr_mcounteren(mi, mmIndex, csr_addr);
    }else if(csr_addr == mscratch){
      return read_csr_mscratch(mi, mmIndex, csr_addr);
    }else if(csr_addr == mepc){
      return read_csr_mepc(mi, mmIndex, csr_addr);
    }else if(csr_addr == mcause){
      return read_csr_mcause(mi, mmIndex, csr_addr);
    }else if(csr_addr == mtval){
      return read_csr_mtval(mi, mmIndex, csr_addr);
    }else if(csr_addr == mip){
      return read_csr_mip(mi, mmIndex, csr_addr);
    }else if(csr_addr == mcycle){
      return read_csr_mcycle(mi, mmIndex, csr_addr);
    }else if(csr_addr == minstret){
      return read_csr_minstret(mi, mmIndex, csr_addr);
    }else if(csr_addr == mvendorid){
      return read_csr_mvendorid(mi, mmIndex, csr_addr);
    }else if(csr_addr == marchid){
      return read_csr_marchid(mi, mmIndex, csr_addr);
    }else if(csr_addr == mimpid){
      return read_csr_mimpid(mi, mmIndex, csr_addr);
    }
    //All hardwired to zero
    else if(csr_addr == tselect || csr_addr == tdata1 || csr_addr == tdata2 || csr_addr == tdata3 ||  csr_addr == mhartid){
      return (true, 0);
    }
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
      return write_csr_sstatus(mi, mmIndex, val);
    }else if(csr_addr == sie){
      return write_csr_sie(mi, mmIndex, val);
    }else if(csr_addr == stvec){
      return write_csr_stvec(mi, mmIndex, val);
    }else if(csr_addr == scounteren){
      return write_csr_scounteren(mi, mmIndex, val);
    }else if(csr_addr == sscratch){
      return write_csr_sscratch(mi, mmIndex, val);
    }else if(csr_addr == sepc){
      return write_csr_sepc(mi, mmIndex, val);
    }else if(csr_addr == scause){
      return write_csr_scause(mi, mmIndex, val);
    }else if(csr_addr == stval){
      return write_csr_stval(mi, mmIndex, val);
    }else if(csr_addr == sip){
      return write_csr_sip(mi, mmIndex, val);
    }else if(csr_addr == satp){
      return write_csr_satp(mi, mmIndex, val);
    }else if(csr_addr == mstatus){
      return write_csr_mstatus(mi, mmIndex, val);
    }else if(csr_addr == medeleg){
      return write_csr_medeleg(mi, mmIndex, val);
    }else if(csr_addr == mideleg){
      return write_csr_mideleg(mi, mmIndex, val);
    }else if(csr_addr == mie){
      return write_csr_mie(mi, mmIndex, val);
    }else if(csr_addr == mtvec){
      return write_csr_mtvec(mi, mmIndex, val);
    }else if(csr_addr == mcounteren){
      return write_csr_mcounteren(mi, mmIndex, val);
    }else if(csr_addr == mscratch){
      return write_csr_mscratch(mi, mmIndex, val);
    }else if(csr_addr == mepc){
      return write_csr_mepc(mi, mmIndex, val);
    }else if(csr_addr == mcause){
      return write_csr_mcause(mi, mmIndex, val);
    }else if(csr_addr == mtval){
      return write_csr_mtval(mi, mmIndex, val);
    }else if(csr_addr == mip){
      return write_csr_mip(mi, mmIndex, val);
    }else if(csr_addr == mcycle){
      return write_csr_mcycle(mi, mmIndex, val);
    }else if(csr_addr == minstret){
      return write_csr_minstret(mi, mmIndex, val);
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

  function write_csr_mcycle(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    // We can't allow writes to mcycle because we use it to measure the progress in machine execution.
    // BBL enables all counters in both M- and S-modes
    // We instead raise an exception.                                  
    return false;
  }
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

  function write_csr_mip(MemoryInteractor mi, uint256 mmIndex, uint64 val) 
  internal returns(bool){
    uint64 mask = RiscVConstants.MIP_SSIP_MASK() | RiscVConstants.MIP_STIP_MASK();
    uint64 c_mip = mi.read_mip(mmIndex);

    c_mip = (c_mip & ~mask) | (val & mask);

    mi.write_mip(mmIndex, c_mip);
    return true;
  }

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

  // The standard RISC-V ISA sets aside a 12-bit encoding space (csr[11:0])
  // The top two bits (csr[11:10]) indicate whether the register is 
  // read/write (00, 01, or 10) or read-only (11)
  // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
  function csr_is_read_only(uint32 csr_addr) internal returns(bool){
    return ((csr_addr & 0xc00) == 0xc00);
  }
}

