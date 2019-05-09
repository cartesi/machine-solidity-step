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

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

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

contract('Running data.json', function(accounts) {
  let rawdata = fs.readFileSync('new_data.json');
  let jsonsteps = JSON.parse(rawdata);

  describe('Checking functionalities', async function() {
    let mmAddress;
    let miAddress;
    let riscV;
    let mm;
    let mi;

    it('Deploying step contracts', async function() {
      mm = await MMInstantiator.new({
         from: accounts[0], gas: 9007199254740991
      });
      mmAddress = mm.address;

      mi = await MemoryInteractor.new(mmAddress, {
        from: accounts[0], gas: 9007199254740991
      });

      riscV = await Step.new(mi.address, {
        from: accounts[0], gas: 9007199254740991
      });
    });

    it('new MM contract', async function() {
      //jsonsteps.forEach(async function(entry, index) {
        //acount[0] is provider
        //account[1] is client
        response = await mm.instantiate(
          accounts[0], accounts[1], "0x" + jsonsteps[0]["accesses"][0]["proof"]["root_hash"],{
            from: accounts[2],
            gas: 9007199254740991
        });

        response = await mm.instantiate(
          accounts[0], accounts[1], "0x" + jsonsteps[1]["accesses"][1]["proof"]["root_hash"],{
            from: accounts[2],
            gas: 9007199254740991
        });
        //        event = getEvent(response, 'MemoryCreated');
        //        expect(event._index.toNumber()).to.equal(index);
      //});
    });


    it('Writing steps to MM manager', async function() {
      //jsonsteps.forEach(async function(entry, index) {
        jsonsteps[0]["accesses"].forEach(async function(rwentry, rwindex) {
          var siblingArray = rwentry["proof"]["sibling_hashes"];
          var siblingModified = [];
          var i = siblingArray.length - 1;

          while (i > -1) {
            siblingModified.push("0x" + siblingArray[i]);
            i--;
          }

          if (rwentry["type"] == "read") {
            await mm.proveRead(0, rwentry["proof"]["address"], "0x" + rwentry["read"], siblingModified, {from: accounts[1], gas: 9007199254740991});
          } else {
            await mm.proveWrite(0, rwentry["proof"]["address"], "0x" + rwentry["read"], "0x" + rwentry["written"], siblingModified, {from: accounts[1], gas: 9007199254740991});
          }
        });

        jsonsteps[1]["accesses"].forEach(async function(rwentry, rwindex) {
          var siblingArray = rwentry["proof"]["sibling_hashes"];
          var siblingModified = [];
          var i = siblingArray.length - 1;
      
          while (i > -1) {
            siblingModified.push("0x" + siblingArray[i]);
            i--;
          }
      
          if (rwentry["type"] == "read") {
            await mm.proveRead(1, rwentry["proof"]["address"], "0x" + rwentry["read"], siblingModified, {from: accounts[0], gas: 9007199254740991});
          } else {
            await mm.proveWrite(1, rwentry["proof"]["address"], "0x" + rwentry["read"], "0x" + rwentry["written"], siblingModified, {from: accounts[0], gas: 9007199254740991});
          }
        });
      //});
    });

    it('Running step: ', async function() {

      response = await riscV.step(mi.address, 0, {
         from: accounts[0],
         gas: 9007199254740991
      });
      expect(7).to.equal(0);
    });

    it('Running step 2: ', async function() {
      console.log("runnin step 2");
      response = await riscV.step(mi.address, 1, {
         from: accounts[0],
         gas: 9007199254740991
      });
      expect(7).to.equal(0);
    });

    // jsonsteps.forEach(function(entry, index) {
    //   it('Running step: ' + index, async function() {
    //     console.log("running step" + index);
    //     response = await riscV.step(mi.address, index, {
    //        from: accounts[1],
    //        gas: 9007199254740991
    //     });
    //     expect(7).to.equal(0);
    //   });
    // });
  });
});





