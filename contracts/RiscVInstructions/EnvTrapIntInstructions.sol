// TO-DO: Add documentation explaining each instruction

/// @title EnvTrapIntInstruction
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";
import "../../contracts/RiscVConstants.sol";
import "../../contracts/Exceptions.sol";

library EnvTrapIntInstructions {
  function execute_ECALL(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc) public {
    uint64 priv = mi.read_iflags_PRV(mmIndex);
    uint64 mtval = mi.read_mtval(mmIndex);
    // TO-DO: Are parameter valuation order deterministic? If so, we dont need to allocate memory
    Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_ECALL_BASE() + priv, mtval);
  }

  function execute_EBREAK(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc) public {
    Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_BREAKPOINT(), mi.read_mtval(mmIndex));
  }

  function execute_SRET(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc) 
  public returns (bool) {
    uint64 priv = mi.read_iflags_PRV(mmIndex);
    uint64 mstatus = mi.read_mstatus(mmIndex);

    if (priv < RiscVConstants.PRV_S() || (priv == RiscVConstants.PRV_S() && (mstatus & RiscVConstants.MSTATUS_TSR_MASK() != 0))) {
      return false;
    } else {
      uint64 spp = (mstatus & RiscVConstants.MSTATUS_SPP_MASK()) >> RiscVConstants.MSTATUS_SPP_SHIFT();
      // Set the IE state to previous IE state
      uint64 spie = (mstatus & RiscVConstants.MSTATUS_SPIE_MASK()) >> RiscVConstants.MSTATUS_SPIE_SHIFT();
      mstatus = (mstatus & ~RiscVConstants.MSTATUS_SIE_MASK()) | (spie << RiscVConstants.MSTATUS_SIE_SHIFT());

      // set SPIE to 1
      mstatus |= RiscVConstants.MSTATUS_SPIE_MASK();
      // set SPP to U
      mstatus &= ~RiscVConstants.MSTATUS_SPP_MASK();
      mi.write_mstatus(mmIndex, mstatus);
      if(priv != spp){
        mi.set_priv(mmIndex, spp);
      }
      mi.write_pc(mmIndex, mi.read_sepc(mmIndex));
      return true;
    }
  }

  function execute_MRET(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns(bool) {
    uint64 priv = mi.read_iflags_PRV(mmIndex);

    if (priv < RiscVConstants.PRV_M()) {
      return false;
    } else {
      uint64 mstatus = mi.read_mstatus(mmIndex);
      uint64 mpp = (mstatus & RiscVConstants.MSTATUS_MPP_MASK()) >> RiscVConstants.MSTATUS_MPP_SHIFT();
      // set IE state to previous IE state
      uint64 mpie = (mstatus & RiscVConstants.MSTATUS_MPIE_MASK()) >> RiscVConstants.MSTATUS_MPIE_SHIFT();
      mstatus = (mstatus & ~RiscVConstants.MSTATUS_MIE_MASK()) | (mpie << RiscVConstants.MSTATUS_MIE_SHIFT());

      // set MPIE to 1
      mstatus |= RiscVConstants.MSTATUS_MPIE_MASK();
      // set MPP to U
      mstatus &= ~RiscVConstants.MSTATUS_MPP_MASK();
      mi.write_mstatus(mmIndex, mstatus);

      if (priv != mpp){
        mi.set_priv(mmIndex, mpp);
      }
      mi.write_pc(mmIndex, mi.read_mepc(mmIndex));
      return true;
    }
  }

  function execute_WFI(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns(bool) {
    uint64 priv = mi.read_iflags_PRV(mmIndex);
    uint64 mstatus = mi.read_mstatus(mmIndex);

    if (priv == RiscVConstants.PRV_U() || (priv == RiscVConstants.PRV_S() && (mstatus & RiscVConstants.MSTATUS_TW_MASK() != 0))) {
      return false;
    } else {
      uint64 mip = mi.read_mip(mmIndex);
      uint64 mie = mi.read_mie(mmIndex);
      // Go to power down if no enable interrupts are pending
      if ((mip & mie) == 0) {
        mi.set_iflags_I(mmIndex, true);
      }
      return true;
    }
  }

}
