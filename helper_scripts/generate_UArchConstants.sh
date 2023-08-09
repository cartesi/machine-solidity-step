#!/bin/bash
EMULATOR_DIR=${EMULATOR_DIR:-"../emulator"}

TEMPLATE_FILE="./templates/UArchConstants.sol.template"
TARGET_FILE="src/UArchConstants.sol"
KEYWORD_START="START OF AUTO-GENERATED CODE"
KEYWORD_END="END OF AUTO-GENERATED CODE"

MACHINE_CMD_TEMPLATE="docker run -w /opt/cartesi/lib/lua/5.4 \
                        -it cartesi/machine-emulator:devel lua \
                        -e 'print(string.format(\"%x\", require(\"cartesi\").machine.%API(\"%ARG\")))'"
CONSTANTS_ARR=( "UCYCLE;get_csr_address;uarch_cycle" \
                "UHALT;get_csr_address;uarch_halt_flag" \
                "UPC;get_csr_address;uarch_pc" \
                "UX0;get_uarch_x_address;0")

# grab head and tail of the template
start=`cat "$TEMPLATE_FILE" | grep "$KEYWORD_START" -n | grep -Eo "[0-9]*"`
end=`cat "$TEMPLATE_FILE" | grep "$KEYWORD_END" -n | grep -Eo "[0-9]*"`
total=`wc -l "$TEMPLATE_FILE" | grep -Eo "[0-9]*"`
let last=total-end+1

h=`head -n $start $TEMPLATE_FILE`
t=`tail -n -$last $TEMPLATE_FILE`

cd $EMULATOR_DIR
make build-debian-image

constants=""
for c in ${CONSTANTS_ARR[@]}; do
        read var api arg <<<$(IFS=";"; echo $c)
        machine_cmd=`echo $MACHINE_CMD_TEMPLATE | sed s#%API#$api#g | sed s#%ARG#$arg#g`
        addr=`eval $machine_cmd | tr -d "\r"`
        constants="$constants uint64 constant $var = 0x$addr;\n"
done

cd - > /dev/null

# compose the solidity file from all components
echo -e "$h" "\n\n$constants" > $TARGET_FILE
echo -e "$t" >> $TARGET_FILE
