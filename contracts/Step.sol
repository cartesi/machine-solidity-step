/// @title Step
pragma solidity ^0.5.0;

//Libraries
import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "../contracts/MemoryInteractor.sol";
import {Fetch} from "../contracts/Fetch.sol";
import {Execute} from "../contracts/Execute.sol";
import {Interrupts} from "../contracts/Interrupts.sol";


//TO-DO: use instantiator pattern so we can always use same instance of mm/pc etc
contract Step {
    // event Print(string message, uint value);
    event StepGiven(uint8 exitCode);

    MemoryInteractor mi;

    constructor(address miAddress) public {
        mi = MemoryInteractor(miAddress);
    }

    function step(uint mmIndex) public returns (uint8) {
        // Every read performed by mi.memoryRead or mm . write should be followed by an
        // endianess swap from little endian to big endian. This is the case because
        // EVM is big endian but RiscV is little endian.
        // Reference: riscv-spec-v2.2.pdf - Preface to Version 2.0
        // Reference: Ethereum yellowpaper - Version 69351d5
        //            Appendix H. Virtual Machine Specification

        // Read iflags register and check its H flag, to see if machine is halted.
        // If machine is halted - nothing else to do. H flag is stored on the least
        // signficant bit on iflags register.
        // Reference: The Core of Cartesi, v1.02 - figure 1.
        uint64 iflags = mi.memoryRead(mmIndex, ShadowAddresses.getIflags());
        //emit Print("iflags", uint(iflags));
        if ((iflags & 1) != 0) {
            //machine is halted
            return endStep(mmIndex, 0);
        }
        //Raise the highest priority interrupt
        Interrupts.raiseInterruptIfAny(mmIndex, address(mi));

        //Fetch Instruction
        Fetch.fetchStatus fetchStatus;
        uint64 pc;
        uint32 insn;

        (fetchStatus, insn, pc) = Fetch.fetchInsn(mmIndex, address(mi));

        if (fetchStatus == Fetch.fetchStatus.success) {
            // If fetch was successfull, tries to execute instruction
            if (Execute.executeInsn(
                    mmIndex,
                    address(mi),
                    insn,
                    pc
                ) == Execute.executeStatus.retired
               ) {
                // If executeInsn finishes successfully we need to update the number of
                // retired instructions. This number is stored on minstret CSR.
                // Reference: riscv-priv-spec-1.10.pdf - Table 2.5, page 12.
                uint64 minstret = mi.memoryRead(mmIndex, ShadowAddresses.getMinstret());
                //emit Print("minstret", uint(minstret));
                mi.memoryWrite(mmIndex, ShadowAddresses.getMinstret(), minstret + 1);
            }
        }
        // Last thing that has to be done in a step is to update the cycle counter.
        // The cycle counter is stored on mcycle CSR.
        // Reference: riscv-priv-spec-1.10.pdf - Table 2.5, page 12.
        uint64 mcycle = mi.memoryRead(mmIndex, ShadowAddresses.getMcycle());
        //emit Print("mcycle", uint(mcycle));
        mi.memoryWrite(mmIndex, ShadowAddresses.getMcycle(), mcycle + 1);
        return endStep(mmIndex, 0);
    }

    function getMemoryInteractor() public view returns (address) {
        return address(mi);
    }

    function endStep(uint256 mmIndex, uint8 exitCode) internal returns (uint8) {
        mi.finishReplayPhase(mmIndex);
        emit StepGiven(exitCode);
        return exitCode;
    }

}
