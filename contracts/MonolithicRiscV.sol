/// @title Monolithic RiscV
pragma solidity ^0.5.0;

//Libraries
import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./lib/BitsManipulationLibrary.sol";
import "../contracts/Fetch.sol";
import "../contracts/MemoryInteractor.sol";

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
    raise_interrupt_if_any();

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
  function raise_interrupt_if_any() public {
    uint32 mask = get_pending_irq_mask();
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
  function get_pending_irq_mask() public returns (uint32){
    uint64 mip = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_mip()))
    );
    //emit Print("mip", uint(mip));

    uint64 mie = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_mie()))
    );
    //emit Print("mie", uint(mie));

    uint32 pending_ints = uint32(mip & mie);
    // if there are no pending interrupts, return 0.
    if(pending_ints == 0){
      return 0;
    }
    mstatus = 0;
    uint32 enabled_ints = 0;
    //TO-DO: check shift + mask
    //TO-DO: Use bitmanipulation library for arithmetic shift

    // Read privilege level on iflags register.
    // The privilege level is represented by bits 2 and 3 on iflags register.
    // Reference: The Core of Cartesi, v1.02 - figure 1.
    priv = (BitsManipulationLibrary.uint64_swapEndian(
      uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_iflags())
    )) >> 2) & 3;
    //emit Print("priv", uint(priv));
    
    if(priv == RiscVConstants.PRV_M()) {
      // MSTATUS is the Machine Status Register - it controls the current
      // operating state. The MIE is an interrupt-enable bit for machine mode.
      // MIE for 64bit is stored on location 3 - according to:
      // Reference: riscv-privileged-v1.10 - figure 3.7 - page 20.
      mstatus = BitsManipulationLibrary.uint64_swapEndian(
        uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_mstatus()))
      );
      //emit Print("mstatus", uint(mstatus));

      if((mstatus & RiscVConstants.MSTATUS_MIE()) != 0){
        enabled_ints = uint32(~BitsManipulationLibrary.uint64_swapEndian(
          uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_mideleg())))
        );
      }
    }else if(priv == RiscVConstants.PRV_S()){
      mstatus = BitsManipulationLibrary.uint64_swapEndian(
        uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_mstatus()))
      );
      //emit Print("mstatus", uint(mstatus));
      // MIDELEG: Machine trap delegation register
      // mideleg defines if a interrupt can be proccessed by a lower privilege
      // level. If mideleg bit is set, the trap will delegated to the S-Mode.
      // Reference: riscv-privileged-v1.10 - Section 3.1.13 - page 27.
      uint64 mideleg = BitsManipulationLibrary.uint64_swapEndian(
        uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_mideleg()))
      );
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

  enum interpreter_status {
    brk, // brk is set, tigh loop was broken
    success // mcycle reached target value
  }
  enum execute_status {
    illegal, // Exception was raised
    retired // Instruction retired - having raised or not an exception
  }
}
