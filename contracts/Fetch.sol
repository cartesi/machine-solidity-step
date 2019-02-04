/// @title Fetch
pragma solidity ^0.5.0;

import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "../contracts/MemoryInteractor.sol";
import "../contracts/PMA.sol";
import "../contracts/VirtualMemory.sol";

library Fetch {
  // Variable positions on their respective array.
  // This is not an enum because enum assumes the type from the number of variables
  // So we would have to explicitly cast to uint256 on every single access
  uint256 constant priv = 0;
  uint256 constant mode= 1;
  uint256 constant vaddr_shift = 2;
  uint256 constant pte_size_log2= 3;
  uint256 constant vpn_bits= 4;
  uint256 constant satp_ppn_bits = 5;

  uint256 constant vaddr_mask = 0;
  uint256 constant pte_addr = 1;
  uint256 constant mstatus = 2;
  uint256 constant satp = 3;
  uint256 constant vpn_mask = 4;


  function fetch_insn(uint256 mmIndex, address _memoryInteractorAddress) public returns (fetch_status, uint32, uint64){
    MemoryInteractor mi = MemoryInteractor(_memoryInteractorAddress); 

    bool translateBool;
    uint64 paddr;

    //read_pc
    uint64 pc = mi.memoryRead(mmIndex, ShadowAddresses.get_pc());
    (translateBool, paddr) = VirtualMemory.translate_virtual_address(mi, mmIndex, pc, RiscVConstants.PTE_XWR_CODE_SHIFT());

    //translate_virtual_address failed
    if(!translateBool){
      //raise_exception(CAUSE_FETCH_PAGE_FAULT)

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
      //raise_exception(CAUSE_FETCH_FAULT)
//      return fetch_status.exception;
    }

    //emit Print("paddr/insn", paddr);
    //will this actually return the instruction? Should it be 32bits?
    uint32 insn = uint32(mi.memoryRead(mmIndex, paddr));
    //emit Print("insn", uint(insn));
    return (fetch_status.success, insn, pc);

  }
  enum fetch_status {
    exception, //failed: exception raised
    success
  }
}
