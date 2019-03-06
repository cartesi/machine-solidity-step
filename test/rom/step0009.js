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

contract('STEP9', function(accounts){
  describe('Checking functionalities', async function() {
    let mmAddress;
    let miAddress;
    let index;
    let riscV;
    let mm;

    it('Writing to MM manager - Step 9', async function() {
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

      //Step: 9
      //----------------
      //iflags.H
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //mip
      response = await mm.proveRead(index,368, "0x0000000000000000", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //mie
      response = await mm.proveRead(index,360, "0x0000000000000000", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveRead(index,256, "0x0000000000001030", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //iflags.PRV
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //mstatus
      response = await mm.proveRead(index,304, "0x0000000a00000000", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2048, "0x00000000800000f9", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2056, "0x0000000000100000", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2064, "0x00000000000010e9", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2072, "0x000000000000f000", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //memory
      response = await mm.proveRead(index,4144, "0x40007f170011e193", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveRead(index,24, "0x0000000000000004", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveWrite(index,24,"0x0000000000000004","0x0000000000000005", ["0x8a631d0f18ad4058566e8e8661c7e5d1055976795e731460a75c989aea46d7e5"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveWrite(index,256,"0x0000000000001030","0x0000000000001034", ["0x1d37f3a38995d1cfad7b41ba6dea2e7174139ed3ce54c72add52418252833582"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveRead(index,296, "0x0000000000000009", ["0xe16d9da914d2e5ffd9ccafd09b7dcffbb5865235ca4df211806278c1726a5dd3"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveWrite(index,296,"0x0000000000000009","0x000000000000000a", ["0xe16d9da914d2e5ffd9ccafd09b7dcffbb5865235ca4df211806278c1726a5dd3"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveRead(index,288, "0x0000000000000009", ["0x53213815ebe2045617a084b9ffdff82619b7f6e481aa2982ba3d4d24ff1e834a"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveWrite(index,288,"0x0000000000000009","0x000000000000000a", ["0x53213815ebe2045617a084b9ffdff82619b7f6e481aa2982ba3d4d24ff1e834a"], {from: accounts[0], gas: 2000000});
      


   
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

    it('Running step 9', async function() {
      response = await riscV.step(index, mi.address, {
        from: accounts[1],
        gas: 9007199254740991
      });
      expect(4).to.equal(0);
    });
  });
});


