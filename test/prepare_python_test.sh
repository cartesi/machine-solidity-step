#!/bin/bash

# this script will compile and migrate the contracts using truffle

# remove build directory to do a clean build
cd ../
rm ./build/ -rf
cd ./test/
sudo truffle compile
sudo truffle migrate --reset
