#!/bin/sh
help()
{
    echo "must pass .bin file path or directory path containing .bin files"
}
kill_geth()
{
    geth_pid=`pgrep geth`
    kill $geth_pid > /dev/null 2>&1
    wait $geth_pid 2>/dev/null
}

if [ $# -ne 1 ]; then
    help
    exit 1
fi

files_to_process=""
count=0
number_of_files=0

if [ -f $1 ]; then
    files_to_process=`/bin/ls -1 $1`
    number_of_files=1
elif [ -d $1 ]; then
    files_to_process=`/bin/ls -1 $1/*.bin`
    number_of_files=`/bin/ls -1 $1/*.bin | wc -l`
else
    help
    exit 1
fi

rm test_ram_result.log
rm geth.log

kill_geth

echo "Starting time: $(date)"

for f in $files_to_process; do
    nohup geth --dev --rpc --rpcapi admin,debug,web3,eth,personal,miner,net,txpool > geth.log 2>&1 &
    cd ../ && ./deploy_ram_tests.sh > /dev/null 2>&1 && cd test/

    count=$((count+1))
    echo "Testing file ${f}(${count}/${number_of_files})"
    python3 test_ram.py $f | tee -a test_ram_result.log
   
    kill_geth
done

echo "Ending time: $(date)"
