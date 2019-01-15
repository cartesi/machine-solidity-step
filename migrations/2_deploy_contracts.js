//Libraries
var RiscVDecoder = artifacts.require("./RiscVDecoder.sol");
var ShadowAddresses = artifacts.require("./ShadowAddresses.sol");
var RiscVConstants = artifacts.require("./RiscVConstants.sol");
var BranchInstructions = artifacts.require("./RiscVInstructions/BranchInstructions.sol");
var ArithmeticInstructions = artifacts.require("./RiscVInstructions/ArithmeticInstructions.sol");
var BitsManipulationLibrary = artifacts.require("./lib/BitsManipulationLibrary.sol");
var Execute = artifacts.require("./Execute.sol");
var Fetch = artifacts.require("./Fetch.sol");
var PMA = artifacts.require("./PMA.sol");
var Interrupts = artifacts.require("./Interrupts.sol");

//Contracts
var AddressTracker = artifacts.require("./AddressTracker.sol");
var MMInstantiator = artifacts.require("./MMInstantiator.sol");
var MemoryInteractor = artifacts.require("./MemoryInteractor.sol");
var Step = artifacts.require("./Step.sol");


module.exports = function(deployer) {
  //Deploy libraries
  deployer.deploy(ShadowAddresses);
  deployer.deploy(RiscVConstants);
  deployer.deploy(BranchInstructions);
  deployer.deploy(ArithmeticInstructions);
  deployer.deploy(BitsManipulationLibrary);


  deployer.link(BitsManipulationLibrary, PMA);
  deployer.deploy(PMA);

  //Link Instruction libraries to Decoder 
  deployer.link(BranchInstructions, RiscVDecoder);
  deployer.link(ArithmeticInstructions, RiscVDecoder);

  deployer.deploy(RiscVDecoder);

  //Link all libraries to Step
  deployer.link(RiscVDecoder, Step);
  deployer.link(ShadowAddresses, Step);
  deployer.link(RiscVConstants, Step);
  deployer.link(BitsManipulationLibrary, Step);

  //Link all libraries to Fetch
  deployer.link(RiscVDecoder, Fetch);
  deployer.link(ShadowAddresses, Fetch);
  deployer.link(RiscVConstants, Fetch);
  deployer.link(BitsManipulationLibrary, Fetch);
  deployer.link(PMA, Fetch);
  deployer.deploy(Fetch);
  deployer.link(Fetch, Step);

  //Link all libraries to Execute
  deployer.link(RiscVDecoder, Execute);
  deployer.link(ShadowAddresses, Execute);
  deployer.link(RiscVConstants, Execute);
  deployer.link(BitsManipulationLibrary, Execute);
  deployer.deploy(Execute);
  deployer.link(Execute, Step);
  
  //Link all libraries to Interrupts
  deployer.link(ShadowAddresses, Interrupts);
  deployer.link(RiscVConstants, Interrupts);
  deployer.link(BitsManipulationLibrary, Interrupts);
  deployer.deploy(Interrupts);
  deployer.link(Interrupts, Step);
  

  deployer.deploy(AddressTracker);
  deployer.deploy(MMInstantiator).then(function(){
    return deployer.deploy(MemoryInteractor, AddressTracker.address);
  });
  deployer.deploy(Step);
};
