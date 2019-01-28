/// @title Exceptions
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/RiscVConstants.sol";

library Exceptions {
  uint64 constant MCAUSE_INSN_ADDRESS_MISALIGNED      = 0x0;
  uint64 constant MCAUSE_INSN_ACCESS_FAULT            = 0x1;
  uint64 constant MCAUSE_ILLEGAL_INSN                 = 0x2;
  uint64 constant MCAUSE_BREAKPOINT                   = 0x3;
  uint64 constant MCAUSE_LOAD_ADDRESS_MISALIGNED      = 0x4;
  uint64 constant MCAUSE_LOAD_ACCESS_FAULT            = 0x5;
  uint64 constant MCAUSE_STORE_AMO_ADDRESS_MISALIGNED = 0x6;
  uint64 constant MCAUSE_STORE_AMO_ACCESS_FAULT       = 0x7;
  uint64 constant MCAUSE_ECALL_BASE                   = 0x8;
  uint64 constant MCAUSE_FETCH_PAGE_FAULT             = 0xc;
  uint64 constant MCAUSE_LOAD_PAGE_FAULT              = 0xd;
  uint64 constant MCAUSE_STORE_AMO_PAGE_FAULT         = 0xf;
  
  function raise_exception(uint256 mmIndex, address _memoryInteractorAddress, uint64 cause, uint64 tval) 
  public {
    MemoryInteractor mi = MemoryInteractor(_memoryInteractorAddress);

    uint64 mcause_interrupt_flag = 1 << uint64(RiscVConstants.XLEN() - 1);
    // All traps are handled in machine-mode, by default. Mideleg or Medeleg provide
    // bits to indicate if the interruption/exception should be taken care of by
    // lower privilege levels.
    // Medeleg -> Machine Exception Delegation register
    // Mideleg -> Machine Interrupt Delegation register
    // Reference: riscv-privileged-v1.9.1.pdf - Section 3.1.12, page 28.
    uint64 deleg = 0;
    uint64 priv = mi.read_iflags_PRV(mmIndex);

    if (priv <= RiscVConstants.PRV_S()) {
      if((cause & mcause_interrupt_flag) != 0) {
        // If exception was caused by an interruption the delegated information is
        // stored on mideleg register.

        // Clear the mcause_interrupt_flag bit before shifting
        deleg = (mi.read_mideleg(mmIndex) >> (cause & uint64(RiscVConstants.XLEN() - 1))) & 1;
      } else {
        //If not, information is in the medeleg register
        deleg = (mi.read_medeleg(mmIndex) >> cause) & 1;
      }
    }
    if (deleg != 0) {
      //is in S mode

      // SCAUSE - Supervisor Cause Register
      // Register containg Interrupt bit (shows if the exception was cause by an interrupt
      // and the Exception code, that identifies the last exception
      // The execption codes can be seen at table 4.1
      // Reference: riscv-privileged-v1.9.1.pdf - Section 4.1.8, page 51.
      mi.write_scause(mmIndex, cause);

      // SEPC - Supervisor Exception Program Counter
      // When a trap is taken, sepc is written with the address of the instruction
      // the encountered the exception.
      // Reference: riscv-privileged-v1.9.1.pdf - Section 4.1.7, page 50.
      mi.write_sepc(mmIndex, mi.read_pc(mmIndex));

      // STVAL - Supervisor Trap Value
      // stval is written with exception-specific information, when a trap is
      // taken into S-Mode. The specific values can be found in Reference.
      // Reference: riscv-privileged-v1.10.pdf - Section 4.1.11, page 55.
      mi.write_stval(mmIndex, tval);

      // MSTATUS - Machine Status Register
      // keeps track of and controls hart's current operating state.
      // Reference: riscv-privileged-v1.10.pdf - Section 3.1.16, page 19.
      uint64 mstatus = mi.read_mstatus(mmIndex);

      // The SPIE bit indicates whether supervisor interrupts were enabled prior
      // to trapping into supervisor mode. When a trap is taken into supervisor 
      // mode, SPIE is set to SIE, and SIE is set to 0. When an SRET instruction 
      // is executed, SIE is set to SPIE, then SPIE is set to 1.
      // Reference: riscv-privileged-v1.10.pdf - Section 4.1.1, page 19.
      mstatus = (mstatus & ~RiscVConstants.MSTATUS_SPIE_MASK()) | (((mstatus >> priv) & 1) << RiscVConstants.MSTATUS_SPIE_SHIFT());

      // The SPP bit indicates the privilege level at which a hart was executing 
      // before entering supervisor mode. When a trap is taken, SPP is set to 0 
      // if the trap originated from user mode, or 1 otherwise.
      // Reference: riscv-privileged-v1.10.pdf - Section 4.1.1, page 49.
      mstatus = (mstatus & ~RiscVConstants.MSTATUS_SPP_MASK()) | (priv << RiscVConstants.MSTATUS_SPP_SHIFT());

      // The SIE bit enables or disables all interrupts in supervisor mode.
      // When SIE is clear, interrupts are not taken while in supervisor mode.
      // When the hart is running in user-mode, the value in SIE is ignored, and
      // supervisor-level interrupts are enabled. The supervisor can disable 
      // indivdual interrupt sources using the sie register.
      // Reference: riscv-privileged-v1.10.pdf - Section 4.1.1, page 50.
      mstatus &= ~RiscVConstants.MSTATUS_SIE_MASK();

      mi.write_mstatus(mmIndex, mstatus);

      // TO-DO: Check gas cost to delegate function to library - if its zero the
      // if check should move to set_priv()
      if(priv != RiscVConstants.PRV_S()){
        mi.set_priv(mmIndex, RiscVConstants.PRV_S());
      }
      // SVEC - Supervisor Trap Vector Base Address Register
      mi.write_pc(mmIndex, mi.read_stvec(mmIndex));
    } else {
      // is in M mode
      mi.write_mcause(mmIndex, cause);
      mi.write_mepc(mmIndex, mi.read_pc(mmIndex));
      mi.write_mtval(mmIndex, tval);
      uint64 mstatus = mi.read_mstatus(mmIndex);

      mstatus = (mstatus & ~RiscVConstants.MSTATUS_MPIE_MASK()) | (((mstatus >> priv) & 1) << RiscVConstants.MSTATUS_MPIE_SHIFT());
      mstatus = (mstatus & ~RiscVConstants.MSTATUS_MPP_MASK()) | (priv << RiscVConstants.MSTATUS_MPP_SHIFT());

      mstatus &= ~RiscVConstants.MSTATUS_MIE_MASK();
      mi.write_mstatus(mmIndex, mstatus);

      // TO-DO: Check gas cost to delegate function to library - if its zero the
      // if check should move to set_priv()
      if(priv != RiscVConstants.PRV_M()){
        mi.set_priv(mmIndex, RiscVConstants.PRV_M());
      }
      mi.write_pc(mmIndex, mi.read_mtvec(mmIndex));
    }
  }
}
