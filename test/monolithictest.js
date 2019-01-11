const BigNumber = require('bignumber.js');
const expect = require("chai").expect;

const getEvent = require('../utils/tools.js').getEvent;
const unwrap = require('../utils/tools.js').unwrap;
const getError = require('../utils/tools.js').getError;
const twoComplement32 = require('../utils/tools.js').twoComplement32;

var MonolithicRiscV = artifacts.require("./MonolithicRiscV.sol");
var MMInstantiator = artifacts.require("./MMInstantiator.sol");
var MemoryInteractor = artifacts.require("./MemoryInteractor.sol");
var AddressTracker = artifacts.require("./AddressTracker.sol");
var Fetch = artifacts.require("./Fetch.sol");

contract('MonolithicRiscV', function(accounts){
  describe('Checking functionalities', async function() {
    let mmAddress;
    let miAddress;
    let index;

    it('Writing to MM manager', async function() {
      let initialHash = "0x00";
      //acount[0] is provider
      //account[1] is client
      let mm = await MMInstantiator.new({
       from: accounts[0], gas: 2000000
      });
      mmAddress = mm.address;
      response = await mm.instantiate(
      accounts[0], accounts[1], initialHash,{
        from: accounts[2],
        gas: 2000000
      });

      event = getEvent(response, 'MemoryCreated');
      expect(event._index.toNumber()).to.equal(0);
      index = 0;

      //Prove Read to iflags - value 12
      response = await mm.proveRead(index, 0x1d0, "0x0C", [], {
        from: accounts[0],
        gas: 2000000
      });

      //Prove Read to mip - value 0
      response = await mm.proveRead(index, 0x170, "0x0", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Read to mie - value 0 
      response = await mm.proveRead(index, 0x168, "0x0", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Read to pc value 4096
      response = await mm.proveRead(index, 0x100, "0x0010000000000000", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Read to iflags - value 12
      response = await mm.proveRead(index, 0x1d0, "0x0C", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Read to mstatus - value 42949672960
      response = await mm.proveRead(index, 0x130, "0x000000000A000000", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Read to pma@800 - value: 2147483649 
      response = await mm.proveRead(index, 0x800, "0x0100008000000000", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Read to pma@808 - value 1048576
      response = await mm.proveRead(index, 0x808, "0x0000100000000000", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Read to pma@810 - value 4097
      response = await mm.proveRead(index, 0x810, "0x0110000000000000", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Read to pma@818 - value 61440
      response = await mm.proveRead(index, 0x818, "0x00F0000000000000", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Read to memory - value 162836104410563223
      response = await mm.proveRead(index, 0x1000, "0x9702000093824202", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Write to x@28 - first value: 0, second value 4096
      response = await mm.proveWrite(index, 0x28, "0x00", "0x0010000000000000", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Write to pc - first value: 4096, second value 4100
      response = await mm.proveWrite(index, 0x100, "0x1000", "0x0410000000000000", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Read to minstret - value 0
      response = await mm.proveRead(index, 0x128, "0x00", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Write to minstret - first value 0, second value 1
      response = await mm.proveWrite(index, 0x128, "0x00", "0x0100000000000000", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Read to mcycle - value 0
      response = await mm.proveRead(index, 0x120, "0x00", [], {
        from: accounts[0],
        gas: 2000000
      });
      //Prove Write to mcycle - first value 0, second value 1
      response = await mm.proveWrite(index, 0x120, "0x00", "0x0100000000000000", [], {
        from: accounts[0],
        gas: 2000000
      });
    })
    it('Deploying Monolithic contract', async function() {
      let riscV = await MonolithicRiscV.new({
        from: accounts[0], gas: 9007199254740991
      });

      let fetchContract = await Fetch.new({
        from: accounts[0], gas: 9007199254740991
      });

      let addressTracker = await AddressTracker.new({
           from: accounts[0], gas: 9007199254740991
      });

      response = await addressTracker.setFetchAddress(fetchContract.address, {
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

      response = await riscV.step(index, addressTracker.address, {
        from: accounts[1],
        gas: 9007199254740991
      });
      expect(4).to.equal(0);
    });
  });
});


