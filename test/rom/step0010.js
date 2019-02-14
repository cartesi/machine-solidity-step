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

contract('STEP10', function(accounts){
  describe('Checking functionalities', async function() {
    let mmAddress;
    let miAddress;
    let index;
    let riscV;
    let mm;

    it('Writing to MM manager - Step 10', async function() {
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

      //Step: 10
      //----------------
      //iflags.H
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0xe9e76f9795c7d43a510b2e4ec08657ef443474bf1f93d3e4ea061d0b8299c93d"], {from: accounts[0], gas: 2000000});
      
      //mip
      response = await mm.proveRead(index,368, "0x0000000000000000", ["0xe9e76f9795c7d43a510b2e4ec08657ef443474bf1f93d3e4ea061d0b8299c93d"], {from: accounts[0], gas: 2000000});
      
      //mie
      response = await mm.proveRead(index,360, "0x0000000000000000", ["0xe9e76f9795c7d43a510b2e4ec08657ef443474bf1f93d3e4ea061d0b8299c93d"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveRead(index,256, "0x0000000000001034", ["0xe9e76f9795c7d43a510b2e4ec08657ef443474bf1f93d3e4ea061d0b8299c93d"], {from: accounts[0], gas: 2000000});
      
      //iflags.PRV
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0xe9e76f9795c7d43a510b2e4ec08657ef443474bf1f93d3e4ea061d0b8299c93d"], {from: accounts[0], gas: 2000000});
      
      //mstatus
      response = await mm.proveRead(index,304, "0x0000000a00000000", ["0xe9e76f9795c7d43a510b2e4ec08657ef443474bf1f93d3e4ea061d0b8299c93d"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2048, "0x00000000800000f9", ["0xe9e76f9795c7d43a510b2e4ec08657ef443474bf1f93d3e4ea061d0b8299c93d"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2056, "0x0000000000100000", ["0xe9e76f9795c7d43a510b2e4ec08657ef443474bf1f93d3e4ea061d0b8299c93d"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2064, "0x00000000000010e9", ["0xe9e76f9795c7d43a510b2e4ec08657ef443474bf1f93d3e4ea061d0b8299c93d"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2072, "0x000000000000f000", ["0xe9e76f9795c7d43a510b2e4ec08657ef443474bf1f93d3e4ea061d0b8299c93d"], {from: accounts[0], gas: 2000000});
      
      //memory
      response = await mm.proveRead(index,4144, "0x40007f170011e193", ["0xe9e76f9795c7d43a510b2e4ec08657ef443474bf1f93d3e4ea061d0b8299c93d"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveWrite(index,240,"0x0000000000000000","0x0000000040008034", ["0xe9e76f9795c7d43a510b2e4ec08657ef443474bf1f93d3e4ea061d0b8299c93d"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveWrite(index,256,"0x0000000000001034","0x0000000000001038", ["0x638d794f2cc7259ee0cb37506f2092ffc98a7a86716213d48d5d6a18befb9775"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveRead(index,296, "0x000000000000000a", ["0x8427416e043f243414c3592249c0e7bd4d42e64e5a3d725b457fabdc181878b3"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveWrite(index,296,"0x000000000000000a","0x000000000000000b", ["0x8427416e043f243414c3592249c0e7bd4d42e64e5a3d725b457fabdc181878b3"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveRead(index,288, "0x000000000000000a", ["0x9bcdfbe0acbd77b1b91b0dbd4aaabd42388b837456249f6fedf46731fe05e96d"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveWrite(index,288,"0x000000000000000a","0x000000000000000b", ["0x9bcdfbe0acbd77b1b91b0dbd4aaabd42388b837456249f6fedf46731fe05e96d"], {from: accounts[0], gas: 2000000});
      


   
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

    it('Running step 10', async function() {
      response = await riscV.step(index, mi.address, {
        from: accounts[1],
        gas: 9007199254740991
      });
      expect(4).to.equal(0);
    });
  });
});


