const BigNumber = require('bignumber.js');
const expect = require("chai").expect;

const getEvent = require('../../utils/tools.js').getEvent;
const unwrap = require('../../utils/tools.js').unwrap;
const getError = require('../../utils/tools.js').getError;
const twoComplement32 = require('../../utils/tools.js').twoComplement32;

var Step = artifacts.require("./Step.sol");
var MMInstantiator = artifacts.require("./MMInstantiator.sol");
var MemoryInteractor = artifacts.require("./MemoryInteractor.sol");
var AddressTracker = artifacts.require("./AddressTracker.sol");
var Fetch = artifacts.require("./Fetch.sol");
var Execute = artifacts.require("./Execute.sol");
var Interrupts = artifacts.require("./Interrupts.sol");

contract('Step 7', function(accounts){
  describe('Checking functionalities', async function() {
    let mmAddress;
    let miAddress;
    let index;
    let riscV;
    let mm;

    it('Writing to MM manager - Step 7', async function() {
      let initialHash = "0x00";
      //acount[0] is provider
      //account[1] is client
      mm = await MMInstantiator.new({
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

      //Step: 7
      //----------------
      //iflags.H
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //mip
      response = await mm.proveRead(index,368, "0x0000000000000000", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //mie
      response = await mm.proveRead(index,360, "0x0000000000000000", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveRead(index,256, "0x0000000000001028", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //iflags.PRV
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //mstatus
      response = await mm.proveRead(index,304, "0x0000000a00000000", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2048, "0x00000000800000f9", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2056, "0x0000000000100000", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2064, "0x00000000000010e9", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2072, "0x000000000000f000", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //memory
      response = await mm.proveRead(index,4136, "0x00f1d19301019193", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveRead(index,24, "0x0000000000000002", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveWrite(index,24,"0x0000000000000002","0x0000000000020000", ["0x76f003480ef38e593a51dac6af7fef60fc691140a01deeddf5c6c069dd8f0666"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveWrite(index,256,"0x0000000000001028","0x000000000000102c", ["0x5e3fc32818b4957bb35ff25c92d8dbad75867ad4b28bdf19f8b51211ec0b20d4"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveRead(index,296, "0x0000000000000007", ["0xb309f24074da4ebb2d6a8c45cf2cafac76d32c02be918db1937b729ebc8d08c0"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveWrite(index,296,"0x0000000000000007","0x0000000000000008", ["0xb309f24074da4ebb2d6a8c45cf2cafac76d32c02be918db1937b729ebc8d08c0"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveRead(index,288, "0x0000000000000007", ["0xf811376312c2a51697086dba3ec468c6796b90d49daf307cdb94516fb9d31697"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveWrite(index,288,"0x0000000000000007","0x0000000000000008", ["0xf811376312c2a51697086dba3ec468c6796b90d49daf307cdb94516fb9d31697"], {from: accounts[0], gas: 2000000});
      


   
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

    it('Running step 7', async function() {
      response = await riscV.step(index, mi.address, {
        from: accounts[1],
        gas: 9007199254740991
      });
      expect(4).to.equal(0);
    });
  });
});


