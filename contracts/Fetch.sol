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

    function fetchInsn(uint256 mmIndex, address memoryInteractorAddress) public returns (fetchStatus, uint32, uint64) {
        MemoryInteractor mi = MemoryInteractor(memoryInteractorAddress);

        bool translateBool;
        uint64 paddr;

        //readPc
        uint64 pc = mi.memoryRead(mmIndex, ShadowAddresses.getPc());
        (translateBool, paddr) = VirtualMemory.translateVirtualAddress(
            mi,
            mmIndex,
            pc,
            RiscVConstants.PTE_XWR_CODE_SHIFT()
        );

        //translateVirtualAddress failed
        if (!translateBool) {
            Exceptions.raiseException(
                mi,
                mmIndex,
                Exceptions.MCAUSE_FETCH_PAGE_FAULT(),
                paddr
            );
            //returns fetchException and returns zero as insn and pc
            return (fetchStatus.exception, 0, 0);
        }

        // Finds the range in memory in which the physical address is located
        // Returns start and length words from pma
        (uint64 pmaStart, uint64 pmaLength) = PMA.findPmaEntry(mi, mmIndex, paddr);

        //emit Print("pmaEntry.start", pmaEntry.start);
        //emit Print("pmaEntry.length", pmaEntry.length);

        // M flag defines if the pma range is in memory
        // X flag defines if the pma is executable
        // If the pma is not memory or not executable - this is a pma violation
        // Reference: The Core of Cartesi, v1.02 - section 3.2 the board - page 5.

        if (!PMA.pmaGetIstart_M(pmaStart) || !PMA.pmaGetIstart_X(pmaStart)) {
            //emit Print("CAUSE_FETCH_FAULT", paddr);
            Exceptions.raiseException(
                mi,
                mmIndex,
                Exceptions.MCAUSE_INSN_ACCESS_FAULT(),
                paddr
            );
            return (fetchStatus.exception, 0, 0);
        }

        //emit Print("paddr/insn", paddr);
        uint32 insn = 0;

        // Check if instruction is on first 32 bits or last 32 bits
        if ((paddr & 7) == 0) {
            insn = uint32(mi.memoryRead(mmIndex, paddr));
        } else {
            // If not aligned, read at the last addr and shift to get the correct insn
            uint64 fullMemory = mi.memoryRead(mmIndex, paddr - 4);
            insn = uint32(fullMemory >> 32);
        }

        return (fetchStatus.success, insn, pc);
    }

    enum fetchStatus {
        exception, //failed: exception raised
        success
    }
}
