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

    function findPmaEntry(MemoryInteractor mi, uint256 mmIndex, uint64 paddr) public returns (uint64, uint64) {
        // Hard coded ram address starts at 0x800
        // In total there are 32 PMAs from processor shadow to Flash disk 7.
        // PMA 0 - describes RAM and is hardcoded to address 0x800
        // PMA 16 - 23 describe flash devices 0-7
        // RAM start field is hardcoded to 0x800
        // Reference: The Core of Cartesi, v1.02 - Table 3.
        uint64 pmaAddress = 0x800;
        uint64 lastPma = 62; // 0 - 31 * 2 words

        for (uint64 i = 0; i <= lastPma; i += 2) {
            uint64 startWord = mi.memoryRead(mmIndex, pmaAddress + (i * 8));

            uint64 lengthWord = mi.memoryRead(mmIndex, pmaAddress + ((i * 8 + 8)));

            uint64 pmaStart = pmaGetStart(startWord);
            uint64 pmaLength = pmaGetLength(lengthWord);

            // TO-DO: fix this - should check for aligned addr
            if (paddr >= pmaStart && paddr <= (pmaStart + pmaLength)) {
                return (startWord, lengthWord);
            }

            if (pmaLength == 0) {
                break;
            }
        }

        return (0, 0);
    }

    // Both pmaStart and pmaLength have to be aligned to a 4KiB boundary.
    // So this leaves the lowest 12 bits for attributes. To find out the actual
    // start and length of the PMAs it is necessary to clean those attribute bits
    // Reference: The Core of Cartesi, v1.02 - Figure 2 - Page 5.
    function pmaGetStart(uint64 startWord) public returns (uint64) {
        return startWord & 0xfffffffffffff000;
    }

    function pmaGetLength(uint64 lengthWord) public returns (uint64) {
        return lengthWord & 0xfffffffffffff000;
    }

    // DID is encoded on bytes 8 - 11 of pma's start word.
    // It defines the devices id.
    // 0 for memory ranges
    // 1 for shadows
    // 2 for CLINT
    // 3 for HTIF
    // Reference: The Core of Cartesi, v1.02 - Figure 2 - Page 5.
    function pmaGetDID(uint64 startWord) internal returns (uint64) {
        return (startWord >> 8) & 0x0F;
    }

    function pmaIsCLINT(uint64 startWord) public returns (bool) {
        return pmaGetDID(startWord) == CLINT_ID;
    }

    function pmaIsHTIF(uint64 startWord) public returns (bool) {
        return pmaGetDID(startWord) == HTIF_ID;
    }

    // M bit defines if the range is memory
    // The flag is pmaEntry start's word first bit
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartM(uint64 start) public returns (bool) {
        return start & 1 == 1;
    }

    // X bit defines if the range is executable
    // The flag is pmaEntry start's word on position 5.
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartX(uint64 start) public returns (bool) {
        return (start >> 5) & 1 == 1;
    }

    // E bit defines if the range is excluded
    // The flag is pmaEntry start's word third bit
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartE(uint64 start) public returns (bool) {
        return (start >> 2) & 1 == 1;
    }

    // W bit defines write permission
    // The flag is pmaEntry start's word bit on position 4
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartW(uint64 start) public returns (bool) {
        return (start >> 4) & 1 == 1;
    }

    // R bit defines read permission
    // The flag is pmaEntry start's word bit on position 3
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartR(uint64 start) public returns (bool) {
        return (start >> 3) & 1 == 1;
    }
}
