
const contract = require("@truffle/contract");
const BitsManipulationLibrary = contract(require("@cartesi/util/build/contracts/BitsManipulationLibrary.json"));
const MMInstantiator = contract(require("@cartesi/arbitration/build/contracts/MMInstantiator.json"));

const Step = artifacts.require("Step");
const TestRamMMInstantiator = artifacts.require("TestRamMMInstantiator");
const TestRamStep = artifacts.require("TestRamStep");

module.exports = function(deployer) {
  deployer.then(async () => {
    BitsManipulationLibrary.setNetwork(deployer.network_id);
    MMInstantiator.setNetwork(deployer.network_id);

    await deployer.link(BitsManipulationLibrary, TestRamMMInstantiator);
    await deployer.link(MMInstantiator, TestRamMMInstantiator);

    await deployer.deploy(TestRamMMInstantiator);
    await deployer.deploy(TestRamStep, Step.address, TestRamMMInstantiator.address);
  });
};
