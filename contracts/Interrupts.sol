/// @title Interrupts
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/RiscVConstants.sol";
import "../contracts/Exceptions.sol";


library Interrupts {

    // \brief Raises an interrupt if any are enabled and pending.
    // \param mi Memory Interactor with which Step function is interacting.
    // \param mmIndex Index corresponding to the instance of Memory Manager that.
    function raiseInterruptIfAny(uint256 mmIndex, MemoryInteractor mi) public {
        uint32 mask = getPendingIrqMask(mmIndex, mi);
        if (mask != 0) {
            uint64 irqNum = ilog2(mask);
            Exceptions.raiseException(
                mi,
                mmIndex,
                irqNum | Exceptions.getMcauseInterruptFlag(),
                0
            );
        }
    }

    // Machine Interrupt Registers: mip and mie.
    // mip register contains information on pending interrupts.
    // mie register contains the interrupt enabled bits.
    // Reference: riscv-privileged-v1.10 - section 3.1.14 - page 28.
    function getPendingIrqMask(uint256 mmIndex, MemoryInteractor mi) internal returns (uint32) {
        uint64 mip = mi.readMip(mmIndex);
        uint64 mie = mi.readMie(mmIndex);

        uint32 pendingInts = uint32(mip & mie);
        // if there are no pending interrupts, return 0.
        if (pendingInts == 0) {
            return 0;
        }
        uint64 mstatus = 0;
        uint32 enabledInts = 0;

        // Read privilege level on iflags register.
        // The privilege level is represented by bits 2 and 3 on iflags register.
        // Reference: The Core of Cartesi, v1.02 - figure 1.
        uint64 priv = mi.readIflagsPrv(mmIndex);

        if (priv == RiscVConstants.getPrvM()) {
            // MSTATUS is the Machine Status Register - it controls the current
            // operating state. The MIE is an interrupt-enable bit for machine mode.
            // MIE for 64bit is stored on location 3 - according to:
            // Reference: riscv-privileged-v1.10 - figure 3.7 - page 20.
            mstatus = mi.readMstatus(mmIndex);

            if ((mstatus & RiscVConstants.getMstatusMieMask()) != 0) {
                enabledInts = uint32(~mi.readMideleg(mmIndex));
            }
        } else if (priv == RiscVConstants.getPrvS()) {
            // MIDELEG: Machine trap delegation register
            // mideleg defines if a interrupt can be proccessed by a lower privilege
            // level. If mideleg bit is set, the trap will delegated to the S-Mode.
            // Reference: riscv-privileged-v1.10 - Section 3.1.13 - page 27.
            mstatus = mi.readMstatus(mmIndex);
            uint64 mideleg = mi.readMideleg(mmIndex);
            enabledInts = uint32(~mideleg);

            // SIE: is the register contaning interrupt enabled bits for supervisor mode.
            // It is located on the first bit of mstatus register (RV64).
            // Reference: riscv-privileged-v1.10 - figure 3.7 - page 20.
            if ((mstatus & RiscVConstants.getMstatusSieMask()) != 0) {
                //TO-DO: make sure this is the correct cast
                enabledInts = enabledInts | uint32(mideleg);
            }
        } else {
            enabledInts = uint32(-1);
        }
        return pendingInts & enabledInts;
    }

    //TO-DO: optmize log2 function
    function ilog2(uint32 v) public returns(uint64) {
        //cpp emulator code:
        //return 31 - _BuiltinClz(v)

        uint leading = 32;
        while (v != 0) {
            v = v >> 1;
            leading--;
        }
        return uint64(31 - leading);
    }
}
