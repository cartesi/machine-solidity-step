#!/bin/bash

set -e

SED=${SED:-"sed"}

for i in test/uarch-log/rv64ui*; do
	BASE=`basename $i .json | $SED "s/-/_/g"`
	cp templates/UArchReplay.t.sol.template test/UArchReplay_$BASE.t.sol
	$SED -i "s/@X@/$BASE/g" test/UArchReplay_$BASE.t.sol
	P=`basename $i`
	$SED -i "s/@PATH@/$P/g" test/UArchReplay_$BASE.t.sol
done
