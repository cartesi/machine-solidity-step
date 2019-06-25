// @title CSR_2
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/CSR_reads.sol";
import "../contracts/CSR.sol";

library CSRExecute {
  uint256 constant CSRRS_code = 0;
  uint256 constant CSRRC_code = 1;

  uint256 constant CSRRSI_code = 0;
  uint256 constant CSRRCI_code = 1;

  function execute_csr_SC(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint256 insncode)
  public returns (bool) {
    uint32 csr_address = RiscVDecoder.insn_I_uimm(insn);

    bool status = false;
    uint64 csrval = 0;

    (status, csrval) = CSR.read_csr(mi, mmIndex, csr_address);

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
      if (!CSR.write_csr(mi, mmIndex, csr_address, exec_value)){
        //return raise_illegal_insn_exception(mi, mmIndex, insn);
        return false;
      }
    }
    //return advance_to_next_insn(mi, mmIndex, pc);
    return true;
  }

   function execute_csr_SCI(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint256 insncode)
  public returns (bool){
    uint32 csr_address = RiscVDecoder.insn_I_uimm(insn);

    bool status = false;
    uint64 csrval = 0;

    (status, csrval) = CSR.read_csr(mi, mmIndex, csr_address);

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
      if (!CSR.write_csr(mi, mmIndex, csr_address, exec_value)){
        //return raise_illegal_insn_exception(mi, mmIndex, insn);
        return false;
      }
    }
    //return advance_to_next_insn(mi, mmIndex, pc);
    return true;
  }

  function execute_csr_RW(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint256 insncode)
  public returns (bool) {
    uint32 csr_address = RiscVDecoder.insn_I_uimm(insn);

    bool status = true;
    uint64 csrval = 0;
    uint64 rs1val = 0;

    uint32 rd = RiscVDecoder.insn_rd(insn);

    if (rd != 0){
      (status, csrval) = CSR.read_csr(mi, mmIndex, csr_address);
    }
    if (!status) {
      //return raise_illegal_insn_exception(mi, mmIndex, insn);
      return false;
    }

    if (insncode == 0) {
      rs1val = execute_CSRRW(mi, mmIndex, insn);
    } else {
      // insncode == 1
      rs1val = execute_CSRRWI(insn);
    }

    if (!CSR.write_csr(mi, mmIndex, csr_address, rs1val)){
      //return raise_illegal_insn_exception(mi, mmIndex, insn);
      return false;
    }
    if (rd != 0){
      mi.write_x(mmIndex, rd, csrval);
    }
    //return advance_to_next_insn(mi, mmIndex, pc);
    return true;
  }

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


}

