const BigNumber = require('bignumber.js');
const expect = require("chai").expect;

const getEvent = require('../utils/tools.js').getEvent;
const unwrap = require('../utils/tools.js').unwrap;
const getError = require('../utils/tools.js').getError;
const twoComplement32 = require('../utils/tools.js').twoComplement32;

var MonolithicRiscV = artifacts.require("./MonolithicRiscV.sol");
var MMInstantiator = artifacts.require("./MMInstantiator.sol");

contract('MonolithicRiscV', function(accounts){
  it('Checking functionalities', async function() {
   expect(5).to.equal(5);
  });
});


