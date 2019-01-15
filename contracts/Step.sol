/// @title Step
pragma solidity ^0.5.0;

//Libraries
import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./lib/BitsManipulationLibrary.sol";
import "../contracts/MemoryInteractor.sol";
import "../contracts/AddressTracker.sol";
import {Fetch} from "../contracts/Fetch.sol";
import {Execute} from "../contracts/Execute.sol";
import "../contracts/Interrupts.sol";

//TO-DO: use instantiator pattern so we can always use same instance of mm/pc etc
contract Step {
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
    Fetch.fetch_status fetchStatus;

    (fetchStatus, insn, pc) = Fetch.fetch_insn(mmIndex, address(mi));
 
    if(fetchStatus == Fetch.fetch_status.success){
      // If fetch was successfull, tries to execute instruction
      if(Execute.execute_insn(mmIndex, address(mi), insn, pc) == Execute.execute_status.retired){
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

  enum interpreter_status {
    brk, // brk is set, tigh loop was broken
    success // mcycle reached target value
  }
}
