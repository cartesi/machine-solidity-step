//const fs   = require('fs');
require('dotenv').config();
const fs = require('fs');

//Libraries
var RiscVDecoder = artifacts.require("./RiscVDecoder.sol");
var ShadowAddresses = artifacts.require("./ShadowAddresses.sol");
var RiscVConstants = artifacts.require("./RiscVConstants.sol");
var BranchInstructions = artifacts.require("./RiscVInstructions/BranchInstructions.sol");
var RealTimeClock = artifacts.require("./RealTimeClock.sol");
var ArithmeticInstructions = artifacts.require("./RiscVInstructions/ArithmeticInstructions.sol");
var ArithmeticImmediateInstructions = artifacts.require("./RiscVInstructions/ArithmeticImmediateInstructions.sol");
var AtomicInstructions = artifacts.require("./RiscVInstructions/AtomicInstructions.sol");
var BitsManipulationLibrary = artifacts.require("./lib/BitsManipulationLibrary.sol");
var S_Instructions = artifacts.require("./RiscVInstructions/S_Instructions.sol");
var EnvTrapInstructions = artifacts.require("./RiscVInstructions/EnvTrapIntInstructions.sol");
var StandAloneInstructions = artifacts.require("./RiscVInstructions/StandAloneInstructions.sol");

var Execute = artifacts.require("./Execute.sol");
var Exceptions = artifacts.require("./Exceptions.sol");
var Fetch = artifacts.require("./Fetch.sol");
var PMA = artifacts.require("./PMA.sol");
var CSR = artifacts.require("./CSR.sol");
var HTIF = artifacts.require("./HTIF.sol");
var CLINT = artifacts.require("./CLINT.sol");
var Interrupts = artifacts.require("./Interrupts.sol");

//Contracts
var MMInstantiator = artifacts.require("./MMInstantiator.sol");
var MemoryInteractor = artifacts.require("./MemoryInteractor.sol");
var VirtualMemory = artifacts.require("./VirtualMemory.sol");
var Step = artifacts.require("./Step.sol");

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

    await deployer.link(RiscVConstants, BranchInstructions);
    await deployer.link(RiscVConstants, ArithmeticInstructions);
    await deployer.link(RiscVConstants, ArithmeticImmediateInstructions);
    await deployer.link(RiscVConstants, StandAloneInstructions);
    await deployer.link(RiscVConstants, EnvTrapInstructions);
    await deployer.link(BitsManipulationLibrary, ArithmeticImmediateInstructions);

    await deployer.deploy(ArithmeticInstructions);
    await deployer.deploy(ArithmeticImmediateInstructions);
    await deployer.deploy(StandAloneInstructions);
    await deployer.deploy(BranchInstructions);
    await deployer.deploy(PMA);

    //Link all libraries to CLINT
    await deployer.link(RealTimeClock, CLINT);
    await deployer.link(RiscVConstants, CLINT);
    await deployer.deploy(CLINT);

    await //Link all libraries to HTIF
    await deployer.link(RealTimeClock, HTIF);
    await deployer.link(RiscVConstants, HTIF);
    await deployer.deploy(HTIF);

    await //Link all libraries to CSR
    await deployer.link(RealTimeClock, CSR);
    await deployer.link(RiscVDecoder, CSR);
    await deployer.link(RiscVConstants, CSR);
    await deployer.deploy(CSR);

    await deployer.deploy(RiscVDecoder);

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
    await deployer.link(CSR, Execute);
    await deployer.link(Exceptions, Execute);
    await deployer.link(S_Instructions, Execute);
    await deployer.link(VirtualMemory, Execute);
    await deployer.deploy(Execute);
    await deployer.link(Execute, Step);

    await deployer.link(BitsManipulationLibrary, MemoryInteractor);
    await deployer.link(ShadowAddresses, MemoryInteractor);

    await deployer.deploy(MMInstantiator)

    if (process.env.CARTESI_INTEGRATION_MM_ADDR) {
      console.log("Deploying MemoryInteractor in integration environment, address: " + process.env.CARTESI_INTEGRATION_MM_ADDR);
      await deployer.deploy(MemoryInteractor, process.env.CARTESI_INTEGRATION_MM_ADDR);
    } else {
      console.log("Deploying MemoryInteractor in test environment, address: " + MMInstantiator.address);
      await deployer.deploy(MemoryInteractor, MMInstantiator.address);
    }
    console.log("MI: " + MemoryInteractor.address);
    //fs.writeFileSync("/tmp/MI.address", MMContract.address);
    await deployer.deploy(Step, MemoryInteractor.address);
    console.log("MM address:" + MMInstantiator.address);
    console.log("Step address:" + Step.address);

    // Write address to file
    let addr_json = "{\"mm_address\":\"" + MMInstantiator.address + "\", \"step_address\":\"" + Step.address + "\"}";

    fs.writeFile('../test/deployedAddresses.json', addr_json, (err) => {
      if (err) console.log("couldnt write to file");
    });
  });
};
