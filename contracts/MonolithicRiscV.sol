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
    uint64 pc = 0;
    uint32 insn = 0;

    mm = mmInterface(_memoryManagerAddress);
    //TO-DO: Check byte order -> riscv is little endian/ solidity is big endian

    //H -> least significant bit of iflags
    if( (uint64(mm.read(mmIndex, ShadowAddresses.get_iflags())) & 1) != 0){
      //machine is halted
      return interpreter_status.success;
    }
    //Raise the highest priority interrupt
    raise_interrupt_if_any();

    if(fetch_insn() == fetch_status.success){
      if(true/*execute_insn == execute_status.retired*/){
        //decodes instruction until it finds the definitive one
        //begin auipc
          //write_register(rd, pc + insn_U_get_imm
          //advance_to_next_insn
            //write_pc = pc + 4
          //end auipc
      }
    }
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

    //how to find paddr?? Some cases paddr == pc?
    //find_pma_entry
    //if pma is memory:
      //read_memory
    //end fetch
  }

  function raise_interrupt_if_any(){
    uint32 mask = get_pending_irq_mask();
    if(mask != 0) {
      uint64 irq_num = ilog2(mask);
      //TO-DO: Raise_exception
     // raise_exception()
    }
  }

  function get_pending_irq_mask() returns (uint32){
    uint64 mip = uint64(mm.read(mmIndex, ShadowAddresses.get_mip()));
    uint64 mie = uint64(mm.read(mmIndex, ShadowAddresses.get_mie()));

    uint32 pending_ints = uint32(mip & mie);
    if(pending_ints == 0){
      return 0;
    }
    uint64 mstatus = 0;
    uint32 enabled_ints = 0;
    //TO-DO: check shift + mask
    //TO-DO: Use bitmanipulation library for arithmetic shift
    int priv = (uint64(mm.read(mmIndex, ShadowAddresses.get_iflags())) >> 2) & 3;
    if(priv == PRVLevelsConstants.get_PRV_M()) {
      mstatus = uint64(mm.read(mmIndex, ShadowAddresses.get_mstatus()));
      if((mstatus & MstatusConstants.get_MSTATUS_MIE()) != 0){
        enabled_ints = uint32(~uint64(mm.read(mmIndex, ShadowAddresses.get_mideleg())));
      }
    }else if(priv == PRVLevelsConstants.get_PRV_S()){
      mstatus = uint64(mm.read(mmIndex, ShadowAddresses.get_mstatus()));
      uint64 mideleg = uint64(mm.read(mmIndex, ShadowAddresses.get_mideleg()));
      enabled_ints = uint32(~mideleg);
      if((mstatus & MstatusConstants.get_MSTATUS_SIE()) != 0){
        //TO-DO: make sure this is the correct cast
        enabled_ints = enabled_ints | uint32(mideleg);
      }
    }else{
      //TO-DO: Should I require iflags_PRV == PRV_U?
      //require(priv == PRVLevelsConstants.get_PRV_U());
      enabled_ints = uint32(-1);
    }
    return pending_ints & enabled_ints;
  }
  function ilog2(uint32 v){
    //cpp emulator code:
    //return 31 - __builtin_clz(v)

    //TO-DO: What to do if v == 0?
    uint leading = 32;
    while(v != 0){
      v = v >> 1;
      leading--;
    }
    return 31 - leading;
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
