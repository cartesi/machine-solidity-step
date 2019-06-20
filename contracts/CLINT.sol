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
    function clintRead(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pmaStartWord,
        uint64 pmaLengthWord,
        uint64 offset,
        uint64 wordSize
    )
    public returns (bool, uint64)
    {

        if (offset == CLINT_MSIP0_ADDR) {
            return clintReadMsip(mi, mmIndex, wordSize);
        } else if (offset == CLINT_MTIMECMP_ADDR) {
            return clintReadMtime(mi, mmIndex, wordSize);
        } else if (offset == CLINT_MTIME_ADDR) {
            return clintReadMtimecmp(mi, mmIndex, wordSize);
        } else {
            return (false, 0);
        }
    }

    // \brief write to clint
    // \param pmaStartWord first word, defines pma's start
    // \param pmaLengthWord second word, defines pma's length
    // \param offset can be uint8, uint16, uint32 or uint64
    // \param wordsize can be uint8, uint16, uint32 or uint64
    // \return bool if read was successfull
    // \return uint64 pval
    function clintWrite(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 pmaStartWord,
        uint64 pmaLengthWord,
        uint64 offset,
        uint64 val,
        uint64 wordSize)
    public returns (bool)
    {
        if (offset == CLINT_MSIP0_ADDR) {
            if (wordSize == 32) {
                if ((val & 1) != 0) {
                    mi.setMip(mmIndex, RiscVConstants.MIP_MSIP_MASK());
                } else {
                    mi.resetMip(mmIndex, RiscVConstants.MIP_MSIP_MASK());
                }
                return true;
            }
            return false;
        } else if (offset == CLINT_MTIMECMP_ADDR) {
            if (wordSize == 64) {
                mi.writeClintMtimecmp(mmIndex, val);
                mi.resetMip(mmIndex, RiscVConstants.MIP_MSIP_MASK());
                return true;
            }
            // partial mtimecmp is not supported
            return false;
        }
        return false;
    }

    // internal functions
    function clintReadMsip(MemoryInteractor mi, uint256 mmIndex, uint64 wordSize)
    internal returns (bool, uint64)
    {
        if (wordSize == 32) {
            if ((mi.readMip(mmIndex) & RiscVConstants.MIP_MSIP_MASK()) == RiscVConstants.MIP_MSIP_MASK()) {
                return(true, 1);
            } else {
                return (true, 0);
            }
        }
        return (false, 0);
    }

    function clintReadMtime(MemoryInteractor mi, uint256 mmIndex, uint64 wordSize)
    internal returns (bool, uint64)
    {
        if (wordSize == 64) {
            return (true, RealTimeClock.rtcCycleToTime(mi.readMcycle(mmIndex)));
        }
        return (false, 0);
    }

    function clintReadMtimecmp(MemoryInteractor mi, uint256 mmIndex, uint64 wordSize)
    internal returns (bool, uint64)
    {
        if (wordSize == 64) {
            return (true, mi.readClintMtimecmp(mmIndex));
        }
        return (false, 0);
    }

    // getters
    function clintMtimecmp() public returns (uint64) {
        return CLINT_MTIMECMP_ADDR;
    }
}


