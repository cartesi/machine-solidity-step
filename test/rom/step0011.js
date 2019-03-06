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

contract('STEP0011', function(accounts){
  describe('Checking functionalities', async function() {
    let mmAddress;
    let miAddress;
    let index;
    let riscV;
    let mm;

    it('Writing to MM manager - Step 11', async function() {
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

      //Step: 11
      //----------------
      //iflags.H
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //mip
      response = await mm.proveRead(index,368, "0x0000000000000000", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //mie
      response = await mm.proveRead(index,360, "0x0000000000000000", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveRead(index,256, "0x0000000000001038", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //iflags.PRV
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //mstatus
      response = await mm.proveRead(index,304, "0x0000000a00000000", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2048, "0x00000000800000f9", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2056, "0x0000000000100000", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2064, "0x00000000000010e9", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2072, "0x000000000000f000", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //memory
      response = await mm.proveRead(index,4152, "0xff9ff06ffc3f3623", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveRead(index,240, "0x0000000040008034", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveRead(index,24, "0x0000000000000005", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //iflags.PRV
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //mstatus
      response = await mm.proveRead(index,304, "0x0000000a00000000", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2048, "0x00000000800000f9", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2056, "0x0000000000100000", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2064, "0x00000000000010e9", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2072, "0x000000000000f000", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2080, "0x000000004000831a", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2088, "0x0000000000001000", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //htif.tohost
      response = await mm.proveWrite(index,1073774592,"0x0000000000000000","0x0000000000000005", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //iflags
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x4e34100984b02109927279c368ba3bd6ec10955aba142f16822785ee637625dd"], {from: accounts[0], gas: 2000000});
      
      //iflags.H
      response = await mm.proveWrite(index,464,"0x000000000000000c","0x000000000000000d", ["0xae3d92a0b0a266593ee8059e27d830a00ce14c2ca28f7b2af8f3839d756f856a"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveWrite(index,256,"0x0000000000001038","0x000000000000103c", ["0x787a061ad04a18ac6533e5682de51c221fff42a10420cea15f84d4b4d2b147d9"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveRead(index,296, "0x000000000000000b", ["0x1afe84f8cad75345324c3fe68f668a0bdb7086a61d289201dccad4c9509e6a5f"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveWrite(index,296,"0x000000000000000b","0x000000000000000c", ["0x1afe84f8cad75345324c3fe68f668a0bdb7086a61d289201dccad4c9509e6a5f"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveRead(index,288, "0x000000000000000b", ["0xf1d7dfb7ae5c2c24c8593ff3c6f1f4bf14f2edaec78e21f42badae927f5ab11d"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveWrite(index,288,"0x000000000000000b","0x000000000000000c", ["0xf1d7dfb7ae5c2c24c8593ff3c6f1f4bf14f2edaec78e21f42badae927f5ab11d"], {from: accounts[0], gas: 2000000});
      

   
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

    it('Running step 11', async function() {
      response = await riscV.step(index, mi.address, {
        from: accounts[1],
        gas: 9007199254740991
      });
      expect(4).to.equal(0);
    });
  });
});


