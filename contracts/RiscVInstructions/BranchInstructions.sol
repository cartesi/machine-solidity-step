/// @title BranchInstructions
pragma solidity ^0.5.0;

library BranchInstructions {
  event Print(string message);

  function execute_BEQ(uint64 rs1, uint64 rs2) public returns (bool){
    emit Print("BQE");
    return rs1 == rs2;
  }

  function execute_BNE(uint64 rs1, uint64 rs2) public returns (bool){
    emit Print("BNE");
    return rs1 != rs2;
  }

  function execute_BLT(uint64 rs1, uint64 rs2) public returns (bool){
    emit Print("BLT");
    return int64(rs1) < int64(rs2);
  }

  function execute_BGE(uint64 rs1, uint64 rs2) public returns (bool){
    emit Print("BGE");
    return int64(rs1) >= int64(rs2);
  }

  function execute_BLTU(uint64 rs1, uint64 rs2) public returns (bool){
    emit Print("BLTU");
    return rs1 < rs2;
  }

  function execute_BGEU(uint64 rs1, uint64 rs2) public returns (bool){
    emit Print("BGEU");
    return rs1 >= rs2;
  }
}
