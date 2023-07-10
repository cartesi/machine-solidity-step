#!/bin/bash
EMULATOR_DIR=${EMULATOR_DIR:-"../emulator"}
CPP_EXECUTE_PATH=${EMULATOR_DIR}"/src/uarch-execute-insn.h"

TEMPLATE_FILE="./templates/UArchExecuteInsn.sol.template"
TARGET_FILE="src/UArchExecuteInsn.sol"
COMPAT_FILE="src/UArchCompat.sol"
KEYWORD_START="START OF AUTO-GENERATED CODE"
KEYWORD_END="END OF AUTO-GENERATED CODE"

# functions to be markes as internal, otherwise default to private
INTERNAL_FNS="uarchExecuteInsn|readUint32"
# function with unused variable, to silence warning
UNUSED_INSN_FN="executeFENCE"

# grab head and tail of the template
start=`cat "$TEMPLATE_FILE" | grep "$KEYWORD_START" -n | grep -Eo "[0-9]*"`
end=`cat "$TEMPLATE_FILE" | grep "$KEYWORD_END" -n | grep -Eo "[0-9]*"`
total=`wc -l "$TEMPLATE_FILE" | grep -Eo "[0-9]*"`
let last=total-end+1

h=`head -n $start $TEMPLATE_FILE`
t=`tail -n -$last $TEMPLATE_FILE`

# get function names from UArchCompat.sol
COMPAT_FNS=`cat src/UArchCompat.sol | grep -o "function [^(]*(" | sed "s/function//g" | sed "s/(//g"`
COMPAT_FNS=`echo $COMPAT_FNS | sed -E "s/( |\n)/|/g"`

src=`cat "$CPP_EXECUTE_PATH"`
pattern="namespace cartesi \{(.*)\}"
[[ $src =~ $pattern ]]
# replace cpp specific syntaxes with solidity ones
src=`echo "${BASH_REMATCH[1]}" | sed "/template/d" \
                          | sed "/dumpInsn/d" \
                          | sed "/note/d" \
                          | sed "s/constexpr//g" \
                          | sed "s/UarchState &a/AccessLogs.Context memory a/g" \
                          | sed "s/throw std::runtime_error/revert/g" \
                          | sed "s/::/./g" \
                          | sed -E "s/static inline (\w+) ($INTERNAL_FNS)\(([^\n]*)\) \{/function \2\(\3\) internal pure returns \(\1\)\{/g" \
                          | sed -E "s/static inline (\w+) (\w+)\(([^\n]*)\) \{/function \2\(\3\) private pure returns \(\1\)\{/g" \
                          | sed -E "s/([^\n]*) $UNUSED_INSN_FN([^\n]*) uint32 insn,([^\n]*)/\1 $UNUSED_INSN_FN\2 uint32,\3/g" \
                          | sed -E "s/($COMPAT_FNS)/UArchCompat.\1/g" \
                          | sed "s/ returns (void)//g"`

# compose the solidity file from all components
echo "$h" "$src" > $TARGET_FILE
echo -e "\n$t" >> $TARGET_FILE
