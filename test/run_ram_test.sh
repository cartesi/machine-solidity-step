#!/bin/bash

if [ $# -ne 1 ]; then
    echo "must pass .bin file path or directory path containing .bin files"
    exit 1
fi

files_to_process=""

if [ -f $1 ]; then
    files_to_process=`/bin/ls -1 $1`
elif [ -d $1 ]; then
    files_to_process=`/bin/ls -1 $1/*.bin`
else
    echo "must pass .bin file path or directory path containing .bin files"
    exit 1
fi

#ps -ef | grep ganache-cli | grep -v grep | awk '{ print $2 }' | xargs kill > /dev/null 2>&1
pgrep geth | xargs kill > /dev/null 2>&1
rm test_ram_result.log

for f in $files_to_process; do
    # run in quiet mode to increase performance
    #ganache-cli -e 1238192383123 --allowUnlimitedContractSize -l 9007199254740991 > ganache.log 2>&1 &

    nohup /mnt/d/code_playground/geth/geth --dev --rpc --rpcapi admin,debug,web3,eth,personal,miner,net,txpool > geth.log 2>&1 &
    cd ../ && ./deploy_ram_tests.sh > /dev/null 2>&1 && cd test/

    python3 test_ram.py $f | tee -a test_ram_result.log
    
    geth_pid=`pgrep geth`
    kill $geth_pid > /dev/null 2>&1
    wait $geth_pid 2>/dev/null
    
    #ganache_pid=`ps -ef | grep ganache-cli | grep -v grep | awk '{ print $2 }'`
    #kill $ganache_pid > /dev/null 2>&1
    #wait $ganache_pid 2>/dev/null
done

