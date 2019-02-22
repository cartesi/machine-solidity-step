// @title CLINT
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/RiscVConstants.sol";
import "../contracts/RealTimeClock.sol";

// Core Local Interruptor (CLINT_ controls the timer interrupt.
// Its active addresses are 0x0200bff8(mtime) and 0x02004000(mtimecmp)
// Reference: The Core of Cartesi, v1.02 - Section 3.2 - The Board
library CLINT {

  uint64 constant CLINT_MSIP0_ADDR = 0x02000000;
  uint64 constant CLINT_MTIMECMP_ADDR = 0x02004000;
  uint64 constant CLINT_MTIME_ADDR = 0x0200bff8;

  // \brief reads clint
  // \param pma_start_word first word, defines pma's start
  // \param pma_length_word second word, defines pma's length
  // \param offset can be uint8, uint16, uint32 or uint64
  // \param wordsize can be uint8, uint16, uint32 or uint64
  // \return bool if read was successfull
  // \return uint64 pval
  function clint_read(MemoryInteractor mi, uint256 mmIndex, uint64 pma_start_word, uint64 pma_length_word, uint64 offset, uint64 val, uint256 wordSize)
  public returns (bool, uint64) {

    if (offset == CLINT_MSIP0_ADDR){
      clint_read_msip(mi, mmIndex, wordSize);
    } else if (offset == CLINT_MTIMECMP_ADDR){
      clint_read_mtime(mi, mmIndex, wordSize);
    } else if (offset == CLINT_MTIME_ADDR){
      clint_read_mtimecmp(mi, mmIndex, wordSize);
    } else{
      return (false, 0);
    }
  }

  // \brief write to clint
  // \param pma_start_word first word, defines pma's start
  // \param pma_length_word second word, defines pma's length
  // \param offset can be uint8, uint16, uint32 or uint64
  // \param wordsize can be uint8, uint16, uint32 or uint64
  // \return bool if read was successfull
  // \return uint64 pval
  function clint_write(MemoryInteractor mi, uint256 mmIndex, uint64 pma_start_word, uint64 pma_length_word, uint64 offset, uint64 val, uint64 wordSize)
  public returns (bool) {

    if (offset == CLINT_MSIP0_ADDR){
      if (wordSize == 32){
        if ((val & 1) != 0){
          // TO-DO: mi.set_mip
          // mi.set_mip(RiscVConstants.MIP_MSIP_MASK());
        } else {
          // TO-DO: mi.set_mip
          // mi.reset_mip(RiscVConstants.MIP_MSIP_MASK());
        }
        return true;
      }
      return false;
    } else if (offset == CLINT_MTIMECMP_ADDR) {
      if (wordSize == 64){
        // TO-DO: mi.set_mip / write_clint_mtimecmp
        // mi.write_clint_mtimecmp(val);
        // mi.reset_mip(RiscVConstants.MIP_MSIP_MASK());
        return true;
      }
      // partial mtimecmp is not supported
      return false;
    }
    return false;
  }

  // internal functions
  function clint_read_msip(MemoryInteractor mi, uint256 mmIndex, uint256 wordSize)
  internal returns (bool, uint64) {
    if(wordSize == 32) {
      if ((mi.read_mip(mmIndex) & RiscVConstants.MIP_MSIP_MASK()) == RiscVConstants.MIP_MSIP_MASK()) {
        return(true, 1);
      } else {
        return (true, 0);
      }
    }
    return (false, 0);
  }

  function clint_read_mtime(MemoryInteractor mi, uint256 mmIndex, uint256 wordSize)
  internal returns (bool, uint64) {
    if(wordSize == 64) {
      return (true, RealTimeClock.rtc_cycle_to_time(mi.read_mcycle(mmIndex)));
    }
    return (false, 0);
  }

  // TO-DO: implement clint_read_mtimecmp
  function clint_read_mtimecmp(MemoryInteractor mi, uint256 mmIndex, uint256 wordSize)
  internal returns (bool, uint64) {
    if(wordSize == 64) {
    }
    return (false, 0);
  }

}


