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

contract('Step 0', function(accounts){
  describe('Checking functionalities', async function() {
    let mmAddress;
    let miAddress;
    let index;
    let riscV;
    let mm;

    it('Writing to MM manager - STEP 0 step', async function() {
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

      //Step: 0
      //----------------
      //iflags.H
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0xcff1f169518b541c2796f5caeb20927d67009f3af9c3f5a3c7d0ac5390a29845"], {from: accounts[0], gas: 2000000});
      
      //mip
      response = await mm.proveRead(index,368, "0x0000000000000000", ["0xcff1f169518b541c2796f5caeb20927d67009f3af9c3f5a3c7d0ac5390a29845"], {from: accounts[0], gas: 2000000});
      
      //mie
      response = await mm.proveRead(index,360, "0x0000000000000000", ["0xcff1f169518b541c2796f5caeb20927d67009f3af9c3f5a3c7d0ac5390a29845"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveRead(index,256, "0x0000000000001000", ["0xcff1f169518b541c2796f5caeb20927d67009f3af9c3f5a3c7d0ac5390a29845"], {from: accounts[0], gas: 2000000});
      
      //iflags.PRV
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0xcff1f169518b541c2796f5caeb20927d67009f3af9c3f5a3c7d0ac5390a29845"], {from: accounts[0], gas: 2000000});
      
      //mstatus
      response = await mm.proveRead(index,304, "0x0000000a00000000", ["0xcff1f169518b541c2796f5caeb20927d67009f3af9c3f5a3c7d0ac5390a29845"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2048, "0x00000000800000f9", ["0xcff1f169518b541c2796f5caeb20927d67009f3af9c3f5a3c7d0ac5390a29845"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2056, "0x0000000000100000", ["0xcff1f169518b541c2796f5caeb20927d67009f3af9c3f5a3c7d0ac5390a29845"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2064, "0x00000000000010e9", ["0xcff1f169518b541c2796f5caeb20927d67009f3af9c3f5a3c7d0ac5390a29845"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2072, "0x000000000000f000", ["0xcff1f169518b541c2796f5caeb20927d67009f3af9c3f5a3c7d0ac5390a29845"], {from: accounts[0], gas: 2000000});
      
      //memory
      response = await mm.proveRead(index,4096, "0x0242829300000297", ["0xcff1f169518b541c2796f5caeb20927d67009f3af9c3f5a3c7d0ac5390a29845"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveWrite(index,40,"0x0000000000000000","0x0000000000001000", ["0xcff1f169518b541c2796f5caeb20927d67009f3af9c3f5a3c7d0ac5390a29845"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveWrite(index,256,"0x0000000000001000","0x0000000000001004", ["0x6be393a6570a3c2321e3175baa7d6b397eca55a8a99a98639af723edc956f18f"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveRead(index,296, "0x0000000000000000", ["0xd06dd5f8e1783e06a4f1140a6235e5c8ff99c043b56495156466c57b944ff892"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveWrite(index,296,"0x0000000000000000","0x0000000000000001", ["0xd06dd5f8e1783e06a4f1140a6235e5c8ff99c043b56495156466c57b944ff892"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveRead(index,288, "0x0000000000000000", ["0x9d9108dcdece700c4e880cb04b0807fb494f70f866bbb26a65ca95e341e9df92"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveWrite(index,288,"0x0000000000000000","0x0000000000000001", ["0x9d9108dcdece700c4e880cb04b0807fb494f70f866bbb26a65ca95e341e9df92"], {from: accounts[0], gas: 2000000});
      


   
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

    it('Running step 0', async function() {
      response = await riscV.step(index, mi.address, {
        from: accounts[1],
        gas: 9007199254740991
      });
      expect(4).to.equal(0);
    });
  });
});


