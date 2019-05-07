/// @title BranchInstructions
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";

library BranchInstructions {

  function get_rs1_rs2(MemoryInteractor mi, uint256 mmIndex, uint32 insn) internal 
  returns(uint64 rs1, uint64 rs2) {
    rs1 = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
    rs2 = mi.read_x(mmIndex, RiscVDecoder.insn_rs2(insn));
  }

  function execute_BEQ(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    return rs1 == rs2;
  }

  function execute_BNE(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    return rs1 != rs2;
  }

  function execute_BLT(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    return int64(rs1) < int64(rs2);
  }

  function execute_BGE(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    return int64(rs1) >= int64(rs2);
  }

  function execute_BLTU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    return rs1 < rs2;
  }

  function execute_BGEU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool){
    (uint64 rs1, uint64 rs2) = get_rs1_rs2(mi, mmIndex, insn);
    return rs1 >= rs2;
  }

  /// @notice Given a branch funct3 group instruction, finds the function
  //  associated with it. Uses binary search for performance.
  //  @param insn for branch funct3 field.
  function branch_funct3(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
  public returns (bool, bool){
    uint32 funct3 = RiscVDecoder.insn_funct3(insn);

    if(funct3 < 0x0005){
      if(funct3 == 0x0000){
        /*funct3 == 0x0000*/
        //return "BEQ";
        return (execute_BEQ(mi, mmIndex, insn), true);
      }else if(funct3 == 0x0004){
        /*funct3 == 0x0004*/
        //return "BLT";
        return (execute_BLT(mi, mmIndex, insn), true);
      }else if(funct3 == 0x0001){
        /*funct3 == 0x0001*/
        //return "BNE";
        return (execute_BNE(mi, mmIndex, insn), true);
      }
    }else if(funct3 > 0x0005){
      if(funct3 == 0x0007){
        /*funct3 == 0x0007*/
        //return "BGEU";
        return (execute_BGEU(mi, mmIndex, insn), true);
      }else if(funct3 == 0x0006){
        /*funct3 == 0x0006*/
        //return "BLTU";
        return (execute_BLTU(mi, mmIndex, insn), true);
      }
    }else if(funct3 == 0x0005){
      /*funct3==0x0005*/
      //return "BGE";
      return (execute_BGE(mi, mmIndex, insn), true);
    }
    return (false, false);
  }
}
