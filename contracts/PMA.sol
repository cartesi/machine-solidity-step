/// @title PMA
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "./lib/BitsManipulationLibrary.sol";

library PMA {

  function find_pma_entry(MemoryInteractor mi, uint256 mmIndex, uint64 paddr) public returns (uint64, uint64){
  
    // Hard coded ram address starts at 0x800
    // In total there are 32 PMAs from processor shadow to Flash disk 7.
    // PMA 0 - describes RAM and is hardcoded to address 0x800
    // PMA 16 - 23 describe flash devices 0-7
    // RAM start field is hardcoded to 0x800
    // Reference: The Core of Cartesi, v1.02 - Table 3.
    uint64 pmaAddress = 0x800;
    bool foundPma;
    //TO-DO: Check lastPma - this is probably wrong.
    uint64 lastPma = 62; // 0 - 31 * 2 words
    //emit Print("paddr", paddr);
    for(uint64 i = 0; i < lastPma; i+=2){
      uint64 start_word = mi.memoryRead(mmIndex, pmaAddress + (i*8));

      uint64 length_word = mi.memoryRead(mmIndex, pmaAddress + ((i * 8 + 8)));

      // Both pma_start and pma_length have to be aligned to a 4KiB boundary.
      // So this leaves the lowest 12 bits for attributes. To find out the actual
      // start and length of the PMAs it is necessary to clean those attribute bits
      // Reference: The Core of Cartesi, v1.02 - Figure 2 - Page 5.
      uint64 pma_start = start_word & 0xfffffffffffff000;
      uint64 pma_length = length_word & 0xfffffffffffff000;

      if(paddr >= pma_start && paddr < (pma_start + pma_length)){
        return (start_word, length_word);
      }

      if(pma_length == 0){
        break;
      }
    }
  }

  // M bit defines if the range is memory
  // The flag is pma_entry start's word first bit
  // Reference: The Core of Cartesi, v1.02 - figure 2.
  function pma_get_istart_M(uint64 start) public returns (bool) {
    return start & 1 == 1;
  }
 
  // X bit defines if the range is executable
  // The flag is pma_entry start's word on position 5.
  // Reference: The Core of Cartesi, v1.02 - figure 2.
  function pma_get_istart_X(uint64 start) public returns (bool) {
    return (start >> 5) & 1 == 1;
  }
}
