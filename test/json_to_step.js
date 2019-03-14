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

contract('Running data.json', function(accounts) {
  let rawdata = fs.readFileSync('data.json');
  let jsonsteps = JSON.parse(rawdata);

  describe('Checking functionalities', async function() {
    let mmAddress;
    let miAddress;
    let riscV;
    let mm;

    it('new MM contract', async function() {
      mm = await MMInstantiator.new({
         from: accounts[0], gas: 2000000
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
            gas: 2000000
          });
        event = getEvent(response, 'MemoryCreated');
        expect(event._index.toNumber()).to.equal(i);
      });
    }

    it('Writing steps to MM manager', async function() {
      jsonsteps["steps"].forEach(function(entry, index) {
        entry["readwrites"].forEach(function(rwentry, rwindex) {
          if (rwentry["Access Type"] == "read") {
            mm.proveRead(index, rwentry["Address Access"], rwentry["Value Read"], [rwentry["Access Proof"]], {from: accounts[0], gas: 2000000});
          } else {
            mm.proveWrite(index, rwentry["Address Access"], rwentry["Value Read"], rwentry["Value Written"], [rwentry["Access Proof"]], {from: accounts[0], gas: 2000000});
          }
        });
      });
    });

    it('Deploying step contracts', async function() {
      riscV = await Step.new({
        from: accounts[0], gas: 9007199254740991
      });

      let addressTracker = await AddressTracker.new({
        from: accounts[0], gas: 9007199254740991
      });

      response = await addressTracker.setMMAddress(mmAddress, {
        from: accounts[0], gas: 9007199254740991
      });

      mi = await MemoryInteractor.new(addressTracker.address, {
        from: accounts[0], gas: 9007199254740991
      });

      response = await addressTracker.setMemoryInteractorAddress(mi.address, {
        from: accounts[0], gas: 9007199254740991
      });
    });

    jsonsteps["steps"].forEach(function(entry, index) {
      it('Running step: ' + index, async function() {
        response = await riscV.step(index, mi.address, {
           from: accounts[1],
           gas: 9007199254740991
        });
        expect(7).to.equal(0);
      });
    });
  });
});





