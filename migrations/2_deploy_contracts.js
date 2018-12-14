//Libraries
var RiscVDecoder = artifacts.require("./RiscVDecoder.sol");
var ShadowAddresses = artifacts.require("./ShadowAddresses.sol");
var RiscVConstants = artifacts.require("./RiscVConstants.sol");
var BranchInstructions = artifacts.require("./RiscVInstructions/BranchInstructions.sol");
var ArithmeticInstructions = artifacts.require("./RiscVInstructions/ArithmeticInstructions.sol");

//Contracts
var MMInstantiator = artifacts.require("./MMInstantiator.sol");
var MonolithicRiscV = artifacts.require("./MonolithicRiscV.sol");


module.exports = function(deployer) {
  //Deploy libraries      
  deployer.deploy(ShadowAddresses);
  deployer.deploy(RiscVConstants);
  deployer.deploy(BranchInstructions);
  deployer.deploy(ArithmeticInstructions);
      
  //Link Instruction libraries to Decoder 
  deployer.link(BranchInstructions, RiscVDecoder);
  deployer.link(ArithmeticInstructions, RiscVDecoder);
        
  deployer.deploy(RiscVDecoder);

  //Link all librarie to Monolithic
  deployer.link(RiscVDecoder, MonolithicRiscV);
  deployer.link(ShadowAddresses, MonolithicRiscV);
  deployer.link(RiscVConstants, MonolithicRiscV);
        
  deployer.deploy(MMInstantiator);
  deployer.deploy(MonolithicRiscV);
};
