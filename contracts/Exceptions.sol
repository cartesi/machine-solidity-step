/// @title Exceptions
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/RiscVConstants.sol";


library Exceptions {
    function getMcauseInsnAddressMisaligned() public returns(uint64) {return 0x0;}
    function getMcauseInsnAccessFault() public returns(uint64) {return 0x1;}
    function getMcauseIllegalInsn() public returns(uint64) {return 0x2;}
    function getMcauseBreakpoint() public returns(uint64) {return 0x3;}
    function getMcauseLoadAddressMisaligned() public returns(uint64) {return 0x4;}
    function getMcauseLoadAccessFault() public returns(uint64) {return 0x5;}
    function getMcauseStoreAmoAddressMisaligned () public returns(uint64) {return 0x6;}
    function getMcauseStoreAmoAccessFault() public returns(uint64) {return 0x7;}
    function getMcauseEcallBase() public returns(uint64) {return 0x8;}
    function getMcauseFetchPageFault() public returns(uint64) {return 0xc;}
    function getMcauseLoadPageFault() public returns(uint64) {return 0xd;}
    function getMcauseStoreAmoPageFault() public returns(uint64) {return 0xf;}

    function getMcauseInterruptFlag() public returns(uint64) {return 1 << uint64(RiscVConstants.xlen() - 1);}

    function raiseException(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 cause,
        uint64 tval)
    public
    {
        // All traps are handled in machine-mode, by default. Mideleg or Medeleg provide
        // bits to indicate if the interruption/exception should be taken care of by
        // lower privilege levels.
        // Medeleg -> Machine Exception Delegation register
        // Mideleg -> Machine Interrupt Delegation register
        // Reference: riscv-privileged-v1.9.1.pdf - Section 3.1.12, page 28.
        uint64 deleg = 0;
        uint64 priv = mi.readIflagsPrv(mmIndex);

        if (priv <= RiscVConstants.PRV_S()) {
            if ((cause & mcause_interrupt_flag()) != 0) {
                // If exception was caused by an interruption the delegated information is
                // stored on mideleg register.

                // Clear the MCAUSE_INTERRUPT_FLAG() bit before shifting
                deleg = (mi.readMideleg(mmIndex) >> (cause & uint64(RiscVConstants.XLEN() - 1))) & 1;
            } else {
                //If not, information is in the medeleg register
                deleg = (mi.readMedeleg(mmIndex) >> cause) & 1;
            }
        }
        if (deleg != 0) {
            //is in S mode

            // SCAUSE - Supervisor Cause Register
            // Register containg Interrupt bit (shows if the exception was cause by an interrupt
            // and the Exception code, that identifies the last exception
            // The execption codes can be seen at table 4.1
            // Reference: riscv-privileged-v1.9.1.pdf - Section 4.1.8, page 51.
            mi.writeScause(mmIndex, cause);

            // SEPC - Supervisor Exception Program Counter
            // When a trap is taken, sepc is written with the address of the instruction
            // the encountered the exception.
            // Reference: riscv-privileged-v1.9.1.pdf - Section 4.1.7, page 50.
            mi.writeSepc(mmIndex, mi.readPc(mmIndex));

            // STVAL - Supervisor Trap Value
            // stval is written with exception-specific information, when a trap is
            // taken into S-Mode. The specific values can be found in Reference.
            // Reference: riscv-privileged-v1.10.pdf - Section 4.1.11, page 55.
            mi.writeStval(mmIndex, tval);

            // MSTATUS - Machine Status Register
            // keeps track of and controls hart's current operating state.
            // Reference: riscv-privileged-v1.10.pdf - Section 3.1.16, page 19.
            uint64 mstatus = mi.readMstatus(mmIndex);

            // The SPIE bit indicates whether supervisor interrupts were enabled prior
            // to trapping into supervisor mode. When a trap is taken into supervisor
            // mode, SPIE is set to SIE, and SIE is set to 0. When an SRET instruction
            // is executed, SIE is set to SPIE, then SPIE is set to 1.
            // Reference: riscv-privileged-v1.10.pdf - Section 4.1.1, page 19.
            mstatus = (mstatus & ~RiscVConstants.mstatus_spie_mask()) | (((mstatus >> priv) & 1) << RiscVConstants.mstatus_spie_shift());

            // The SPP bit indicates the privilege level at which a hart was executing
            // before entering supervisor mode. When a trap is taken, SPP is set to 0
            // if the trap originated from user mode, or 1 otherwise.
            // Reference: riscv-privileged-v1.10.pdf - Section 4.1.1, page 49.
            mstatus = (mstatus & ~RiscVConstants.mstatus_spp_mask()) | (priv << RiscVConstants.mstatus_spp_shift());

            // The SIE bit enables or disables all interrupts in supervisor mode.
            // When SIE is clear, interrupts are not taken while in supervisor mode.
            // When the hart is running in user-mode, the value in SIE is ignored, and
            // supervisor-level interrupts are enabled. The supervisor can disable
            // indivdual interrupt sources using the sie register.
            // Reference: riscv-privileged-v1.10.pdf - Section 4.1.1, page 50.
            mstatus &= ~RiscVConstants.mstatus_sie_mask();

            mi.writeMstatus(mmIndex, mstatus);

            // TO-DO: Check gas cost to delegate function to library - if its zero the
            // if check should move to setPriv()
            if (priv != RiscVConstants.PRV_S()) {
                mi.setPriv(mmIndex, RiscVConstants.prv_s());
            }
            // SVEC - Supervisor Trap Vector Base Address Register
            mi.writePc(mmIndex, mi.readStvec(mmIndex));
        } else {
            // is in M mode
            mi.writeMcause(mmIndex, cause);
            mi.writeMepc(mmIndex, mi.readPc(mmIndex));
            mi.writeMtval(mmIndex, tval);
            uint64 mstatus = mi.readMstatus(mmIndex);

            mstatus = (mstatus & ~RiscVConstants.mstatus_mpie_mask()) | (((mstatus >> priv) & 1) << RiscVConstants.mstatus_mpie_shift());
            mstatus = (mstatus & ~RiscVConstants.mstatus_mpp_mask()) | (priv << RiscVConstants.mstatus_mpp_shift());

            mstatus &= ~RiscVConstants.mstatus_mie_mask();
            mi.writeMstatus(mmIndex, mstatus);

            // TO-DO: Check gas cost to delegate function to library - if its zero the
            // if check should move to setPriv()
            if (priv != RiscVConstants.prv_m()) {
                mi.setPriv(mmIndex, RiscVConstants.prv_m());
            }
            mi.writePc(mmIndex, mi.readMtvec(mmIndex));
        }
    }
}
