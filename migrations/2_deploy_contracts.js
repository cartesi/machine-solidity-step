
// Libraries
const RiscVDecoder = artifacts.require("RiscVDecoder");
const ShadowAddresses = artifacts.require("ShadowAddresses");
const RiscVConstants = artifacts.require("RiscVConstants");
const CSRReads = artifacts.require("CSRReads");
const BranchInstructions = artifacts.require("BranchInstructions");
const RealTimeClock = artifacts.require("RealTimeClock");
const ArithmeticInstructions = artifacts.require("ArithmeticInstructions");
const ArithmeticImmediateInstructions = artifacts.require("ArithmeticImmediateInstructions");
const AtomicInstructions = artifacts.require("AtomicInstructions");
const BitsManipulationLibrary = artifacts.require("@cartesi/util/BitsManipulationLibrary");
const S_Instructions = artifacts.require("S_Instructions");
const EnvTrapInstructions = artifacts.require("EnvTrapIntInstructions");
const StandAloneInstructions = artifacts.require("StandAloneInstructions");

const Execute = artifacts.require("Execute");
const Exceptions = artifacts.require("Exceptions");
const Fetch = artifacts.require("Fetch");
const PMA = artifacts.require("PMA");
const CSR = artifacts.require("CSR");
const CSRExecute = artifacts.require("CSRExecute");
const HTIF = artifacts.require("HTIF");
const CLINT = artifacts.require("CLINT");
const Interrupts = artifacts.require("Interrupts");

// Contracts
const MMInstantiator = artifacts.require("@cartesi/arbitration/MMInstantiator");
const MockMMInstantiator = artifacts.require("MockMMInstantiator");
const TestRamMMInstantiator = artifacts.require("TestRamMMInstantiator");
const MemoryInteractor = artifacts.require("MemoryInteractor");
const VirtualMemory = artifacts.require("VirtualMemory");
const Step = artifacts.require("Step");

// Read environment variable to decide if it should instantiate MM or get the address
module.exports = function(deployer) {
  //Deploy libraries
  deployer.then(async () => {
    await deployer.deploy(ShadowAddresses);
    await deployer.deploy(RiscVConstants);

    await deployer.link(BitsManipulationLibrary, RiscVDecoder);
    await deployer.deploy(RiscVDecoder);
    await deployer.deploy(RealTimeClock);

    await deployer.link(RiscVDecoder, BranchInstructions);
    await deployer.link(RiscVDecoder, ArithmeticInstructions);
    await deployer.link(RiscVDecoder, ArithmeticImmediateInstructions);
    await deployer.link(RiscVDecoder, StandAloneInstructions);
    await deployer.link(RiscVDecoder, CSRReads);

    await deployer.link(RiscVConstants, BranchInstructions);
    await deployer.link(RiscVConstants, ArithmeticInstructions);
    await deployer.link(RiscVConstants, ArithmeticImmediateInstructions);
    await deployer.link(RiscVConstants, CSRReads);
    await deployer.link(RiscVConstants, StandAloneInstructions);
    await deployer.link(RiscVConstants, EnvTrapInstructions);
    await deployer.link(BitsManipulationLibrary, ArithmeticImmediateInstructions);

    await deployer.deploy(ArithmeticInstructions);
    await deployer.deploy(ArithmeticImmediateInstructions);
    await deployer.deploy(StandAloneInstructions);
    await deployer.deploy(BranchInstructions);
    await deployer.deploy(PMA);

    await deployer.link(RealTimeClock, CSRReads);
    await deployer.deploy(CSRReads);

    //Link all libraries to CLINT
    await deployer.link(RealTimeClock, CLINT);
    await deployer.link(RiscVConstants, CLINT);
    await deployer.deploy(CLINT);

    //Link all libraries to HTIF
    await deployer.link(RealTimeClock, HTIF);
    await deployer.link(RiscVConstants, HTIF);
    await deployer.deploy(HTIF);

    //Link all libraries to CSR
    await deployer.link(RealTimeClock, CSR);
    await deployer.link(RiscVDecoder, CSR);
    await deployer.link(CSRReads, CSR);
    await deployer.link(RiscVConstants, CSR);
    await deployer.deploy(CSR);

    //Link all libraries to CRSExecute
    await deployer.link(RealTimeClock, CSRExecute);
    await deployer.link(RiscVDecoder, CSRExecute);
    await deployer.link(CSRReads, CSRExecute);
    await deployer.link(RiscVConstants, CSRExecute);
    await deployer.link(CSR, CSRExecute);
    await deployer.deploy(CSRExecute);

    //Link all libraries to Exceptions
    await deployer.link(RiscVConstants, Exceptions);
    await deployer.deploy(Exceptions);

    await deployer.link(Exceptions, EnvTrapInstructions);
    await deployer.deploy(EnvTrapInstructions);

    //Link libraries to Virtual Memory
    await deployer.link(RiscVDecoder, VirtualMemory);
    await deployer.link(ShadowAddresses, VirtualMemory);
    await deployer.link(RiscVConstants, VirtualMemory);
    await deployer.link(PMA, VirtualMemory);
    await deployer.link(CLINT, VirtualMemory);
    await deployer.link(HTIF, VirtualMemory);
    await deployer.link(Exceptions, VirtualMemory);
    await deployer.deploy(VirtualMemory);

    //Link all libraries to S_Instructions
    await deployer.link(RiscVDecoder, S_Instructions);
    await deployer.link(VirtualMemory, S_Instructions);
    await deployer.deploy(S_Instructions);

    //Link all libraries to AtomicInstruction
    await deployer.link(RiscVDecoder, AtomicInstructions);
    await deployer.link(VirtualMemory, AtomicInstructions);
    await deployer.deploy(AtomicInstructions);

    //Link all libraries to Step
    await deployer.link(RiscVDecoder, Step);
    await deployer.link(ShadowAddresses, Step);
    await deployer.link(RiscVConstants, Step);

    //Link all libraries to Fetch
    await deployer.link(RiscVDecoder, Fetch);
    await deployer.link(ShadowAddresses, Fetch);
    await deployer.link(RiscVConstants, Fetch);
    await deployer.link(PMA, Fetch);
    await deployer.link(VirtualMemory, Fetch);
    await deployer.link(Exceptions, Fetch);
    await deployer.deploy(Fetch);
    await deployer.link(Fetch, Step);

    //Link all libraries to Interrupts
    await deployer.link(ShadowAddresses, Interrupts);
    await deployer.link(RiscVConstants, Interrupts);
    await deployer.link(Exceptions, Interrupts);
    await deployer.deploy(Interrupts);
    await deployer.link(Interrupts, Step);

    // Link all libraries to MemoryInteractor
    await deployer.link(BitsManipulationLibrary, MemoryInteractor);
    await deployer.link(HTIF, MemoryInteractor);
    await deployer.link(CLINT, MemoryInteractor);
    await deployer.link(RiscVConstants, MemoryInteractor);
    await deployer.link(ShadowAddresses, MemoryInteractor);

    //Link all libraries to Execute
    await deployer.link(RiscVDecoder, Execute);
    await deployer.link(ShadowAddresses, Execute);
    await deployer.link(RiscVConstants, Execute);
    await deployer.link(BranchInstructions, Execute);
    await deployer.link(ArithmeticInstructions, Execute);
    await deployer.link(ArithmeticImmediateInstructions, Execute);
    await deployer.link(AtomicInstructions, Execute);
    await deployer.link(EnvTrapInstructions, Execute);
    await deployer.link(StandAloneInstructions, Execute);
    await deployer.link(BitsManipulationLibrary, Execute);
    await deployer.link(CSRExecute, Execute);
    await deployer.link(CSR, Execute);
    await deployer.link(Exceptions, Execute);
    await deployer.link(S_Instructions, Execute);
    await deployer.link(VirtualMemory, Execute);
    await deployer.deploy(Execute);
    await deployer.link(Execute, Step);

    await deployer.link(BitsManipulationLibrary, MemoryInteractor);
    await deployer.link(ShadowAddresses, MemoryInteractor);

    // use MockMMInstantiator to run test_single_step.py and test_multi_steps.py
    await deployer.deploy(MockMMInstantiator)
    await deployer.link(BitsManipulationLibrary, TestRamMMInstantiator);
    // use TestRamMMInstantiator to run test_ram.py
    await deployer.deploy(TestRamMMInstantiator)

    // await deployer.deploy(MemoryInteractor, TestRamMMInstantiator.address);
    // await deployer.deploy(MemoryInteractor, MockMMInstantiator.address);
    await deployer.deploy(MemoryInteractor, MMInstantiator.address);
    await deployer.deploy(Step, MemoryInteractor.address);
  });
};
