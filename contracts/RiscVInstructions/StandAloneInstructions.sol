/// @title StandAloneInstructions
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";

library StandAloneInstructions {
  //AUIPC forms a 32-bit offset from the 20-bit U-immediate, filling in the 
  // lowest 12 bits with zeros, adds this offset to pc and store the result on rd.
  // Reference: riscv-spec-v2.2.pdf -  Page 14
  function execute_auipc(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc) public {
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if(rd != 0){
      mi.write_x(mmIndex, rd, pc + uint64(RiscVDecoder.insn_U_imm(insn)));
    }
    //return advance_to_next_insn(mi, mmIndex, pc);
  }

  // LUI (i.e load upper immediate). Is used to build 32-bit constants and uses 
  // the U-type format. LUI places the U-immediate value in the top 20 bits of
  // the destination register rd, filling in the lowest 12 bits with zeros
  // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 13
  function execute_lui(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc) public {
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if(rd != 0){
      mi.write_x(mmIndex, rd, uint64(RiscVDecoder.insn_U_imm(insn)));
    }
    //return advance_to_next_insn(mi, mmIndex, pc);
  }

  // JALR (i.e Jump and Link Register). uses the I-type encoding. The target
  // address is obtained by adding the 12-bit signed I-immediate to the register 
  // rs1, then setting the least-significant bit of the result to zero. 
  // The address of the instruction following the jump (pc+4) is written to register rd
  // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 16
  function execute_jalr(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns (bool, uint64){
    uint64 new_pc = uint64(int64(mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn)))) & ~uint64(1);

    if((new_pc & 3) != 0){
      return (false, new_pc);
      //return raise_misaligned_fetch_exception(mi, mmIndex, new_pc);
    }
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if(rd != 0){
      mi.write_x(mmIndex, rd, pc + 4);
    }
    return (true, new_pc);
    //return execute_jump(mi, mmIndex, new_pc);
  }

  // JAL (i.e Jump and Link). J_immediate encondes a signed offset in multiples
  // of 2 bytes. The offset is added to pc and JAL stores the address of the jump
  // (pc + 4) to the rd register.
  // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 16
  function execute_jal(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns (bool, uint64){
    uint64 new_pc = pc + uint64(RiscVDecoder.insn_J_imm(insn));

    if((new_pc & 3) != 0){
      return (false, new_pc);
      //return raise_misaligned_fetch_exception(mi, mmIndex, new_pc);
    }
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if(rd != 0){
      mi.write_x(mmIndex, rd, pc + 4);
    }
    return (true, new_pc);
    //return execute_jump(mi, mmIndex, new_pc);
  }

}

