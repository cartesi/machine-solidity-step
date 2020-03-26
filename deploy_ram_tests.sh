#!/bin/bash

# this script will compile and migrate the contracts using truffle

# remove build directory to do a clean build
rm ./build/ -rf
cd node_modules/@cartesi/util && truffle migrate --network development && cd ../../../
cd node_modules/@cartesi/arbitration && truffle migrate --network development && cd ../../../
export TEST_RAM_DEPLOYMENT=y
truffle migrate --network development
