/// @title Monolithic RiscV
pragma solidity 0.4.24;

//Libraries
import "./ShadowAddresses.sol";
import "./PRVLevelsConstants.sol";
import "./MstatusConstants.sol";

contract mmInterface {
  function read(uint256 _index, uint64 _address) public view returns (bytes8);
  function write(uint256 _index, uint64 _address, bytes8 _value) public;
  function finishReplayPhase(uint256 _index) public;
}

//TO-DO: use instantiator pattern so we can always use same instance of mm/pc etc
contract MonolithicRiscV {
  event Print(string message);
  mmInterface mm;
  uint256 mmIndex;

  function step(address _memoryManagerAddress) returns (interpreter_status){
    //instantiate mmInterface to correct address
    //Read iflags_H to find out if machine is halted

    //Raise the highest priority interrupt
      //get_pending_irq_mask

//    if(fetch_insn() == fetch_status.success){
//      if(execute_insn == execute_status.retired){
//        decodes instruction until it finds the definitive one
//        begin auipc
//          write_register(rd, pc + insn_U_get_imm
//          advance_to_next_insn
//          write_pc = pc + 4
//        end auipc
//      }
//    }
    //read_minstret
    //write_minsret + 1

    //read_mcycle
    //write_mcycle + 1
//  //end step
  }
  function fetch_insn() returns (fetch_status){
    emit Print("fetch");
    //read_pc

    //translate_virtual_address();

    //find_pma_entry
    //if pma is memory:
      //read_memory
    //end fetch

  }
  //enums
  enum fetch_status {
    exception, //failed: exception raised
    success
  }
  enum interpreter_status {
    brk, // brk is set, tigh loop was broken
    success // mcycle reached target value
  }
}
