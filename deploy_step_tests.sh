#!/bin/sh

# this script will compile and deploy the contracts using builder
yarn clean
npx buidler deploy --network localhost
