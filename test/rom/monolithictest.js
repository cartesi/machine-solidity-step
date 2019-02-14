//const BigNumber = require('bignumber.js');
//const expect = require("chai").expect;
//
//const getEvent = require('../../utils/tools.js').getEvent;
//const unwrap = require('../../utils/tools.js').unwrap;
//const getError = require('../../utils/tools.js').getError;
//const twoComplement32 = require('../../utils/tools.js').twoComplement32;
//
//var Step = artifacts.require("./Step.sol");
//var MMInstantiator = artifacts.require("./MMInstantiator.sol");
//var MemoryInteractor = artifacts.require("./MemoryInteractor.sol");
//var AddressTracker = artifacts.require("./AddressTracker.sol");
//var Fetch = artifacts.require("./Fetch.sol");
//var Execute = artifacts.require("./Execute.sol");
//var Interrupts = artifacts.require("./Interrupts.sol");
//
//contract('Step', function(accounts){
//  describe('Checking functionalities', async function() {
//    let mmAddress;
//    let miAddress;
//    let index;
//    let riscV;
//    let mm;
//
//    it('Writing to MM manager - AUIPC step', async function() {
//      let initialHash = "0x00";
//      //acount[0] is provider
//      //account[1] is client
//      mm = await MMInstantiator.new({
//       from: accounts[0], gas: 2000000
//      });
//      mmAddress = mm.address;
//      response = await mm.instantiate(
//      accounts[0], accounts[1], initialHash,{
//        from: accounts[2],
//        gas: 2000000
//      });
//
//      event = getEvent(response, 'MemoryCreated');
//      expect(event._index.toNumber()).to.equal(0);
//      index = 0;
//
//      //Prove Read to iflags - value 12
//      response = await mm.proveRead(index, 464, "0x000000000000000c", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//
//      //Prove Read to mip - value 0
//      response = await mm.proveRead(index, 0x170, "0x0", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to mie - value 0 
//      response = await mm.proveRead(index, 0x168, "0x0", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to pc value 4096
//      response = await mm.proveRead(index, 0x100, "0x0010000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to iflags - value 12
//      response = await mm.proveRead(index, 0x1d0, "0x0C", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to mstatus - value 42949672960
//      response = await mm.proveRead(index, 0x130, "0x000000000A000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to pma@800 - value: 2147483649 
//      response = await mm.proveRead(index, 0x800, "0x0100008000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to pma@808 - value 1048576
//      response = await mm.proveRead(index, 0x808, "0x0000100000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to pma@810 - value 4129 (it was 4097 but I turned on X flag)
//      response = await mm.proveRead(index, 0x810, "0x2110000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to pma@818 - value 61440
//      response = await mm.proveRead(index, 0x818, "0x00F0000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to memory - value 162836104410563223
//      response = await mm.proveRead(index, 0x1000, "0x9702000093824202", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Write to x@28 - first value: 0, second value 4096
//      response = await mm.proveWrite(index, 0x28, "0x00", "0x0010000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Write to pc - first value: 4096, second value 4100
//      response = await mm.proveWrite(index, 0x100, "0x1000", "0x0410000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to minstret - value 0
//      response = await mm.proveRead(index, 0x128, "0x00", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Write to minstret - first value 0, second value 1
//      response = await mm.proveWrite(index, 0x128, "0x00", "0x0100000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to mcycle - value 0
//      response = await mm.proveRead(index, 0x120, "0x00", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Write to mcycle - first value 0, second value 1
//      response = await mm.proveWrite(index, 0x120, "0x00", "0x0100000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//    })
//    it('Deploying step contracts', async function() {
//      riscV = await Step.new({
//        from: accounts[0], gas: 9007199254740991
//      });
//
//      let addressTracker = await AddressTracker.new({
//        from: accounts[0], gas: 9007199254740991
//      });
//
//      response = await addressTracker.setMMAddress(mmAddress, {
//        from: accounts[0], gas: 9007199254740991
//      });
//
//      mi = await MemoryInteractor.new(addressTracker.address, {
//        from: accounts[0], gas: 9007199254740991
//      });
//
//      response = await addressTracker.setMemoryInteractorAddress(mi.address, {
//        from: accounts[0], gas: 9007199254740991
//      });
//    });
//
//    it('Running AUIPC step', async function() {
//      response = await riscV.step(index, mi.address, {
//        from: accounts[1],
//        gas: 9007199254740991
//      });
//      expect(4).to.equal(0);
//    });
//
//    it('Writing to MM manager - ADDI step', async function() {
//      let initialHash = "0x00";
//      //acount[0] is provider
//      //account[1] is client
//     response = await mm.instantiate(
//      accounts[0], accounts[1], initialHash,{
//        from: accounts[2],
//        gas: 2000000
//      });
//
//      event = getEvent(response, 'MemoryCreated');
//      index = event._index.toNumber();
//
//      //Prove Read to iflags - value 12
//      response = await mm.proveRead(index, 0x1d0, "0x0C", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//
//      //Prove Read to mip - value 0
//      response = await mm.proveRead(index, 0x170, "0x0", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to mie - value 0
//      response = await mm.proveRead(index, 0x168, "0x0", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to pc value 4112
//      response = await mm.proveRead(index, 0x100, "0x1010000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to iflags - value 12
//      response = await mm.proveRead(index, 0x1d0, "0x0C", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to mstatus - value 42949672960
//      response = await mm.proveRead(index, 0x130, "0x000000000A000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to pma@800 - value: 2147483649
//      response = await mm.proveRead(index, 0x800, "0x0100008000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to pma@808 - value 1048576
//      response = await mm.proveRead(index, 0x808, "0x0000100000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to pma@810 - value 4097
//      response = await mm.proveRead(index, 0x810, "0x0110000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to pma@818 - value 61440
//      response = await mm.proveRead(index, 0x818, "0x00F0000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to memory - value 1409105756751123
//      response = await mm.proveRead(index, 0x1010, "0x1305150093010500", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to x@50 - value 1
//      response = await mm.proveRead(index, 0x50, "0x0100000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//
//      //Prove Write to x@50 - first value: 1, second value 2
//      response = await mm.proveWrite(index, 0x50, "0x0100000000000000", "0x0100000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Write to pc - first value: 4112, second value 4116
//      response = await mm.proveWrite(index, 0x100, "0x1010000000000000", "0x1410000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to minstret - value 4
//      response = await mm.proveRead(index, 0x128, "0x0400000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Write to minstret - first value 4, second value 5
//      response = await mm.proveWrite(index, 0x128, "0x0400000000000000", "0x0500000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Read to mcycle - value 4
//      response = await mm.proveRead(index, 0x120, "0x0400000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//      //Prove Write to mcycle - first value 4, second value 5
//      response = await mm.proveWrite(index, 0x120, "0x0400000000000000", "0x0500000000000000", [], {
//        from: accounts[0],
//        gas: 2000000
//      });
//    })
//    it('Running ADDI step', async function() {
//      response = await riscV.step(index, mi.address, {
//        from: accounts[1],
//        gas: 9007199254740991
//      });
//      expect(4).to.equal(0);
//    });
//  });
//});
//
//
