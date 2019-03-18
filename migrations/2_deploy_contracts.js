//Libraries
var RiscVDecoder = artifacts.require("./RiscVDecoder.sol");
var ShadowAddresses = artifacts.require("./ShadowAddresses.sol");
var RiscVConstants = artifacts.require("./RiscVConstants.sol");
var BranchInstructions = artifacts.require("./RiscVInstructions/BranchInstructions.sol");
var RealTimeClock = artifacts.require("./RealTimeClock.sol");
var ArithmeticInstructions = artifacts.require("./RiscVInstructions/ArithmeticInstructions.sol");
var ArithmeticImmediateInstructions = artifacts.require("./RiscVInstructions/ArithmeticImmediateInstructions.sol");
var BitsManipulationLibrary = artifacts.require("./lib/BitsManipulationLibrary.sol");
var S_Instructions = artifacts.require("./RiscVInstructions/S_Instructions.sol");
var EnvTrapInstructions = artifacts.require("./RiscVInstructions/EnvTrapIntInstructions.sol");

var Execute = artifacts.require("./Execute.sol");
var Exceptions = artifacts.require("./Exceptions.sol");
var Fetch = artifacts.require("./Fetch.sol");
var PMA = artifacts.require("./PMA.sol");
var CSR = artifacts.require("./CSR.sol");
var HTIF = artifacts.require("./HTIF.sol");
var CLINT = artifacts.require("./CLINT.sol");
var Interrupts = artifacts.require("./Interrupts.sol");

//Contracts
var AddressTracker = artifacts.require("./AddressTracker.sol");
var MMInstantiator = artifacts.require("./MMInstantiator.sol");
var MemoryInteractor = artifacts.require("./MemoryInteractor.sol");
var VirtualMemory = artifacts.require("./VirtualMemory.sol");
var Step = artifacts.require("./Step.sol");


module.exports = function(deployer) {
  //Deploy libraries
  deployer.deploy(ShadowAddresses);
  deployer.deploy(RiscVConstants);
  deployer.deploy(BitsManipulationLibrary);
  deployer.deploy(RiscVDecoder);
  deployer.deploy(RealTimeClock);

  deployer.link(RiscVDecoder, BranchInstructions);
  deployer.link(RiscVDecoder, ArithmeticInstructions);
  deployer.link(RiscVDecoder, ArithmeticImmediateInstructions);

  deployer.link(RiscVConstants, BranchInstructions);
  deployer.link(RiscVConstants, ArithmeticInstructions);
  deployer.link(RiscVConstants, ArithmeticImmediateInstructions);
  deployer.link(RiscVConstants, EnvTrapInstructions);

  deployer.link(BitsManipulationLibrary, ArithmeticImmediateInstructions);

  deployer.deploy(ArithmeticInstructions);
  deployer.deploy(ArithmeticImmediateInstructions);
  deployer.deploy(BranchInstructions);
  deployer.deploy(PMA);

  //Link all libraries to CLINT
  deployer.link(RealTimeClock, CLINT);
  deployer.link(RiscVConstants, CLINT);
  deployer.deploy(CLINT);

  //Link all libraries to HTIF
  deployer.link(RealTimeClock, HTIF);
  deployer.link(RiscVConstants, HTIF);

  deployer.deploy(HTIF);

  //Link all libraries to CSR
  deployer.link(RealTimeClock, CSR);
  deployer.link(RiscVDecoder, CSR);
  deployer.link(RiscVConstants, CSR);
  deployer.deploy(CSR);

  deployer.deploy(RiscVDecoder);

  //Link all libraries to Exceptions
  deployer.link(RiscVConstants, Exceptions);
  deployer.deploy(Exceptions);

  deployer.link(Exceptions, EnvTrapInstructions);
  deployer.deploy(EnvTrapInstructions);
  //Link libraries to Virtual Memory
  deployer.link(RiscVDecoder, VirtualMemory);
  deployer.link(ShadowAddresses, VirtualMemory);
  deployer.link(RiscVConstants, VirtualMemory);
  deployer.link(PMA, VirtualMemory);
  deployer.link(CLINT, VirtualMemory);
  deployer.link(HTIF, VirtualMemory);
  deployer.link(Exceptions, VirtualMemory);
  deployer.deploy(VirtualMemory);

  //Link all libraries to S_Instructions
  deployer.link(RiscVDecoder, S_Instructions);
  deployer.link(VirtualMemory, S_Instructions);
  deployer.deploy(S_Instructions);

  //Link all libraries to Step
  deployer.link(RiscVDecoder, Step);
  deployer.link(ShadowAddresses, Step);
  deployer.link(RiscVConstants, Step);

  //Link all libraries to Fetch
  deployer.link(RiscVDecoder, Fetch);
  deployer.link(ShadowAddresses, Fetch);
  deployer.link(RiscVConstants, Fetch);
  deployer.link(PMA, Fetch);
  deployer.link(VirtualMemory, Fetch);
  deployer.deploy(Fetch);
  deployer.link(Fetch, Step);

  //Link all libraries to Interrupts
  deployer.link(ShadowAddresses, Interrupts);
  deployer.link(RiscVConstants, Interrupts);
  deployer.deploy(Interrupts);
  deployer.link(Interrupts, Step);

  // Link all libraries to MemoryInteractor
  deployer.link(BitsManipulationLibrary, MemoryInteractor);
  deployer.link(HTIF, MemoryInteractor);
  deployer.link(CLINT, MemoryInteractor);
  deployer.link(ShadowAddresses, MemoryInteractor);

   //Link all libraries to Execute
  deployer.link(RiscVDecoder, Execute);
  deployer.link(ShadowAddresses, Execute);
  deployer.link(RiscVConstants, Execute);
  deployer.link(BranchInstructions, Execute);
  deployer.link(ArithmeticInstructions, Execute);
  deployer.link(ArithmeticImmediateInstructions, Execute);
  deployer.link(EnvTrapInstructions, Execute);
  deployer.link(BitsManipulationLibrary, Execute);
  deployer.link(CSR, Execute);
  deployer.link(Exceptions, Execute);
  deployer.link(S_Instructions, Execute);
  deployer.deploy(Execute);
  deployer.link(Execute, Step);

  deployer.link(BitsManipulationLibrary, MemoryInteractor);
  deployer.link(ShadowAddresses, MemoryInteractor);

  deployer.deploy(AddressTracker);
  deployer.deploy(MMInstantiator).then(function(){
    return deployer.deploy(MemoryInteractor, AddressTracker.address);
  });
  deployer.deploy(Step);
};
