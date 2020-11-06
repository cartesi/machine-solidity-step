// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./MemoryInteractor.sol";

/// @title PMA
/// @author Felipe Argento
/// @notice Implements PMA behaviour
library PMA {

    uint64 constant MEMORY_ID = 0; //< DID for memory
    uint64 constant SHADOW_ID = 1; //< DID for shadow device
    uint64 constant DRIVE_ID = 2;  //< DID for drive device
    uint64 constant CLINT_ID = 3;  //< DID for CLINT device
    uint64 constant HTIF_ID = 4;   //< DID for HTIF device

    /// @notice Finds PMA that contains target physical address.
    /// @param mi Memory Interactor with which Step function is interacting.
    //  contains the logs for this Step execution.
    /// @param paddr Target physical address.
    /// @return start of pma if found. If not, returns (0)
    function findPmaEntry(MemoryInteractor mi, uint64 paddr) public returns (uint64) {
        // Hard coded ram address starts at 0x800
        // In total there are 32 PMAs from processor shadow to Flash disk 7.
        // PMA 0 - describes RAM and is hardcoded to address 0x800
        // PMA 16 - 23 describe flash devices 0-7
        // RAM start field is hardcoded to 0x800
        // Reference: The Core of Cartesi, v1.02 - Table 3.
        uint64 pmaAddress = 0x800;
        uint64 lastPma = 62; // 0 - 31 * 2 words

        for (uint64 i = 0; i <= lastPma; i += 2) {
            uint64 startWord = mi.memoryRead(pmaAddress + (i * 8));

            uint64 lengthWord = mi.memoryRead(pmaAddress + ((i * 8 + 8)));

            uint64 pmaStart = pmaGetStart(startWord);
            uint64 pmaLength = pmaGetLength(lengthWord);

            // TO-DO: fix overflow possibility
            if (paddr >= pmaStart && paddr <= (pmaStart + pmaLength)) {
                return startWord;
            }

            if (pmaLength == 0) {
                break;
            }
        }

        return 0;
    }

    // M bit defines if the range is memory
    // The flag is pmaEntry start's word first bit
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartM(uint64 start) public pure returns (bool) {
        return start & 1 == 1;
    }

    // X bit defines if the range is executable
    // The flag is pmaEntry start's word on position 5.
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartX(uint64 start) public pure returns (bool) {
        return (start >> 5) & 1 == 1;
    }

    // E bit defines if the range is excluded
    // The flag is pmaEntry start's word third bit
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartE(uint64 start) public pure returns (bool) {
        return (start >> 2) & 1 == 1;
    }

    // W bit defines write permission
    // The flag is pmaEntry start's word bit on position 4
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartW(uint64 start) public pure returns (bool) {
        return (start >> 4) & 1 == 1;
    }

    // R bit defines read permission
    // The flag is pmaEntry start's word bit on position 3
    // Reference: The Core of Cartesi, v1.02 - figure 2.
    function pmaGetIstartR(uint64 start) public pure returns (bool) {
        return (start >> 3) & 1 == 1;
    }

    function pmaIsCLINT(uint64 startWord) public pure returns (bool) {
        return pmaGetDID(startWord) == CLINT_ID;
    }

    function pmaIsHTIF(uint64 startWord) public pure returns (bool) {
        return pmaGetDID(startWord) == HTIF_ID;
    }

    // Both pmaStart and pmaLength have to be aligned to a 4KiB boundary.
    // So this leaves the lowest 12 bits for attributes. To find out the actual
    // start and length of the PMAs it is necessary to clean those attribute bits
    // Reference: The Core of Cartesi, v1.02 - Figure 2 - Page 5.
    function pmaGetStart(uint64 startWord) internal pure returns (uint64) {
        return startWord & 0xfffffffffffff000;
    }

    function pmaGetLength(uint64 lengthWord) internal pure returns (uint64) {
        return lengthWord & 0xfffffffffffff000;
    }

    // DID is encoded on bytes 8 - 11 of pma's start word.
    // It defines the devices id.
    // 0 for memory ranges
    // 1 for shadows
    // 1 for drive
    // 3 for CLINT
    // 4 for HTIF
    // Reference: The Core of Cartesi, v1.02 - Figure 2 - Page 5.
    function pmaGetDID(uint64 startWord) internal pure returns (uint64) {
        return (startWord >> 8) & 0x0F;
    }

}
