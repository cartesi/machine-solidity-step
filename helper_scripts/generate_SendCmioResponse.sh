#!/bin/bash

set -e

SED=${SED:-"sed"}
EMULATOR_DIR=${EMULATOR_DIR:-"../emulator"}
CPP_RESET_PATH=${EMULATOR_DIR}"/src/send-cmio-response.cpp"

TEMPLATE_FILE="./templates/SendCmioResponse.sol.template"
TARGET_FILE="src/SendCmioResponse.sol"
COMPAT_FILE="src/EmulatorCompat.sol"
CONSTANTS_FILE="src/EmulatorConstants.sol"
KEYWORD_START="START OF AUTO-GENERATED CODE"
KEYWORD_END="END OF AUTO-GENERATED CODE"

# get function names from EmulatorCompat.sol
COMPAT_FNS=`cat $COMPAT_FILE | grep -o "function [^(]*(" | $SED "s/function//g" | $SED "s/(//g"`
COMPAT_FNS=`echo $COMPAT_FNS | $SED -E "s/( |\n)/|/g"`

# get constant names from EmulatorConstants.sol
CONSTANTS=`cat $CONSTANTS_FILE | grep  -E -o 'constant\s+[^ ]*' | $SED -E "s/constant//g; s/ //g" | tr '\n' '|' | sed "s/.$//"`

# grab head and tail of the template
start=`cat "$TEMPLATE_FILE" | grep "$KEYWORD_START" -n | grep -Eo "[0-9]*"`
end=`cat "$TEMPLATE_FILE" | grep "$KEYWORD_END" -n | grep -Eo "[0-9]*"`
total=`wc -l "$TEMPLATE_FILE" | grep -Eo "[0-9]*"`
let last=total-end+1

h=`head -n $start $TEMPLATE_FILE`
t=`tail -n -$last $TEMPLATE_FILE`

cpp_src=`cat "$CPP_RESET_PATH"`
pattern="namespace cartesi \{(.*)\}"
[[ $cpp_src =~ $pattern ]]

# replace cpp specific syntaxes with solidity ones
cpp_src=`echo "${BASH_REMATCH[1]}" \
        | $SED "/Explicit instantiatio/d" \
        | $SED "/template/d" \
        | $SED "/    uint32 length);/d" \
        | $SED "s/machine_merkle_tree::get_log2_word_size()/TREE_LOG2_WORD_SIZE/g" \
        | $SED -E "s/($COMPAT_FNS)/EmulatorCompat.\1/g" \
        | $SED "s/writeMemoryWithPadding(a, PMA_CMIO_RX_BUFFER_START, data, dataLength, writeLengthLog2Size);/a.writeRegion(Memory.regionFromPhysicalAddress(PMA_CMIO_RX_BUFFER_START.toPhysicalAddress(),Memory.alignedSizeFromLog2(uint8(writeLengthLog2Size - TREE_LOG2_WORD_SIZE))),dataHash);"/g \
        | $SED -E "s/($CONSTANTS)([^a-zA-Z])/EmulatorConstants.\1\2/g" \
        | $SED "s/void send_cmio_response(STATE_ACCESS a, uint16 reason, bytes data, uint32 dataLength) {/function sendCmioResponse(AccessLogs.Context memory a, uint16 reason, bytes32 dataHash, uint32 dataLength) internal pure {/" \
        | $SED "s/const uint64/uint64/g" \
        | $SED "s/const uint32/uint32/g" \
        | $SED "/^$/N;/^\n$/D"
        `

# compose the solidity file from all components
echo -e "$h" "\n\n$h_src" > $TARGET_FILE
echo "$cpp_src" >> $TARGET_FILE
echo -e "\n$t" >> $TARGET_FILE
