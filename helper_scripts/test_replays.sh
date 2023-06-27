#!/bin/bash
for i in test/uarch-log/rv64ui*; do
	BASE=`basename $i .json | sed "s/-/_/g"`
	cp templates/UArchReplay.t.sol.template test/UArchReplay_$BASE.t.sol
	sed -i "s/@X@/$BASE/g" test/UArchReplay_$BASE.t.sol
	P=`basename $i`
	sed -i "s/@PATH@/$P/g" test/UArchReplay_$BASE.t.sol
done

for i in test/uarch-log/rv64ui*; do
	BASE=`basename $i .json | sed "s/-/_/g"`
	forge test -vvv --match-contract UArchReplay_${BASE}_Test
	if [ $? != 0 ]; then
		exit 1
	fi
done
