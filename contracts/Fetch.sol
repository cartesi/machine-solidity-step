/// @title Fetch
pragma solidity ^0.5.0;

import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "../contracts/MemoryInteractor.sol";
import "../contracts/PMA.sol";
import "../contracts/VirtualMemory.sol";
import "../contracts/Exceptions.sol";

library Fetch {

  function fetch_insn(uint256 mmIndex, address _memoryInteractorAddress) public returns (fetch_status, uint32, uint64){
    MemoryInteractor mi = MemoryInteractor(_memoryInteractorAddress); 

    bool translateBool;
    uint64 paddr;

    //read_pc
    uint64 pc = mi.memoryRead(mmIndex, ShadowAddresses.get_pc());
    (translateBool, paddr) = VirtualMemory.translate_virtual_address(mi, mmIndex, pc, RiscVConstants.PTE_XWR_CODE_SHIFT());

    //translate_virtual_address failed
    if(!translateBool){
      Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_FETCH_PAGE_FAULT(), paddr);
      //returns fetch_exception and returns zero as insn and pc
      return (fetch_status.exception, 0, 0);
    }

    // Finds the range in memory in which the physical address is located
    // Returns start and length words from pma
    (uint64 pma_start, uint64 pma_length) = PMA.find_pma_entry(mi, mmIndex, paddr);

    //emit Print("pma_entry.start", pma_entry.start);
    //emit Print("pma_entry.length", pma_entry.length);

    // M flag defines if the pma range is in memory 
    // X flag defines if the pma is executable
    // If the pma is not memory or not executable - this is a pma violation
    // Reference: The Core of Cartesi, v1.02 - section 3.2 the board - page 5.

    if(!PMA.pma_get_istart_M(pma_start) || !PMA.pma_get_istart_X(pma_start)){
      //emit Print("CAUSE_FETCH_FAULT", paddr);
      Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_INSN_ACCESS_FAULT(), paddr);
      return (fetch_status.exception, 0, 0);
    }

    //emit Print("paddr/insn", paddr);
    uint32 insn = 0;

    // Check if instruction is on first 32 bits or last 32 bits
    if ((paddr & 7) == 0) {
      insn = uint32(mi.memoryRead(mmIndex, paddr));
    } else{
      // If not aligned, read at the last addr and shift to get the correct insn
      uint64 full_memory = mi.memoryRead(mmIndex, paddr - 4);
      insn = uint32(full_memory >> 32);
    }

    return (fetch_status.success, insn, pc);
  }
  enum fetch_status {
    exception, //failed: exception raised
    success
  }
}
