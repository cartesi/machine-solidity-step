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

contract('STEP 0001', function(accounts){
  describe('Checking functionalities', async function() {
    let mmAddress;
    let miAddress;
    let index;
    let riscV;
    let mm;

    it('Writing to MM manager - STEP 0001', async function() {
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
      //Step: 1
      //----------------
      //iflags.H
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});

      //mip
      response = await mm.proveRead(index,368, "0x0000000000000000", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});

      //mie
      response = await mm.proveRead(index,360, "0x0000000000000000", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});

      //pc
      response = await mm.proveRead(index,256, "0x0000000000001004", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});

      //iflags.PRV
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});

      //mstatus
      response = await mm.proveRead(index,304, "0x0000000a00000000", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});

      //pma.istart
      response = await mm.proveRead(index,2048, "0x00000000800000f9", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});

      //pma.ilength
      response = await mm.proveRead(index,2056, "0x0000000000100000", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});

      //pma.istart
      response = await mm.proveRead(index,2064, "0x00000000000010e9", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2072, "0x000000000000f000", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});
      
      //memory
      response = await mm.proveRead(index, 4096, "0x0242829300000297", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveRead(index,40, "0x0000000000001000", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveWrite(index,40,"0x0000000000001000","0x0000000000001024", ["0xf11e1faa8c7422e5487bcb6ccc997f72a8f33d6c486f1964e0527e2c3a8b1dce"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveWrite(index,256,"0x0000000000001004","0x0000000000001008", ["0x0b6a39125eca8f7fbfcce376a1322b37c6c0830e06984a7dcf5c6877218e13b3"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveRead(index,296, "0x0000000000000001", ["0x8ca0fc02e5a1df85ac24f19f17ac3d70aad37b01367a9e839c85952f3efe9d43"], {from: accounts[0], gas: 2000000});

      //minstret
      response = await mm.proveWrite(index,296,"0x0000000000000001","0x0000000000000002", ["0x8ca0fc02e5a1df85ac24f19f17ac3d70aad37b01367a9e839c85952f3efe9d43"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveRead(index,288, "0x0000000000000001", ["0xe1c17d45361129d659d8b35284887116dbdb508488f0220dadf0c42fb9c0e687"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveWrite(index,288,"0x0000000000000001","0x0000000000000002", ["0xe1c17d45361129d659d8b35284887116dbdb508488f0220dadf0c42fb9c0e687"], {from: accounts[0], gas: 2000000});
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

    it('Running step 1', async function() {
      response = await riscV.step(index, mi.address, {
        from: accounts[1],
        gas: 9007199254740991
      });
      expect(4).to.equal(0);
    });
  });
});


