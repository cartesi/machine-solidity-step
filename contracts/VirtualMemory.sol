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

import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./MemoryInteractor.sol";
import "./PMA.sol";
import "./CLINT.sol";
import "./HTIF.sol";
import "./Exceptions.sol";

/// @title Virtual Memory
/// @author Felipe Argento
/// @notice Defines Virtual Memory behaviour
library VirtualMemory {

    // Variable positions on their respective array.
    // This is not an enum because enum assumes the type from the number of variables
    // So we would have to explicitly cast to uint256 on every single access
    uint256 constant PRIV = 0;
    uint256 constant MODE= 1;
    uint256 constant VADDR_SHIFT = 2;
    uint256 constant PTE_SIZE_LOG2 = 3;
    uint256 constant VPN_BITS = 4;
    uint256 constant SATP_PPN_BITS = 5;

    uint256 constant VADDR_MASK = 0;
    uint256 constant PTE_ADDR = 1;
    uint256 constant MSTATUS = 2;
    uint256 constant SATP = 3;
    uint256 constant VPN_MASK = 4;
    uint256 constant PTE = 5;

    // Write/Read Virtual Address variable indexes
    uint256 constant OFFSET = 0;
    uint256 constant PMA_START = 1;
    uint256 constant PADDR = 2;
    uint256 constant VAL = 3;

    /// @notice Read word to virtual memory
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @param vaddr is the words virtual address
    /// @return True if write was succesfull, false if not.
    /// @return Word with receiveing value.
    function readVirtualMemory(
        MemoryInteractor mi,
        uint64 wordSize,
        uint64 vaddr
    )
    public returns(bool, uint64)
    {
        uint64[6] memory uint64vars;
        if (vaddr & (wordSize/8 - 1) != 0) {
            // Word is not aligned - raise exception
            Exceptions.raiseException(
                mi,
                Exceptions.getMcauseLoadAddressMisaligned(),
                vaddr
            );
            return (false, 0);
        } else {
            (bool translateSuccess, uint64 paddr) = translateVirtualAddress(
                mi,
                vaddr,
                RiscVConstants.getPteXwrReadShift()
            );

            if (!translateSuccess) {
                // translation failed - raise exception
                Exceptions.raiseException(
                    mi,
                    Exceptions.getMcauseLoadPageFault(),
                    vaddr
                );
                return (false, 0);
            }
            uint64vars[PMA_START] = PMA.findPmaEntry(mi, paddr);
            if (PMA.pmaGetIstartE(uint64vars[PMA_START]) || !PMA.pmaGetIstartR(uint64vars[PMA_START])) {
                // PMA is either excluded or we dont have permission to write - raise exception
                Exceptions.raiseException(
                    mi,
                    Exceptions.getMcauseLoadAccessFault(),
                    vaddr
                );
                return (false, 0);
            } else if (PMA.pmaGetIstartM(uint64vars[PMA_START])) {
                return (true, mi.readMemory(paddr, wordSize));
            }else {
                bool success = false;
                if (PMA.pmaIsHTIF(uint64vars[PMA_START])) {
                    (success, uint64vars[VAL]) = HTIF.htifRead(
                        mi,
                        paddr,
                        wordSize
                    );
                } else if (PMA.pmaIsCLINT(uint64vars[PMA_START])) {
                    (success, uint64vars[VAL]) = CLINT.clintRead(
                        mi,
                        paddr,
                        wordSize
                    );
                }
                if (!success) {
                    Exceptions.raiseException(
                        mi,
                        Exceptions.getMcauseLoadAccessFault(),
                        vaddr
                    );
                }
                return (success, uint64vars[VAL]);
            }
        }
    }

    /// @notice Writes word to virtual memory
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @param vaddr is the words virtual address
    /// @param val is the value to be written
    /// @return True if write was succesfull, false if not.
    function writeVirtualMemory(
        MemoryInteractor mi,
        uint64 wordSize,
        uint64 vaddr,
        uint64 val
    )
    public returns (bool)
    {
        uint64[6] memory uint64vars;

        if (vaddr & ((wordSize / 8) - 1) != 0) {
            // Word is not aligned - raise exception
            Exceptions.raiseException(
                mi,
                Exceptions.getMcauseStoreAmoAddressMisaligned(),
                vaddr
            );
            return false;
        } else {
            bool translateSuccess;
            (translateSuccess, uint64vars[PADDR]) = translateVirtualAddress(
                mi,
                vaddr,
                RiscVConstants.getPteXwrWriteShift()
            );

            if (!translateSuccess) {
                // translation failed - raise exception
                Exceptions.raiseException(
                    mi,
                    Exceptions.getMcauseStoreAmoPageFault(),
                    vaddr);

                return false;
            }
            uint64vars[PMA_START] = PMA.findPmaEntry(mi, uint64vars[PADDR]);

            if (PMA.pmaGetIstartE(uint64vars[PMA_START]) || !PMA.pmaGetIstartW(uint64vars[PMA_START])) {
                // PMA is either excluded or we dont have permission to write - raise exception
                Exceptions.raiseException(
                    mi,
                    Exceptions.getMcauseStoreAmoAccessFault(),
                    vaddr
                );
                return false;
            } else if (PMA.pmaGetIstartM(uint64vars[PMA_START])) {
                //write to memory
                mi.writeMemory(
                    uint64vars[PADDR],
                    val,
                    wordSize
                );
                return true;
            } else {

                if (PMA.pmaIsHTIF(uint64vars[PMA_START])) {
                    if (!HTIF.htifWrite(
                       mi,
                       PMA.pmaGetStart(uint64vars[PMA_START]), val, wordSize
                    )) {
                        Exceptions.raiseException(
                            mi,
                            Exceptions.getMcauseStoreAmoAccessFault(),
                            vaddr
                        );
                        return false;
                    }
                } else if (PMA.pmaIsCLINT(uint64vars[PMA_START])) {
                    if (!CLINT.clintWrite(
                            mi,
                            PMA.pmaGetStart(uint64vars[PMA_START]), val, wordSize
                    )) {
                        Exceptions.raiseException(
                            mi,
                            Exceptions.getMcauseStoreAmoAccessFault(),
                            vaddr
                        );
                        return false;
                    }
                }
                return true;
            }
        }
    }

    // Finds the physical address associated to the virtual address (vaddr).
    // Walks the page table until it finds a valid one. Returns a bool if the physical
    // address was succesfully found along with the address. Returns false and zer0
    // if something went wrong.

    // Virtual Address Translation proccess is defined, step by step on the following Reference:
    // Reference: riscv-priv-spec-1.10.pdf - Section 4.3.2, page 62.
    function translateVirtualAddress(
        MemoryInteractor mi,
        uint64 vaddr,
        int xwrShift
    )
    public returns(bool, uint64)
    {
        //TO-DO: check shift + mask
        //TO-DO: use bitmanipulation right shift

        // Through arrays we force variables that were being put on stack to be stored
        // in memory. It is more expensive, but the stack only supports 16 variables.
        uint64[6] memory uint64vars;
        int[6] memory intvars;

        // Reads privilege level on iflags register. The privilege level is located
        // on bits 2 and 3.
        // Reference: The Core of Cartesi, v1.02 - figure 1.
        intvars[PRIV] = mi.readIflagsPrv();

        //readMstatus
        uint64vars[MSTATUS] = mi.memoryRead(ShadowAddresses.getMstatus());

        // When MPRV is set, data loads and stores use privilege in MPP
        // instead of the current privilege level (code access is unaffected)
        //TO-DO: Check this &/&& and shifts
        if ((uint64vars[MSTATUS] & RiscVConstants.getMstatusMprvMask() != 0) && (xwrShift != RiscVConstants.getPteXwrCodeShift())) {
            intvars[PRIV] = (uint64vars[MSTATUS] & RiscVConstants.getMstatusMppMask()) >> RiscVConstants.getMstatusMppShift();
        }

        // Physical memory is mediated by Machine-mode so, if privilege is M-mode it
        // does not use virtual Memory
        // Reference: riscv-priv-spec-1.7.pdf - Section 3.3, page 32.
        if (intvars[PRIV] == RiscVConstants.getPrvM()) {
            return (true, vaddr);
        }

        // SATP - Supervisor Address Translation and Protection Register
        // Holds MODE, Physical page number (PPN) and address space identifier (ASID)
        // MODE is located on bits 60 to 63 for RV64.
        // Reference: riscv-priv-spec-1.10.pdf - Section 4.1.12, page 56.
        uint64vars[SATP] = mi.memoryRead(ShadowAddresses.getSatp());
        // In RV64, mode can be
        //   0: Bare: No translation or protection
        //   8: sv39: Page-based 39-bit virtual addressing
        //   9: sv48: Page-based 48-bit virtual addressing
        // Reference: riscv-priv-spec-1.10.pdf - Table 4.3, page 57.
        intvars[MODE] = (uint64vars[SATP] >> 60) & 0xf;

        if (intvars[MODE] == 0) {
            return(true, vaddr);
        } else if (intvars[MODE] < 8 || intvars[MODE] > 9) {
            return(false, 0);
        }
        // Here we know we are in sv39 or sv48 modes

        // Page table hierarchy of sv39 has 3 levels, and sv48 has 4 levels
        int levels = intvars[MODE] - 8 + 3;
        // Page offset are bits located from 0 to 11.
        // Then come levels virtual page numbers (VPN)
        // The rest of vaddr must be filled with copies of the
        // most significant bit in VPN[levels]
        // Hence, the use of arithmetic shifts here
        // Reference: riscv-priv-spec-1.10.pdf - Figure 4.16, page 63.

        //TO-DO: Use bitmanipulation library for arithmetic shift
        intvars[VADDR_SHIFT] = RiscVConstants.getXlen() - (RiscVConstants.getPgShift() + levels * 9);
        if (((int64(vaddr) << uint64(intvars[VADDR_SHIFT])) >> uint64(intvars[VADDR_SHIFT])) != int64(vaddr)) {
            return (false, 0);
        }
        // The least significant 44 bits of satp contain the physical page number
        // for the root page table
        // Reference: riscv-priv-spec-1.10.pdf - Figure 4.12, page 57.
        intvars[SATP_PPN_BITS] = 44;
        // Initialize pteAddr with the base address for the root page table
        uint64vars[PTE_ADDR] = (uint64vars[SATP] & ((uint64(1) << uint64(intvars[SATP_PPN_BITS])) - 1)) << RiscVConstants.getPgShift();
        // All page table entries have 8 bytes
        // Each page table has 4k/pteSize entries
        // To index all entries, we need vpnBits
        // Reference: riscv-priv-spec-1.10.pdf - Section 4.4.1, page 63.
        intvars[PTE_SIZE_LOG2] = 3;
        intvars[VPN_BITS] = 12 - intvars[PTE_SIZE_LOG2];
        uint64vars[VPN_MASK] = uint64((1 << uint(intvars[VPN_BITS])) - 1);

        for (int i = 0; i < levels; i++) {
            // Mask out VPN[levels -i-1]
            intvars[VADDR_SHIFT] = RiscVConstants.getPgShift() + intvars[VPN_BITS] * (levels - 1 - i);
            uint64 vpn = (vaddr >> uint(intvars[VADDR_SHIFT])) & uint64vars[VPN_MASK];
            // Add offset to find physical address of page table entry
            uint64vars[PTE_ADDR] += vpn << uint64(intvars[PTE_SIZE_LOG2]);
            //Read page table entry from physical memory
            bool readRamSucc;
            (readRamSucc, uint64vars[PTE]) = readRamUint64(mi, uint64vars[PTE_ADDR]);

            if (!readRamSucc) {
                return(false, 0);
            }

            // The OS can mark page table entries as invalid,
            // but these entries shouldn't be reached during page lookups
            //TO-DO: check if condition
            if ((uint64vars[PTE] & RiscVConstants.getPteVMask()) == 0) {
                return (false, 0);
            }
            // Clear all flags in least significant bits, then shift back to multiple of page size to form physical address
            uint64 ppn = (uint64vars[PTE] >> 10) << RiscVConstants.getPgShift();
            // Obtain X, W, R protection bits
            // X, W, R bits are located on bits 1 to 3 on physical address
            // Reference: riscv-priv-spec-1.10.pdf - Figure 4.18, page 63.
            int xwr = (uint64vars[PTE] >> 1) & 7;
            // xwr !=0 means we are done walking the page tables
            if (xwr != 0) {
                // These protection bit combinations are reserved for future use
                if (xwr == 2 || xwr == 6) {
                    return (false, 0);
                }
                // (We know we are not PRV_M if we reached here)
                if (intvars[PRIV] == RiscVConstants.getPrvS()) {
                    // If SUM is set, forbid S-mode code from accessing U-mode memory
                    //TO-DO: check if condition
                    if ((uint64vars[PTE] & RiscVConstants.getPteUMask() != 0) && ((uint64vars[MSTATUS] & RiscVConstants.getMstatusSumMask())) == 0) {
                        return (false, 0);
                    }
                } else {
                    // Forbid U-mode code from accessing S-mode memory
                    if ((uint64vars[PTE] & RiscVConstants.getPteUMask()) == 0) {
                        return (false, 0);
                    }
                }
                // MXR allows to read access to execute-only pages
                if (uint64vars[MSTATUS] & RiscVConstants.getMstatusMxrMask() != 0) {
                    //Set R bit if X bit is set
                    xwr = xwr | (xwr >> 2);
                }
                // Check protection bits against request access
                if (((xwr >> uint(xwrShift)) & 1) == 0) {
                    return (false, 0);
                }
                // Check page, megapage, and gigapage alignment
                uint64vars[VADDR_MASK] = (uint64(1) << uint64(intvars[VADDR_SHIFT])) - 1;
                if (ppn & uint64vars[VADDR_MASK] != 0) {
                    return (false, 0);
                }
                // Decide if we need to update access bits in pte
                bool updatePte = (uint64vars[PTE] & RiscVConstants.getPteAMask() == 0) || ((uint64vars[PTE] & RiscVConstants.getPteDMask() == 0) && xwrShift == RiscVConstants.getPteXwrWriteShift());

                uint64vars[PTE] |= RiscVConstants.getPteAMask();

                if (xwrShift == RiscVConstants.getPteXwrWriteShift()) {
                    uint64vars[PTE] = uint64vars[PTE] | RiscVConstants.getPteDMask();
                }
                // If so, update pte
                if (updatePte) {
                    writeRamUint64(
                        mi,
                        uint64vars[PTE_ADDR],
                        uint64vars[PTE]
                    );
                }
                // Add page offset in vaddr to ppn to form physical address
                return (true, (vaddr & uint64vars[VADDR_MASK]) | (ppn & ~uint64vars[VADDR_MASK]));
            }else {
                uint64vars[PTE_ADDR] = ppn;
            }
        }
        return (false, 0);
    }

    function readRamUint64(MemoryInteractor mi, uint64 paddr)
    internal returns (bool, uint64)
    {
        uint64 pmaStart = PMA.findPmaEntry(mi, paddr);
        if (!PMA.pmaGetIstartM(pmaStart) || !PMA.pmaGetIstartR(pmaStart)) {
            return (false, 0);
        }
        return (true, mi.readMemory(paddr, 64));
    }

    function writeRamUint64(
        MemoryInteractor mi,
        uint64 paddr,
        uint64 val
    )
    internal returns (bool)
    {
        uint64 pmaStart = PMA.findPmaEntry(mi, paddr);
        if (!PMA.pmaGetIstartM(pmaStart) || !PMA.pmaGetIstartW(pmaStart)) {
            return false;
        }
        mi.writeMemory(
            paddr,
            val,
            64
        );
        return true;
    }

}
