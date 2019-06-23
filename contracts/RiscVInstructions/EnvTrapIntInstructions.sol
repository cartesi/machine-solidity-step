// TO-DO: Add documentation explaining each instruction

/// @title EnvTrapIntInstruction
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";
import "../../contracts/RiscVConstants.sol";
import "../../contracts/Exceptions.sol";


library EnvTrapIntInstructions {
    function executeECALL(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint64 pc
    ) public
    {
        uint64 priv = mi.readIflagsPRV(mmIndex);
        uint64 mtval = mi.readMtval(mmIndex);
        // TO-DO: Are parameter valuation order deterministic? If so, we dont need to allocate memory
        Exceptions.raiseException(
            mi,
            mmIndex,
            Exceptions.MCAUSE_ECALL_BASE() + priv,
            mtval
        );
    }

    function executeEBREAK(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint64 pc
    ) public
    {
        Exceptions.raiseException(
            mi,
            mmIndex,
            Exceptions.MCAUSE_BREAKPOINT(),
            mi.readMtval(mmIndex)
        );
    }

    function executeSRET(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint64 pc
    )
    public returns (bool)
    {
        uint64 priv = mi.readIflags_PRV(mmIndex);
        uint64 mstatus = mi.readMstatus(mmIndex);

        if (priv < RiscVConstants.PRV_S() || (priv == RiscVConstants.PRV_S() && (mstatus & RiscVConstants.MSTATUS_TSR_MASK() != 0))) {
            return false;
        } else {
            uint64 spp = (mstatus & RiscVConstants.MSTATUS_SPP_MASK()) >> RiscVConstants.MSTATUS_SPP_SHIFT();
            // Set the IE state to previous IE state
            uint64 spie = (mstatus & RiscVConstants.MSTATUS_SPIE_MASK()) >> RiscVConstants.MSTATUS_SPIE_SHIFT();
            mstatus = (mstatus & ~RiscVConstants.MSTATUS_SIE_MASK()) | (spie << RiscVConstants.MSTATUS_SIE_SHIFT());

            // set SPIE to 1
            mstatus |= RiscVConstants.MSTATUS_SPIE_MASK();
            // set SPP to U
            mstatus &= ~RiscVConstants.MSTATUS_SPP_MASK();
            mi.writeMstatus(mmIndex, mstatus);
            if (priv != spp) {
                mi.setPriv(mmIndex, spp);
            }
            mi.writePc(mmIndex, mi.readSepc(mmIndex));
            return true;
        }
    }

    function executeMRET(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint64 pc
    )
    public returns(bool)
    {
        uint64 priv = mi.readIflags_PRV(mmIndex);

        if (priv < RiscVConstants.PRV_M()) {
            return false;
        } else {
            uint64 mstatus = mi.readMstatus(mmIndex);
            uint64 mpp = (mstatus & RiscVConstants.MSTATUS_MPP_MASK()) >> RiscVConstants.MSTATUS_MPP_SHIFT();
            // set IE state to previous IE state
            uint64 mpie = (mstatus & RiscVConstants.MSTATUS_MPIE_MASK()) >> RiscVConstants.MSTATUS_MPIE_SHIFT();
            mstatus = (mstatus & ~RiscVConstants.MSTATUS_MIE_MASK()) | (mpie << RiscVConstants.MSTATUS_MIE_SHIFT());

            // set MPIE to 1
            mstatus |= RiscVConstants.MSTATUS_MPIE_MASK();
            // set MPP to U
            mstatus &= ~RiscVConstants.MSTATUS_MPP_MASK();
            mi.writeMstatus(mmIndex, mstatus);

            if (priv != mpp) {
                mi.setPriv(mmIndex, mpp);
            }
            mi.writePc(mmIndex, mi.readMepc(mmIndex));
            return true;
        }
    }

    function executeWFI(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint64 pc
    )
    public returns(bool)
    {
        uint64 priv = mi.readIflags_PRV(mmIndex);
        uint64 mstatus = mi.readMstatus(mmIndex);

        if (priv == RiscVConstants.PRV_U() || (priv == RiscVConstants.PRV_S() && (mstatus & RiscVConstants.MSTATUS_TW_MASK() != 0))) {
            return false;
        } else {
            uint64 mip = mi.readMip(mmIndex);
            uint64 mie = mi.readMie(mmIndex);
            // Go to power down if no enable interrupts are pending
            if ((mip & mie) == 0) {
                mi.setIflags_I(mmIndex, true);
            }
            return true;
        }
    }
}
