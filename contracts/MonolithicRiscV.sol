/// @title Monolithic RiscV
pragma solidity ^0.5.0;

//Libraries
import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./lib/BitsManipulationLibrary.sol";
import "../contracts/MemoryInteractor.sol";
import "../contracts/AddressTracker.sol";
import "../contracts/Fetch.sol";
import "../contracts/Interrupts.sol";

//TO-DO: use instantiator pattern so we can always use same instance of mm/pc etc
contract MonolithicRiscV {
  event Print(string message, uint value);

  //Keep tracks of all contract's addresses
  AddressTracker addrTracker;
  MemoryInteractor mi;

  uint256 mmIndex; //this has to be removed
  //Should not be Storage - but stack too deep
  //this will probably be ok when we split it into a bunch of different calls
  uint64 pc = 0;
  uint32 insn = 0;
  int priv;
  uint64 mstatus;

  function step(uint _mmIndex, address _addressTrackerAddress) public returns (interpreter_status){
    addrTracker = AddressTracker(_addressTrackerAddress);
    mmIndex = _mmIndex; //TO-DO: Remove this - should trickle down
    mi = MemoryInteractor(addrTracker.getMemoryInteractorAddress());

    // Every read performed by mi.memoryRead or mm . write should be followed by an 
    // endianess swap from little endian to big endian. This is the case because
    // EVM is big endian but RiscV is little endian.
    // Reference: riscv-spec-v2.2.pdf - Preface to Version 2.0
    // Reference: Ethereum yellowpaper - Version 69351d5
    //            Appendix H. Virtual Machine Specification

    // Read iflags register and check its H flag, to see if machine is halted.
    // If machine is halted - nothing else to do. H flag is stored on the least
    // signficant bit on iflags register.
    // Reference: The Core of Cartesi, v1.02 - figure 1.
    uint64 iflags = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_iflags()))
    );
    //emit Print("iflags", uint(iflags));
    if((iflags & 1) != 0){
      //machine is halted
      return interpreter_status.success;
    }
    //Raise the highest priority interrupt
    Interrupts interrupt = Interrupts(addrTracker.getInterruptsAddress());
    interrupt.raise_interrupt_if_any(mmIndex, address(mi));

    //Fetch Instruction
    Fetch fetchContract = Fetch(addrTracker.getFetchAddress());
    Fetch.fetch_status fetchStatus;

    (fetchStatus, insn) = fetchContract.fetch_insn(mmIndex, address(mi));
 
    if(fetchStatus == Fetch.fetch_status.success){
      // If fetch was successfull, tries to execute instruction
      //emit Print("fetch.status successfull", 0);
      if(execute_insn() == execute_status.retired){
        // If execute_insn finishes successfully we need to update the number of
        // retired instructions. This number is stored on minstret CSR.
        // Reference: riscv-priv-spec-1.10.pdf - Table 2.5, page 12.
        uint64 minstret = BitsManipulationLibrary.uint64_swapEndian(
          uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_minstret()))
        );
        //emit Print("minstret", uint(minstret));
        minstret = BitsManipulationLibrary.uint64_swapEndian(minstret + 1);
        mi.memoryWrite(mmIndex, ShadowAddresses.get_minstret(), bytes8(minstret ));
      }
    }
    // Last thing that has to be done in a step is to update the cycle counter.
    // The cycle counter is stored on mcycle CSR.
    // Reference: riscv-priv-spec-1.10.pdf - Table 2.5, page 12.
    uint64 mcycle = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_mcycle()))
    );
    //emit Print("mcycle", uint(mcycle));
    mcycle = BitsManipulationLibrary.uint64_swapEndian(mcycle + 1);
    mi.memoryWrite(mmIndex, ShadowAddresses.get_mcycle(), bytes8(mcycle));
    return interpreter_status.success;
  }

  function execute_insn() public returns (execute_status) {
    // OPCODE is located on bit 0 - 6 of the following types of 32bits instructions:
    // R-Type, I-Type, S-Trype and U-Type
    // Reference: riscv-spec-v2.2.pdf - Figure 2.2 - Page 11
    uint32 opcode = RiscVDecoder.inst_opcode(insn);

    // Find instruction associated with that opcode
    // Sometimes the opcode fully defines the associated instructions, but most
    // of the times it only specifies which group it belongs to.
    // For example, an opcode of: 01100111 is always a LUI instruction but an
    // opcode of 1100011 might be BEQ, BNE, BLT etc
    // Reference: riscv-spec-v2.2.pdf - Table 19.2 - Page 104
    bytes32 insn_or_group = RiscVDecoder.opinsn(opcode);

    // TO-DO: We have to find a way to do this - insn_or_group should return a
    // pointer to a function - that can be either a direct instrunction or a branch
    if(insn_or_group == bytes32("AUIPC")){
      //emit Print("opcode AUIPC", opcode);
      return execute_auipc();
    }
  }
    //AUIPC forms a 32-bit offset from the 20-bit U-immediate, filling in the 
    // lowest 12 bits with zeros, adds this offset to pc and store the result on rd.
    // Reference: riscv-spec-v2.2.pdf -  Page 14
  function execute_auipc() public returns (execute_status){
    uint32 rd = RiscVDecoder.insn_rd(insn) * 8; //8 = sizeOf(uint64)
    //emit Print("execute_auipc RD", uint(rd));
    if(rd != 0){
      mi.memoryWrite(mmIndex, rd, bytes8(BitsManipulationLibrary.uint64_swapEndian(
        pc + uint64(RiscVDecoder.insn_U_imm(insn)))
      ));
     // emit Print("pc", uint(pc));
     // emit Print("ins_u_imm", uint(RiscVDecoder.insn_U_imm(insn)));
    }
    return advance_to_next_insn();
  }

  function advance_to_next_insn() public returns (execute_status){
    pc = BitsManipulationLibrary.uint64_swapEndian(pc + 4);
    mi.memoryWrite(mmIndex, ShadowAddresses.get_pc(), bytes8(pc));
    //emit Print("advance_to_next", 0);
    return execute_status.retired;
  }

  enum interpreter_status {
    brk, // brk is set, tigh loop was broken
    success // mcycle reached target value
  }
  enum execute_status {
    illegal, // Exception was raised
    retired // Instruction retired - having raised or not an exception
  }
}
