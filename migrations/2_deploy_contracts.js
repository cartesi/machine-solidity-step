const fs = require('fs');

//Libraries
var RiscVDecoder = artifacts.require("RiscVDecoder");
var ShadowAddresses = artifacts.require("ShadowAddresses");
var RiscVConstants = artifacts.require("RiscVConstants");
var CSRReads = artifacts.require("CSRReads");
var BranchInstructions = artifacts.require("BranchInstructions");
var RealTimeClock = artifacts.require("RealTimeClock");
var ArithmeticInstructions = artifacts.require("ArithmeticInstructions");
var ArithmeticImmediateInstructions = artifacts.require("ArithmeticImmediateInstructions");
var AtomicInstructions = artifacts.require("AtomicInstructions");
var BitsManipulationLibrary = artifacts.require("@cartesi/util/BitsManipulationLibrary");
var S_Instructions = artifacts.require("S_Instructions");
var EnvTrapInstructions = artifacts.require("EnvTrapIntInstructions");
var StandAloneInstructions = artifacts.require("StandAloneInstructions");

var Execute = artifacts.require("Execute");
var Exceptions = artifacts.require("Exceptions");
var Fetch = artifacts.require("Fetch");
var PMA = artifacts.require("PMA");
var CSR = artifacts.require("CSR");
var CSRExecute = artifacts.require("CSRExecute");
var HTIF = artifacts.require("HTIF");
var CLINT = artifacts.require("CLINT");
var Interrupts = artifacts.require("Interrupts");

//Contracts
var MMInstantiator = artifacts.require("@cartesi/arbitration/MMInstantiator");
var MockMMInstantiator = artifacts.require("MockMMInstantiator");
var TestRamMMInstantiator = artifacts.require("TestRamMMInstantiator");
var MemoryInteractor = artifacts.require("MemoryInteractor");
var VirtualMemory = artifacts.require("VirtualMemory");
var Step = artifacts.require("Step");

// Read environment variable to decide if it should instantiate MM or get the address
module.exports = function(deployer) {
  //Deploy libraries
  deployer.then(async () => {
    await deployer.deploy(ShadowAddresses);
    await deployer.deploy(RiscVConstants);
    await deployer.deploy(BitsManipulationLibrary);

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

    await deployer.deploy(MMInstantiator)
    // use MockMMInstantiator to run test_single_step.py and test_multi_steps.py
    await deployer.deploy(MockMMInstantiator)

    await deployer.link(BitsManipulationLibrary, TestRamMMInstantiator);
    // use TestRamMMInstantiator to run test_ram.py
    await deployer.deploy(TestRamMMInstantiator)

    let mmAddress;
    if (process.env.CARTESI_INTEGRATION_MM_ADDR) {
      mmAddress = process.env.CARTESI_INTEGRATION_MM_ADDR
      console.log("Deploying MemoryInteractor in integration environment, address: " + mmAddress);
    } else if (false) {
      mmAddress = TestRamMMInstantiator.address
      console.log("Deploying MemoryInteractor in test environment, with Test Ram MM address: " + mmAddress);
    } else {
      mmAddress = MockMMInstantiator.address
      console.log("Deploying MemoryInteractor in test environment, with Mock MM address: " + mmAddress);
    }
    await deployer.deploy(MemoryInteractor, mmAddress);
    await deployer.deploy(Step, MemoryInteractor.address);

    // Write address to file
    let addr_json = "{\"mm_address\":\"" + mmAddress + "\", \"step_address\":\"" + Step.address + "\"}";

    fs.writeFile('../test/deployedAddresses.json', addr_json, (err) => {
      if (err) console.log("couldnt write to file");
    });

    if (process.env.STEP_ADD_FILE_PATH) {
        fs.writeFileSync(process.env.STEP_ADD_FILE_PATH, Step.address);
    }
  });
};
