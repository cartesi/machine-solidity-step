#!/bin/bash

set -e

EMULATOR_DIR=${EMULATOR_DIR:-"../emulator"}

TEMPLATE_FILE="./templates/UArchConstants.sol.template"
TARGET_FILE="src/UArchConstants.sol"
KEYWORD_START="START OF AUTO-GENERATED CODE"
KEYWORD_END="END OF AUTO-GENERATED CODE"

# grab head and tail of the template
start=`cat "$TEMPLATE_FILE" | grep "$KEYWORD_START" -n | grep -Eo "[0-9]*"`
end=`cat "$TEMPLATE_FILE" | grep "$KEYWORD_END" -n | grep -Eo "[0-9]*"`
total=`wc -l "$TEMPLATE_FILE" | grep -Eo "[0-9]*"`
let last=total-end+1

h=`head -n $start $TEMPLATE_FILE`
t=`tail -n -$last $TEMPLATE_FILE`

# cd $EMULATOR_DIR
# make build-emulator-image
# cd -

# run the Lua script that instantiates the cartesi module and
# outputs the uarch constants values
constants=$(docker run --rm \
   -v`pwd`:/opt/cartesi/machine-solidity-step  \
   -w /opt/cartesi/machine-solidity-step \
   cartesi/machine-emulator:devel \
   /opt/cartesi/machine-solidity-step/helper_scripts/generate_UArchConstants.lua)

# compose the solidity file from all components
echo -e "$h" "\n\n$constants" > $TARGET_FILE
echo -e "$t" >> $TARGET_FILE

echo "wrote $TARGET_FILE"
