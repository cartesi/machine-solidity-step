/// @title Interrupts
pragma solidity ^0.5.0;

import "./ShadowAddresses.sol";
import "./lib/BitsManipulationLibrary.sol";
import "../contracts/MemoryInteractor.sol";
import "../contracts/RiscVConstants.sol";

library Interrupts {
  function raise_interrupt_if_any(uint256 mmIndex, address miAddress) public {
   uint32 mask = get_pending_irq_mask(mmIndex, miAddress);
     if(mask != 0) {
       uint64 irq_num = ilog2(mask);
       //TO-DO: Raise_exception
      // raise_exception()
     }
  }

  // Machine Interrupt Registers: mip and mie.
  // mip register contains information on pending interrupts.
  // mie register contains the interrupt enabled bits.
  // Reference: riscv-privileged-v1.10 - section 3.1.14 - page 28.
  function get_pending_irq_mask(uint256 mmIndex, address miAddress) public returns (uint32){
    MemoryInteractor mi = MemoryInteractor(miAddress); 

    uint64 mip = mi.memoryRead(mmIndex, ShadowAddresses.get_mip());
    //emit Print("mip", uint(mip));

    uint64 mie = mi.memoryRead(mmIndex, ShadowAddresses.get_mie());
    //emit Print("mie", uint(mie));

    uint32 pending_ints = uint32(mip & mie);
    // if there are no pending interrupts, return 0.
    if(pending_ints == 0){
      return 0;
    }
    uint64 mstatus = 0;
    uint32 enabled_ints = 0;
    //TO-DO: check shift + mask
    //TO-DO: Use bitmanipulation library for arithmetic shift

    // Read privilege level on iflags register.
    // The privilege level is represented by bits 2 and 3 on iflags register.
    // Reference: The Core of Cartesi, v1.02 - figure 1.
    uint64 priv = (mi.memoryRead(mmIndex, ShadowAddresses.get_iflags()) >> 2) & 3;
    //emit Print("priv", uint(priv));
    
    if(priv == RiscVConstants.PRV_M()) {
      // MSTATUS is the Machine Status Register - it controls the current
      // operating state. The MIE is an interrupt-enable bit for machine mode.
      // MIE for 64bit is stored on location 3 - according to:
      // Reference: riscv-privileged-v1.10 - figure 3.7 - page 20.
      mstatus = mi.memoryRead(mmIndex, ShadowAddresses.get_mstatus());
      //emit Print("mstatus", uint(mstatus));

      if((mstatus & RiscVConstants.MSTATUS_MIE()) != 0){
        enabled_ints = uint32(~mi.memoryRead(mmIndex, ShadowAddresses.get_mideleg()));
      }
    }else if(priv == RiscVConstants.PRV_S()){
      mstatus = mi.memoryRead(mmIndex, ShadowAddresses.get_mstatus());
      //emit Print("mstatus", uint(mstatus));
      // MIDELEG: Machine trap delegation register
      // mideleg defines if a interrupt can be proccessed by a lower privilege
      // level. If mideleg bit is set, the trap will delegated to the S-Mode.
      // Reference: riscv-privileged-v1.10 - Section 3.1.13 - page 27.
      uint64 mideleg = mi.memoryRead(mmIndex, ShadowAddresses.get_mideleg());
      //emit Print("mideleg", uint(mideleg));
      enabled_ints = uint32(~mideleg);


      // SIE: is the register contaning interrupt enabled bits for supervisor mode.
      // It is located on the first bit of mstatus register (RV64).
      // Reference: riscv-privileged-v1.10 - figure 3.7 - page 20.
      if((mstatus & RiscVConstants.MSTATUS_SIE()) != 0){
        //TO-DO: make sure this is the correct cast
        enabled_ints = enabled_ints | uint32(mideleg);
      }
    }else{
      enabled_ints = uint32(-1);
    }
    return pending_ints & enabled_ints;
  }

  //TO-DO: optmize log2 function
  function ilog2(uint32 v) public returns(uint64){
    //cpp emulator code:
    //return 31 - __builtin_clz(v)

    uint leading = 32;
    while(v != 0){
      v = v >> 1;
      leading--;
    }
    return uint64(31 - leading);
  }

}
