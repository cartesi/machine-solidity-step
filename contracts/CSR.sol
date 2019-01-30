// @title CSR
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";

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


  function read_csr(MemoryInteractor mi, uint256 mmIndex, uint32 csr_addr)
  public returns (bool, uint32) {
    // Attemps to access a CSR without appropriate privilege level raises a
    // illegal instruction exception.
    // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
    if(csr_priv(csr_address) > mi.read_iflags_PRV(mmIndex)){
      return(false, 0);
    }
    if(csraddr == ucycle) {
      return read_csr_cycle();
    }else if(csraddr == uinstret){
      return read_csr_instret(a, csraddr, status);
    }else if(csraddr == utime){
      return read_csr_time(a, csraddr, status);
    }else if(csraddr == sstatus){
      return read_csr_sstatus(a, status);
    }else if(csraddr == sie){
      return read_csr_sie(a, status);
    }else if(csraddr == stvec){
      return read_csr_stvec(a, status);
    }else if(csraddr == scounteren){
      return read_csr_scounteren(a, status);
    }else if(csraddr == sscratch){
      return read_csr_sscratch(a, status);
    }else if(csraddr == sepc){
      return read_csr_sepc(a, status);
    }else if(csraddr == scause){
      return read_csr_scause(a, status);
    }else if(csraddr == stval){
      return read_csr_stval(a, status);
    }else if(csraddr == sip){
      return read_csr_sip(a, status);
    }else if(csraddr == satp){
      return read_csr_satp(a, status);
    }else if(csraddr == mstatus){
      return read_csr_mstatus(a, status);
    }else if(csraddr == misa){
      return read_csr_misa(a, status);
    }else if(csraddr == medeleg){
      return read_csr_medeleg(a, status);
    }else if(csraddr == mideleg){
      return read_csr_mideleg(a, status);
    }else if(csraddr == mie){
      return read_csr_mie(a, status);
    }else if(csraddr == mtvec){
      return read_csr_mtvec(a, status);
    }else if(csraddr == mcounteren){
      return read_csr_mcounteren(a, status);
    }else if(csraddr == mscratch){
      return read_csr_mscratch(a, status);
    }else if(csraddr == mepc){
      return read_csr_mepc(a, status);
    }else if(csraddr == mcause){
      return read_csr_mcause(a, status);
    }else if(csraddr == mtval){
      return read_csr_mtval(a, status);
    }else if(csraddr == mip){
      return read_csr_mip(a, status);
    }else if(csraddr == mcycle){
      return read_csr_mcycle(a, status);
    }else if(csraddr == minstret){
      return read_csr_minstret(a, status);
    }else if(csraddr == mvendorid){
      return read_csr_mvendorid(a, status);
    }else if(csraddr == marchid){
      return read_csr_marchid(a, status);
    }else if(csraddr == mimpid){
      return read_csr_mimpid(a, status);
    }
    // All hardwired to zero
    else if(csraddr == tselect || csraddr == tdata1 || csraddr == tdata2 || csraddr == tdata3 ||  csraddr == mhartid){
      return (0, true);
    }
  }

  // Extract privilege level from CSR 
  // Bits csr[9:8] encode the CSR's privilege level (i.e lowest privilege level
  // that can access that CSR.
  // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
  function csr_priv(uint32 csr_address) internal returns(uint32) {
    return (csr_address >> 8) & 3;
  }
}



