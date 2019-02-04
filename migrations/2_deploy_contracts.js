//Libraries
var RiscVDecoder = artifacts.require("./RiscVDecoder.sol");
var ShadowAddresses = artifacts.require("./ShadowAddresses.sol");
var RiscVConstants = artifacts.require("./RiscVConstants.sol");
var BranchInstructions = artifacts.require("./RiscVInstructions/BranchInstructions.sol");
var ArithmeticInstructions = artifacts.require("./RiscVInstructions/ArithmeticInstructions.sol");
var ArithmeticImmediateInstructions = artifacts.require("./RiscVInstructions/ArithmeticImmediateInstructions.sol");
var BitsManipulationLibrary = artifacts.require("./lib/BitsManipulationLibrary.sol");
var Execute = artifacts.require("./Execute.sol");
var Exceptions = artifacts.require("./Exceptions.sol");
var Fetch = artifacts.require("./Fetch.sol");
var PMA = artifacts.require("./PMA.sol");
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

  deployer.link(RiscVDecoder, BranchInstructions);
  deployer.link(RiscVDecoder, ArithmeticInstructions);
  deployer.link(RiscVDecoder, ArithmeticImmediateInstructions);

  deployer.link(RiscVConstants, BranchInstructions);
  deployer.link(RiscVConstants, ArithmeticInstructions);
  deployer.link(RiscVConstants, ArithmeticImmediateInstructions);

  deployer.deploy(ArithmeticInstructions);
  deployer.deploy(ArithmeticImmediateInstructions);
  deployer.deploy(BranchInstructions);
  deployer.deploy(PMA);

  //Link Instruction libraries to Decoder
  deployer.link(BranchInstructions, RiscVDecoder);
  deployer.link(ArithmeticInstructions, RiscVDecoder);

  deployer.deploy(RiscVDecoder);

  //Link libraries to Virtual Memory
  deployer.link(RiscVDecoder, VirtualMemory);
  deployer.link(ShadowAddresses, VirtualMemory);
  deployer.link(RiscVConstants, VirtualMemory);
  deployer.link(PMA, VirtualMemory);
  deployer.deploy(VirtualMemory);

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
  deployer.link(ShadowAddresses, MemoryInteractor);

  //Link all libraries to Exceptions
  deployer.link(RiscVConstants, Exceptions);
  deployer.deploy(Exceptions);

   //Link all libraries to Execute
  deployer.link(RiscVDecoder, Execute);
  deployer.link(ShadowAddresses, Execute);
  deployer.link(RiscVConstants, Execute);
  deployer.link(BranchInstructions, Execute);
  deployer.link(ArithmeticInstructions, Execute);
  deployer.link(ArithmeticImmediateInstructions, Execute);
  deployer.link(Exceptions, Execute);
  deployer.deploy(Execute);
  deployer.link(Execute, Step);

  deployer.deploy(AddressTracker);
  deployer.deploy(MMInstantiator).then(function(){
    return deployer.deploy(MemoryInteractor, AddressTracker.address);
  });
  deployer.deploy(Step);
};
