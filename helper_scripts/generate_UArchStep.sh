#!/bin/bash

set -e

SED=${SED:-"sed"}
EMULATOR_DIR=${EMULATOR_DIR:-"../emulator"}
CPP_STEP_PATH=${EMULATOR_DIR}"/src/uarch-step.cpp"
CPP_STEP_H_PATH=${EMULATOR_DIR}"/src/uarch-step.h"

TEMPLATE_FILE="./templates/UArchStep.sol.template"
TARGET_FILE="src/UArchStep.sol"
COMPAT_FILE="src/UArchCompat.sol"
KEYWORD_START="START OF AUTO-GENERATED CODE"
KEYWORD_END="END OF AUTO-GENERATED CODE"

# function with to be internal
INTERNAL_FN="step"
# function with unused variable, to silence warning
UNUSED_INSN_FN="executeFENCE"

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

cpp_src=`cat "$CPP_STEP_PATH"`
pattern="namespace cartesi \{(.*)\}"
[[ $cpp_src =~ $pattern ]]
# replace cpp specific syntaxes with solidity ones
cpp_src=`echo "${BASH_REMATCH[1]}" \
        | $SED "/template/d" \
        | $SED "/dumpInsn/d" \
        | $SED "/note/d" \
        | $SED "s/constexpr//g" \
        | $SED "s/UarchState &a/AccessLogs.Context memory a/g" \
        | $SED "s/throw std::runtime_error/revert/g" \
        | $SED "s/::/./g" \
        | $SED "s/UINT64_MAX/type(uint64).max/g" \
        | $SED -E "s/UArchStepStatus uarch_step/static inline UArchStepStatus step/g" \
        | $SED -E "s/static inline (\w+) ($INTERNAL_FN)\(([^\n]*)\) \{/function \2\(\3\) internal pure returns \(\1\)\{/g" \
        | $SED -E "s/static inline (\w+) (\w+)\(([^\n]*)\) \{/function \2\(\3\) private pure returns \(\1\)\{/g" \
        | $SED -E "s/([^\n]*) $UNUSED_INSN_FN([^\n]*) uint32 insn,([^\n]*)/\1 $UNUSED_INSN_FN\2 uint32,\3/g" \
        | $SED -E "s/($COMPAT_FNS)/UArchCompat.\1/g" \
        | $SED "s/ returns (void)//g"`

# compose the solidity file from all components
echo -e "$h" "\n\n$h_src" > $TARGET_FILE
echo "$cpp_src" >> $TARGET_FILE
echo -e "\n$t" >> $TARGET_FILE
