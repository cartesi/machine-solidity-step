const BigNumber = require('bignumber.js');
const expect = require("chai").expect;

const getEvent = require('../utils/tools.js').getEvent;
const unwrap = require('../utils/tools.js').unwrap;
const getError = require('../utils/tools.js').getError;
const twoComplement32 = require('../utils/tools.js').twoComplement32;

var MonolithicRiscV = artifacts.require("./MonolithicRiscV.sol");
var MMInstantiator = artifacts.require("./MMInstantiator.sol");

contract('MonolithicRiscV', function(accounts){
  describe('Checking functionalities', async function() {
    let mmAddress;
    let index;

    it('Writing to MM manager', async function() {
      let initialHash = 0;
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

      //Write to iflags
      response = await mm.proveRead(index, 0x1d0, 12, [], {
        from: accounts[0],
        gas: 2000000
      });

      //Write to mip
      response = await mm.proveRead(index, 0x170, 0, [], {
        from: accounts[0],
        gas: 2000000
      });
      //Write to mie
      response = await mm.proveRead(index, 0x168, 0, [], {
        from: accounts[0],
        gas: 2000000
      });
      //Write to pc
      response = await mm.proveRead(index, 0x100, 4096, [], {
        from: accounts[0],
        gas: 2000000
      });
      //Write to mstatus
      response = await mm.proveRead(index, 0x130, 42949672960, [], {
        from: accounts[0],
        gas: 2000000
      });
      //Write to pma@800
      response = await mm.proveRead(index, 0x800, 2147483649, [], {
        from: accounts[0],
        gas: 2000000
      });
      //Write to pma@808
      response = await mm.proveRead(index, 0x808, 1048576, [], {
        from: accounts[0],
        gas: 2000000
      });
      //Write to pma@810
      response = await mm.proveRead(index, 0x810, 4097, [], {
        from: accounts[0],
        gas: 2000000
      });
      //Write to pma@818
      response = await mm.proveRead(index, 0x818, 61440, [], {
        from: accounts[0],
        gas: 2000000
      });
      //Write to memory
      response = await mm.proveRead(index, 0x1000, 162836104410563223, [], {
        from: accounts[0],
        gas: 2000000
      });
    })
    it('Deploying Monolithic contract', async function() {
      let riscV = await MonolithicRiscV.new({
        from: accounts[0], gas: 4600000
      });
      response = await riscV.step(index, mmAddress, {
        from: accounts[1],
        gas: 4600000
      });
      expect(4).to.equal(0);
    });
  });
});


