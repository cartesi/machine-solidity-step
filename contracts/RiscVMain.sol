// @title RiscVMain
pragma solidity ^0.5.0;

import "./RiscVDecoder.sol";
import "./RiscVMachineState.sol";

contract RiscVMain {
  // Main RiscV contract - should be able to receive a machine state, receive the
  //next instruction and perform the step function following RiscV defined behaviour

  //event to help debbuging
  event Print(string message);
  event Print(uint64 uintToPrint);

  enum execute_status {
    illegal,
    retired
  }
  //this shouldnt be in storage - too expensive. How can we have this in memory
  //and access it without passing by param (only accepted on experimental pragma)
  RiscVMachineState.Machine_state a;

  function execute_branch(uint64 pc, uint32 insn) public returns (execute_status){
    //TO-DO: Make sure that a.x[insn_rs1(insn)] works
    //does this work? If yes, why?
    uint64 rs1 = a.x[RiscVDecoder.insn_rs1(insn)]; //read_register rs1
    uint64 rs2 = a.x[RiscVDecoder.insn_rs2(insn)]; //read_register rs2

    emit Print(rs1);
    emit Print(rs2);

    if(RiscVDecoder.branch_funct3(insn, rs1, rs2)){
      uint64 new_pc = uint64(int32(pc) + RiscVDecoder.insn_B_imm(insn));
      if((new_pc & 3) != 0) {
        return misaligned_fetch_exception(new_pc);
      }else {
        return execute_jump(new_pc);
      }
    }
//    should this be done on the blockchain?
    return execute_next_insn(pc);
  }

  function execute_arithmetic(uint64 pc, uint32 insn) public returns (execute_status){
    uint32 rd = RiscVDecoder.insn_rd(insn);
    if(rd != 0){
      uint64 rs1 = a.x[RiscVDecoder.insn_rs1(insn)]; //read_register rs1
      uint64 rs2 = a.x[RiscVDecoder.insn_rs2(insn)]; //read_register rs2
      a.x[rd] = RiscVDecoder.arithmetic_funct3_funct7(insn, rs1, rs2);
    }
    return execute_next_insn(pc);
  }

  function execute_jump(uint64 new_pc) public returns (execute_status){
    a.pc = new_pc;
    return execute_status.retired;
  }

  function misaligned_fetch_exception(uint64 pc) public returns (execute_status){
    //TO-DO: Raise excecption - Misaligned fetch
    return execute_status.retired;
  }

  function execute_next_insn(uint64 pc) public returns (execute_status){
    a.pc = pc + 4;
    return execute_status.retired;
  }
}
