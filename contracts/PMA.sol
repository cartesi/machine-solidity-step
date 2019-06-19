/// @title PMA
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";

library PMA { 
  // 0 for memory ranges
  // 1 for shadows
  // 2 for CLINT
  // 3 for HTIF

  uint64 constant MEMORY_ID = 0;
  uint64 constant SHADOW_ID = 1;
  uint64 constant CLINT_ID = 2;
  uint64 constant HTIF_ID = 3;



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

    for(uint64 i = 0; i < lastPma; i += 2){
      uint64 start_word = mi.memoryRead(mmIndex, pmaAddress + (i * 8));

      uint64 length_word = mi.memoryRead(mmIndex, pmaAddress + ((i * 8 + 8)));

      uint64 pma_start = pma_get_start(start_word);
      uint64 pma_length = pma_get_length(length_word);

      // TO-DO: fix this - should check for aligned addr
      if(paddr >= pma_start && paddr <= (pma_start + pma_length)){
        return (start_word, length_word);
      }

      if(pma_length == 0){
        break;
      }
    }

    return (0, 0);
  }
  // Both pma_start and pma_length have to be aligned to a 4KiB boundary.
  // So this leaves the lowest 12 bits for attributes. To find out the actual
  // start and length of the PMAs it is necessary to clean those attribute bits
  // Reference: The Core of Cartesi, v1.02 - Figure 2 - Page 5.
  function pma_get_start(uint64 start_word) public returns (uint64){
    return start_word & 0xfffffffffffff000;
  }

  function pma_get_length(uint64 length_word) public returns (uint64){
    return length_word & 0xfffffffffffff000;
  }

  // DID is encoded on bytes 8 - 11 of pma's start word.
  // It defines the devices id.
  // 0 for memory ranges
  // 1 for shadows
  // 2 for CLINT
  // 3 for HTIF
  // Reference: The Core of Cartesi, v1.02 - Figure 2 - Page 5.
  function pma_get_DID(uint64 start_word) internal returns (uint64) {
    return (start_word >> 8) & 0x0F;
  }

  function pma_is_CLINT(uint64 start_word) public returns (bool) {
    return pma_get_DID(start_word) == CLINT_ID;
  }

  function pma_is_HTIF(uint64 start_word) public returns (bool) {
    return pma_get_DID(start_word) == HTIF_ID;
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

  // E bit defines if the range is excluded
  // The flag is pma_entry start's word third bit
  // Reference: The Core of Cartesi, v1.02 - figure 2.
  function pma_get_istart_E(uint64 start) public returns (bool) {
    return (start >> 2) & 1 == 1;
  }

  // W bit defines write permission
  // The flag is pma_entry start's word bit on position 4
  // Reference: The Core of Cartesi, v1.02 - figure 2.
  function pma_get_istart_W(uint64 start) public returns (bool) {
    return (start >> 4) & 1 == 1;
  }
  // R bit defines read permission
  // The flag is pma_entry start's word bit on position 3
  // Reference: The Core of Cartesi, v1.02 - figure 2.
  function pma_get_istart_R(uint64 start) public returns (bool) {
    return (start >> 3) & 1 == 1;
  }
}
