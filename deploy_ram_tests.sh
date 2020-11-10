#!/bin/sh

# this script will compile and deploy the contracts using builder
yarn clean
npx hardhat deploy --network ramtest
