// @title CSR
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/RiscVConstants.sol";
import "../contracts/RiscVDecoder.sol";
import "../contracts/RealTimeClock.sol";
import "../contracts/CSR_reads.sol";
import "../contracts/CSR_writes.sol";

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

  uint256 constant CSRRW_code = 0;
  uint256 constant CSRRWI_code = 1;

  uint256 constant CSRRS_code = 0;
  uint256 constant CSRRC_code = 1;

  uint256 constant CSRRSI_code = 0;
  uint256 constant CSRRCI_code = 1;


  function execute_CSRRW(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
  public returns(uint64) {
    return mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn)); 
  }

  function execute_CSRRWI(uint32 insn)
  public returns(uint64) {
    return uint64(RiscVDecoder.insn_rs1(insn));
  }

  function execute_CSRRS(uint64 csr, uint64 rs1)
  public returns(uint64) {
    return csr | rs1;
  }

  function execute_CSRRC(uint64 csr, uint64 rs1)
  public returns(uint64) {
    return csr & ~rs1;
  }

  function execute_CSRRSI(uint64 csr, uint32 rs1)
  public returns(uint64) {
    return csr | rs1;
  }

  function execute_CSRRCI(uint64 csr, uint32 rs1)
  public returns(uint64) {
    return csr & ~rs1;
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
      return CSR_reads.read_csr_cycle(mi, mmIndex, csr_addr);
    }else if(csr_addr == uinstret){
      return CSR_reads.read_csr_instret(mi, mmIndex, csr_addr);
    }else if(csr_addr == utime){
      return CSR_reads.read_csr_time(mi, mmIndex, csr_addr);
    }else if(csr_addr == sstatus){
      return CSR_reads.read_csr_sstatus(mi, mmIndex, csr_addr);
    }else if(csr_addr == sie){
      return CSR_reads.read_csr_sie(mi, mmIndex, csr_addr);
    }else if(csr_addr == stvec){
      return CSR_reads.read_csr_stvec(mi, mmIndex, csr_addr);
    }else if(csr_addr == scounteren){
      return CSR_reads.read_csr_scounteren(mi, mmIndex, csr_addr);
    }else if(csr_addr == sscratch){
      return CSR_reads.read_csr_sscratch(mi, mmIndex, csr_addr);
    }else if(csr_addr == sepc){
      return CSR_reads.read_csr_sepc(mi, mmIndex, csr_addr);
    }else if(csr_addr == scause){
      return CSR_reads.read_csr_scause(mi, mmIndex, csr_addr);
    }else if(csr_addr == stval){
      return CSR_reads.read_csr_stval(mi, mmIndex, csr_addr);
    }else if(csr_addr == sip){
      return CSR_reads.read_csr_sip(mi, mmIndex, csr_addr);
    }else if(csr_addr == satp){
      return CSR_reads.read_csr_satp(mi, mmIndex, csr_addr);
    }else if(csr_addr == mstatus){
      return CSR_reads.read_csr_mstatus(mi, mmIndex, csr_addr);
    }else if(csr_addr == misa){
      return CSR_reads.read_csr_misa(mi, mmIndex, csr_addr);
    }else if(csr_addr == medeleg){
      return CSR_reads.read_csr_medeleg(mi, mmIndex, csr_addr);
    }else if(csr_addr == mideleg){
      return CSR_reads.read_csr_mideleg(mi, mmIndex, csr_addr);
    }else if(csr_addr == mie){
      return CSR_reads.read_csr_mie(mi, mmIndex, csr_addr);
    }else if(csr_addr == mtvec){
      return CSR_reads.read_csr_mtvec(mi, mmIndex, csr_addr);
    }else if(csr_addr == mcounteren){
      return CSR_reads.read_csr_mcounteren(mi, mmIndex, csr_addr);
    }else if(csr_addr == mscratch){
      return CSR_reads.read_csr_mscratch(mi, mmIndex, csr_addr);
    }else if(csr_addr == mepc){
      return CSR_reads.read_csr_mepc(mi, mmIndex, csr_addr);
    }else if(csr_addr == mcause){
      return CSR_reads.read_csr_mcause(mi, mmIndex, csr_addr);
    }else if(csr_addr == mtval){
      return CSR_reads.read_csr_mtval(mi, mmIndex, csr_addr);
    }else if(csr_addr == mip){
      return CSR_reads.read_csr_mip(mi, mmIndex, csr_addr);
    }else if(csr_addr == mcycle){
      return CSR_reads.read_csr_mcycle(mi, mmIndex, csr_addr);
    }else if(csr_addr == minstret){
      return CSR_reads.read_csr_minstret(mi, mmIndex, csr_addr);
    }else if(csr_addr == mvendorid){
      return CSR_reads.read_csr_mvendorid(mi, mmIndex, csr_addr);
    }else if(csr_addr == marchid){
      return CSR_reads.read_csr_marchid(mi, mmIndex, csr_addr);
    }else if(csr_addr == mimpid){
      return CSR_reads.read_csr_mimpid(mi, mmIndex, csr_addr);
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
      return CSR_writes.write_csr_sstatus(mi, mmIndex, val);
    }else if(csr_addr == sie){
      return CSR_writes.write_csr_sie(mi, mmIndex, val);
    }else if(csr_addr == stvec){
      return CSR_writes.write_csr_stvec(mi, mmIndex, val);
    }else if(csr_addr == scounteren){
      return CSR_writes.write_csr_scounteren(mi, mmIndex, val);
    }else if(csr_addr == sscratch){
      return CSR_writes.write_csr_sscratch(mi, mmIndex, val);
    }else if(csr_addr == sepc){
      return CSR_writes.write_csr_sepc(mi, mmIndex, val);
    }else if(csr_addr == scause){
      return CSR_writes.write_csr_scause(mi, mmIndex, val);
    }else if(csr_addr == stval){
      return CSR_writes.write_csr_stval(mi, mmIndex, val);
    }else if(csr_addr == sip){
      return CSR_writes.write_csr_sip(mi, mmIndex, val);
    }else if(csr_addr == satp){
      return CSR_writes.write_csr_satp(mi, mmIndex, val);
    }else if(csr_addr == mstatus){
      return CSR_writes.write_csr_mstatus(mi, mmIndex, val);
    }else if(csr_addr == medeleg){
      return CSR_writes.write_csr_medeleg(mi, mmIndex, val);
    }else if(csr_addr == mideleg){
      return CSR_writes.write_csr_mideleg(mi, mmIndex, val);
    }else if(csr_addr == mie){
      return CSR_writes.write_csr_mie(mi, mmIndex, val);
    }else if(csr_addr == mtvec){
      return CSR_writes.write_csr_mtvec(mi, mmIndex, val);
    }else if(csr_addr == mcounteren){
      return CSR_writes.write_csr_mcounteren(mi, mmIndex, val);
    }else if(csr_addr == mscratch){
      return CSR_writes.write_csr_mscratch(mi, mmIndex, val);
    }else if(csr_addr == mepc){
      return CSR_writes.write_csr_mepc(mi, mmIndex, val);
    }else if(csr_addr == mcause){
      return CSR_writes.write_csr_mcause(mi, mmIndex, val);
    }else if(csr_addr == mtval){
      return CSR_writes.write_csr_mtval(mi, mmIndex, val);
    }else if(csr_addr == mip){
      return CSR_writes.write_csr_mip(mi, mmIndex, val);
    }else if(csr_addr == mcycle){
      return CSR_writes.write_csr_mcycle(mi, mmIndex, val);
    }else if(csr_addr == minstret){
      return CSR_writes.write_csr_minstret(mi, mmIndex, val);
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

  function execute_csr_SC(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc, uint256 insncode)
  public returns (bool) {
    uint32 csr_address = RiscVDecoder.insn_I_uimm(insn);

    bool status = false;
    uint64 csrval = 0;

    (status, csrval) = read_csr(mi, mmIndex, csr_address);

    if (!status) {
      //return raise_illegal_insn_exception(mi, mmIndex, insn);
      return false;
    }
    uint32 rs1 = RiscVDecoder.insn_rs1(insn);
    uint64 rs1val = mi.read_x(mmIndex, rs1);
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if (rd != 0) {
      mi.write_x(mmIndex, rd, csrval);
    }

    uint64 exec_value = 0;
    if (insncode == CSRRS_code) {
      exec_value = execute_CSRRS(csrval, rs1val);
    } else {
      // insncode == CSRRC_code
      exec_value = execute_CSRRC(csrval, rs1val);
    }
    if (rs1 != 0) {
      if (!write_csr(mi, mmIndex, csr_address, exec_value)){
        //return raise_illegal_insn_exception(mi, mmIndex, insn);
        return false;
      }
    }
    //return advance_to_next_insn(mi, mmIndex, pc);
    return true;
  }

   function execute_csr_SCI(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc, uint256 insncode)
  public returns (bool){
    uint32 csr_address = RiscVDecoder.insn_I_uimm(insn);

    bool status = false;
    uint64 csrval = 0;

    (status, csrval) = read_csr(mi, mmIndex, csr_address);

    if (!status) {
      //return raise_illegal_insn_exception(mi, mmIndex, insn);
      return false;
    }
    uint32 rs1 = RiscVDecoder.insn_rs1(insn);
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if (rd != 0) {
      mi.write_x(mmIndex, rd, csrval);
    }

    uint64 exec_value = 0;
    if (insncode == CSRRSI_code) {
      exec_value = execute_CSRRSI(csrval, rs1);
    } else {
      // insncode == CSRRCI_code
      exec_value = execute_CSRRCI(csrval, rs1);
    }

    if (rs1 != 0) {
      if (!write_csr(mi, mmIndex, csr_address, exec_value)){
        //return raise_illegal_insn_exception(mi, mmIndex, insn);
        return false;
      }
    }
    //return advance_to_next_insn(mi, mmIndex, pc);
    return true;
  }

  function execute_csr_RW(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc, uint256 insncode)
  public returns (bool) {
    uint32 csr_address = RiscVDecoder.insn_I_uimm(insn);

    bool status = true;
    uint64 csrval = 0;
    uint64 rs1val = 0;

    if (insncode == CSRRW_code) {
      rs1val = execute_CSRRW(mi, mmIndex, insn);
    } else {
      // insncode == CSRRWI_code
      rs1val = execute_CSRRWI(insn);
    }

    uint32 rd = RiscVDecoder.insn_rd(insn);

    if (rd != 0){
      (status, csrval) = read_csr(mi, mmIndex, csr_address);
    }
    if (!status) {
      //return raise_illegal_insn_exception(mi, mmIndex, insn);
      return false;
    }

    if (!write_csr(mi, mmIndex, csr_address, rs1val)){
      //return raise_illegal_insn_exception(mi, mmIndex, insn);
      return false;
    }
    if (rd != 0){
      mi.write_x(mmIndex, rd, csrval);
    }
    //return advance_to_next_insn(mi, mmIndex, pc);
    return true;
  }

  // getters
  function get_CSRRW_code() public returns (uint256) {return CSRRW_code;}
  function get_CSRRWI_code() public returns (uint256) {return CSRRWI_code;}

  function get_CSRRS_code() public returns (uint256) {return CSRRS_code; }
  function get_CSRRC_code() public returns (uint256) {return CSRRC_code; }

  function get_CSRRSI_code() public returns (uint256) {return CSRRSI_code;}
  function get_CSRRCI_code() public returns (uint256) {return CSRRCI_code;}

}

