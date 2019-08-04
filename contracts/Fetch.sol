pragma solidity ^0.5.0;

import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "../contracts/MemoryInteractor.sol";
import "../contracts/PMA.sol";
import "../contracts/VirtualMemory.sol";
import "../contracts/Exceptions.sol";

/// @title Fetch
/// @author Felipe Argento
/// @notice Implements main CSR read and write logic
library Fetch {

    /// @notice Finds and loads next insn.
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param mmIndex Index corresponding to the instance of Memory Manager that
    /// @return Returns fetchStatus.success if load was successful, excpetion if not.
    /// @return Returns instructions
    /// @return Returns pc
    function fetchInsn(uint256 mmIndex, MemoryInteractor mi) public returns (fetchStatus, uint32, uint64) {
        bool translateBool;
        uint64 paddr;

        //readPc
        uint64 pc = mi.readPc(mmIndex);
        (translateBool, paddr) = VirtualMemory.translateVirtualAddress(
            mi,
            mmIndex,
            pc,
            RiscVConstants.getPteXwrCodeShift()
        );

        //translateVirtualAddress failed
        if (!translateBool) {
            Exceptions.raiseException(
                mi,
                mmIndex,
                Exceptions.getMcauseFetchPageFault(),
                pc
            );
            //returns fetchException and returns zero as insn and pc
            return (fetchStatus.exception, 0, 0);
        }

        // Finds the range in memory in which the physical address is located
        // Returns start and length words from pma
        uint64 pmaStart = PMA.findPmaEntry(mi, mmIndex, paddr);

        // M flag defines if the pma range is in memory
        // X flag defines if the pma is executable
        // If the pma is not memory or not executable - this is a pma violation
        // Reference: The Core of Cartesi, v1.02 - section 3.2 the board - page 5.
        if (!PMA.pmaGetIstartM(pmaStart) || !PMA.pmaGetIstartX(pmaStart)) {
            Exceptions.raiseException(
                mi,
                mmIndex,
                Exceptions.getMcauseInsnAccessFault(),
                paddr
            );
            return (fetchStatus.exception, 0, 0);
        }

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
