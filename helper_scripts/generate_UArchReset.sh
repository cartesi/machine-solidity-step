#!/bin/bash
SED=${SED:-"sed"}
EMULATOR_DIR=${EMULATOR_DIR:-"../emulator"}
CPP_RESET_PATH=${EMULATOR_DIR}"/src/uarch-reset-state.cpp"

TEMPLATE_FILE="./templates/UArchReset.sol.template"
TARGET_FILE="src/UArchReset.sol"
COMPAT_FILE="src/UArchCompat.sol"
KEYWORD_START="START OF AUTO-GENERATED CODE"
KEYWORD_END="END OF AUTO-GENERATED CODE"

# get function names from UArchCompat.sol
COMPAT_FNS=`cat $COMPAT_FILE | grep -o "function [^(]*(" | $SED "s/function//g" | $SED "s/(//g"`
COMPAT_FNS=`echo $COMPAT_FNS | $SED -E "s/( |\n)/|/g"`

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
        | $SED -E "s/($COMPAT_FNS)/UArchCompat.\1/g" \
        | $SED "s/void uarch_reset_state(UarchState &a) {/function reset(AccessLogs.Context memory a) internal pure {/"`

# compose the solidity file from all components
echo -e "$h" "\n\n$h_src" > $TARGET_FILE
echo "$cpp_src" >> $TARGET_FILE
echo -e "\n$t" >> $TARGET_FILE
