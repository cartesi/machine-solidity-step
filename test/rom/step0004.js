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

contract('STEP4', function(accounts){
  describe('Checking functionalities', async function() {
    let mmAddress;
    let miAddress;
    let index;
    let riscV;
    let mm;

    it('Writing to MM manager - STEP 4', async function() {
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

      //Step: 4
      //----------------
      //iflags.H
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //mip
      response = await mm.proveRead(index,368, "0x0000000000000000", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //mie
      response = await mm.proveRead(index,360, "0x0000000000000000", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveRead(index,256, "0x0000000000001010", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //iflags.PRV
      response = await mm.proveRead(index,464, "0x000000000000000c", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //mstatus
      response = await mm.proveRead(index,304, "0x0000000a00000000", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2048, "0x00000000800000f9", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2056, "0x0000000000100000", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //pma.istart
      response = await mm.proveRead(index,2064, "0x00000000000010e9", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //pma.ilength
      response = await mm.proveRead(index,2072, "0x000000000000f000", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //memory
      response = await mm.proveRead(index,4112, "0x0005019300150513", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveRead(index,80, "0x0000000000000001", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //x
      response = await mm.proveWrite(index,80,"0x0000000000000001","0x0000000000000002", ["0x169b14b100f888c2c5b7a2a2181d05bbeaa7a5291758991fd804cdd7a96a5bbb"], {from: accounts[0], gas: 2000000});
      
      //pc
      response = await mm.proveWrite(index,256,"0x0000000000001010","0x0000000000001014", ["0x095daae56a8e46c1ac7ef3452b349802e2a746372270b5a69c2588ff46498bc7"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveRead(index,296, "0x0000000000000004", ["0x6f0666e4ac36c357a86109a5984e5b22937188f0f4163971e6cda5ab0b1b59dc"], {from: accounts[0], gas: 2000000});
      
      //minstret
      response = await mm.proveWrite(index,296,"0x0000000000000004","0x0000000000000005", ["0x6f0666e4ac36c357a86109a5984e5b22937188f0f4163971e6cda5ab0b1b59dc"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveRead(index,288, "0x0000000000000004", ["0x9d11d6fd8db8efd1ac6dbf5850162b87efdaf9c79a294ad3eb487084fc8cd11a"], {from: accounts[0], gas: 2000000});
      
      //mcycle
      response = await mm.proveWrite(index,288,"0x0000000000000004","0x0000000000000005", ["0x9d11d6fd8db8efd1ac6dbf5850162b87efdaf9c79a294ad3eb487084fc8cd11a"], {from: accounts[0], gas: 2000000});
      


   
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

    it('Running step 4', async function() {
      response = await riscV.step(index, mi.address, {
        from: accounts[1],
        gas: 9007199254740991
      });
      expect(4).to.equal(0);
    });
  });
});


