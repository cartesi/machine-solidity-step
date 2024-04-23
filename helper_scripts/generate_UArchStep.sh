#!/bin/bash

set -e

SED=${SED:-"sed"}
EMULATOR_DIR=${EMULATOR_DIR:-"../emulator"}
CPP_STEP_PATH=${EMULATOR_DIR}"/src/uarch-step.cpp"
CPP_STEP_H_PATH=${EMULATOR_DIR}"/src/uarch-step.h"

TEMPLATE_FILE="./templates/UArchStep.sol.template"
TARGET_FILE="src/UArchStep.sol"
COMPAT_FILE="src/UArchCompat.sol"
CONSTANTS_FILE="src/UArchConstants.sol"
KEYWORD_START="START OF AUTO-GENERATED CODE"
KEYWORD_END="END OF AUTO-GENERATED CODE"

# function with to be internal
INTERNAL_FN="step"

# grab head and tail of the template
start=`cat "$TEMPLATE_FILE" | grep "$KEYWORD_START" -n | grep -Eo "[0-9]*"`
end=`cat "$TEMPLATE_FILE" | grep "$KEYWORD_END" -n | grep -Eo "[0-9]*"`
total=`wc -l "$TEMPLATE_FILE" | grep -Eo "[0-9]*"`
let last=total-end+1

h=`head -n $start $TEMPLATE_FILE`
t=`tail -n -$last $TEMPLATE_FILE`

h_src=`cat "$CPP_STEP_H_PATH"`
pattern="enum class (.*) : int \{(.*)\};"
[[ $h_src =~ $pattern ]]
# retrieve enum type from cpp header
h_src=`echo "enum ${BASH_REMATCH[1]} {${BASH_REMATCH[2]}}"`

# get function names from UArchCompat.sol
COMPAT_FNS=`cat $COMPAT_FILE | grep -o "function [^(]*(" | $SED "s/function//g" | $SED "s/(//g"`
COMPAT_FNS=`echo $COMPAT_FNS | $SED -E "s/( |\n)/|/g"`

# get constant names from UArchConstants.sol
CONSTANTS=`cat $CONSTANTS_FILE | grep  -E -o 'constant\s+[^ ]*' | $SED -E "s/constant//g; s/ //g" | tr '\n' '|' | sed "s/.$//"`

cpp_src=`cat "$CPP_STEP_PATH"`
pattern="namespace cartesi \{(.*)\}"
[[ $cpp_src =~ $pattern ]]
# replace cpp specific syntaxes with solidity ones
cpp_src=`echo "${BASH_REMATCH[1]}" \
        | $SED "/template/d" \
        | $SED "/note = a.make_scoped_note/d" \
        | $SED "/(void) note/d" \
        | $SED "s/constexpr//g" \
        | $SED "s/UarchState &a/AccessLogs.Context memory a/g" \
        | $SED "s/::/./g" \
        | $SED "s/UINT64_MAX/type(uint64).max/g" \
        | $SED -E "s/UArchStepStatus uarch_step/static inline UArchStepStatus step/g" \
        | $SED -E "s/static inline (\w+) ($INTERNAL_FN)\(([^\n]*)\) \{/function \2\(\3\) internal pure returns \(\1\)\{/g" \
        | $SED -E "s/static inline (\w+) (\w+)\(([^\n]*)\) \{/function \2\(\3\) private pure returns \(\1\)\{/g" \
        | $SED -E "s/($COMPAT_FNS)/UArchCompat.\1/g" \
        | $SED -E "s/([^a-zA-Z])($CONSTANTS)([^a-zA-Z])/UArchConstants.\1\2\3/g" \
        | $SED "s/ returns (void)//g"`

# compose the solidity file from all components
echo -e "$h" "\n\n$h_src" > $TARGET_FILE
echo "$cpp_src" >> $TARGET_FILE
echo -e "\n$t" >> $TARGET_FILE
