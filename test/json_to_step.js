const BigNumber = require('bignumber.js');
const fs = require('fs');
const expect = require("chai").expect;
const getEvent = require('../utils/tools.js').getEvent;
const unwrap = require('../utils/tools.js').unwrap;
const getError = require('../utils/tools.js').getError;
const twoComplement32 = require('../utils/tools.js').twoComplement32;
var fetch = require("node-fetch");

var Step = artifacts.require("./Step.sol");
var MMInstantiator = artifacts.require("./MMInstantiator.sol");
var MemoryInteractor = artifacts.require("./MemoryInteractor.sol");
var AddressTracker = artifacts.require("./AddressTracker.sol");
var Fetch = artifacts.require("./Fetch.sol");
var Execute = artifacts.require("./Execute.sol");
var Interrupts = artifacts.require("./Interrupts.sol");
var CSR = artifacts.require("./CSR.sol");

contract('CSR', function(accounts) {
  it("get the size of the contract", function() {
    return CSR.deployed().then(function(instance) {
      var bytecode = instance.constructor._json.bytecode;
      var deployed = instance.constructor._json.deployedBytecode;
      var sizeOfB  = bytecode.length / 2;
      var sizeOfD  = deployed.length / 2;
      console.log("size of bytecode in bytes = ", sizeOfB);
      console.log("size of deployed in bytes = ", sizeOfD);
      console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });
  });
});

contract('Execute', function(accounts) {
  it("get the size of the contract", function() {
    return Execute.deployed().then(function(instance) {
      var bytecode = instance.constructor._json.bytecode;
      var deployed = instance.constructor._json.deployedBytecode;
      var sizeOfB  = bytecode.length / 2;
      var sizeOfD  = deployed.length / 2;
      console.log("size of bytecode in bytes = ", sizeOfB);
      console.log("size of deployed in bytes = ", sizeOfD);
      console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });
  });
});

contract('Running data.json', function(accounts) {
  let rawdata = fs.readFileSync('data.json');
  let jsonsteps = JSON.parse(rawdata);

  describe('Checking functionalities', async function() {
    let mmAddress;
    let miAddress;
    let riscV;
    let mm;
    let mi;

    it('new MM contract', async function() {
      mm = await MMInstantiator.new({
         from: accounts[0], gas: 9007199254740991
      });
      mmAddress = mm.address;
    });

    for (i in jsonsteps["steps"]){
      let initialHash = "0x00";
      //acount[0] is provider
      //account[1] is client
      it('Instantiating MM manager ' + i, async function() {
        response = await mm.instantiate(
          accounts[0], accounts[1], initialHash,{
            from: accounts[2],
            gas: 9007199254740991
          });
        event = getEvent(response, 'MemoryCreated');
        expect(event._index.toNumber()).to.equal(i);
      });
    }

    it('Writing steps to MM manager', async function() {
      jsonsteps["steps"].forEach(function(entry, index) {
        entry["readwrites"].forEach(function(rwentry, rwindex) {
          if (rwentry["Access Type"] == "read") {
            mm.proveRead(index, rwentry["Address Access"], rwentry["Value Read"], [rwentry["Access Proof"]], {from: accounts[0], gas: 9007199254740991});
          } else {
            mm.proveWrite(index, rwentry["Address Access"], rwentry["Value Read"], rwentry["Value Written"], [rwentry["Access Proof"]], {from: accounts[0], gas: 9007199254740991});
          }
        });
      });
    });

    it('Deploying step contracts', async function() {
      riscV = await Step.new({
        from: accounts[0], gas: 9007199254740991
      });

      mi = await MemoryInteractor.new(mmAddress, {
        from: accounts[0], gas: 9007199254740991
      });

    });

    jsonsteps["steps"].forEach(function(entry, index) {
      it('Running step: ' + index, async function() {
        response = await riscV.step(mi.address, index, {
           from: accounts[1],
           gas: 9007199254740991
        });
        expect(7).to.equal(0);
      });
    });
  });
});





