//Libraries
var RiscVDecoder = artifacts.require("./RiscVDecoder.sol");
var ShadowAddresses = artifacts.require("./ShadowAddresses.sol");
var RiscVConstants = artifacts.require("./RiscVConstants.sol");
var BranchInstructions = artifacts.require("./RiscVInstructions/BranchInstructions.sol");
var ArithmeticInstructions = artifacts.require("./RiscVInstructions/ArithmeticInstructions.sol");
var BitsManipulationLibrary = artifacts.require("./lib/BitsManipulationLibrary.sol");

//Contracts
var AddressTracker = artifacts.require("./AddressTracker.sol");
var MMInstantiator = artifacts.require("./MMInstantiator.sol");
var MemoryInteractor = artifacts.require("./MemoryInteractor.sol");
var MonolithicRiscV = artifacts.require("./MonolithicRiscV.sol");
var Fetch = artifacts.require("./Fetch.sol");
var Interrupts = artifacts.require("./Interrupts.sol");


module.exports = function(deployer) {
  //Deploy libraries
  deployer.deploy(ShadowAddresses);
  deployer.deploy(RiscVConstants);
  deployer.deploy(BranchInstructions);
  deployer.deploy(ArithmeticInstructions);
  deployer.deploy(BitsManipulationLibrary);

  //Link Instruction libraries to Decoder 
  deployer.link(BranchInstructions, RiscVDecoder);
  deployer.link(ArithmeticInstructions, RiscVDecoder);

  deployer.deploy(RiscVDecoder);

  //Link all libraries to Monolithic
  deployer.link(RiscVDecoder, MonolithicRiscV);
  deployer.link(ShadowAddresses, MonolithicRiscV);
  deployer.link(RiscVConstants, MonolithicRiscV);
  deployer.link(BitsManipulationLibrary, MonolithicRiscV);
  
  //Link all libraries to Fetch
  deployer.link(RiscVDecoder, Fetch);
  deployer.link(ShadowAddresses, Fetch);
  deployer.link(RiscVConstants, Fetch);
  deployer.link(BitsManipulationLibrary, Fetch);

  //Link all libraries to Interrupts
  deployer.link(ShadowAddresses, Interrupts);
  deployer.link(RiscVConstants, Interrupts);
  deployer.link(BitsManipulationLibrary, Interrupts);

  deployer.deploy(Fetch);
  deployer.deploy(Interrupts);
  deployer.deploy(AddressTracker);
  deployer.deploy(MMInstantiator).then(function(){
    return deployer.deploy(MemoryInteractor, AddressTracker.address);
  });
  deployer.deploy(MonolithicRiscV);
};
