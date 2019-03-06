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

contract('STEP 2', function(accounts){
  describe('Checking functionalities', async function() {
    let mmAddress;
    let miAddress;
    let index;
    let riscV;
    let mm;

    it('Writing to MM manager - STEP 2', async function() {
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

      //Step: 2
      //----------------
      //iflags.H
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //mip
      response = await mm.proveRead(index,368, "0x0000000000000000", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //mie
      response = await mm.proveRead(index,360, "0x0000000000000000", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveRead(index,256, "0x0000000000001008", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //iflags.PRV
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //mstatus
      response = await mm.proveRead(index,304, "0x0000000a00000000", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2048, "0x00000000800000f9", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2056, "0x0000000000100000", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2064, "0x00000000000010e9", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2072, "0x000000000000f000", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //memory
      response = await mm.proveRead(index,4104, "0x0010051330529073", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveRead(index,40, "0x0000000000001024", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //iflags.PRV
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //mtvec
      response = await mm.proveWrite(index,312,"0x0000000000000000","0x0000000000001024", ["0x504ee57a0a9e815fcfc2f14949cb1605a6259ad8901fb627c1db5de257c5452c"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveWrite(index,256,"0x0000000000001008","0x000000000000100c", ["0x9171ae089cc9881b82179457abebdcb6262b2d452aa098acec3a600e043e1e95"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveRead(index,296, "0x0000000000000002", ["0x2809f5c44c23a1381bf64aacdbb4b46911a4e57de9ec206447c033f60b69d09c"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveWrite(index,296,"0x0000000000000002","0x0000000000000003", ["0x2809f5c44c23a1381bf64aacdbb4b46911a4e57de9ec206447c033f60b69d09c"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveRead(index,288, "0x0000000000000002", ["0x3bd8f7b991f5fafa16505f656b83993db23a605476d86e0fa7ce571dc41fde3d"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveWrite(index,288,"0x0000000000000002","0x0000000000000003", ["0x3bd8f7b991f5fafa16505f656b83993db23a605476d86e0fa7ce571dc41fde3d"], {from: accounts[0], gas: 2000000});
      


   
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

    it('Running step 2', async function() {
      response = await riscV.step(index, mi.address, {
        from: accounts[1],
        gas: 9007199254740991
      });
      expect(4).to.equal(0);
    });
  });
});


