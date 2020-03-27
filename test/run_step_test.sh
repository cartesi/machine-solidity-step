#!/bin/bash
help()
{
    echo "must pass .json file path or directory path containing .json files"
}
kill_ganache()
{
    ganache_pid=`ps -ef | grep ganache-cli | grep -v grep | awk '{ print $2 }'`
    kill $ganache_pid > /dev/null 2>&1
    wait $ganache_pid 2>/dev/null
}

if [ $# -ne 1 ]; then
    help
    exit 1
fi

files_to_process=""
number_of_files=0
count=0

if [ -f $1 ]; then
    files_to_process=`/bin/ls -1 $1`
    number_of_files=1
elif [ -d $1 ]; then
    files_to_process=`/bin/ls -1 $1/*.json`
    number_of_files=`/bin/ls -1 $1/*.json | wc -l`
else
    help
    exit 1
fi

rm test_step_result.log
rm ganache.log

kill_ganache

echo "Starting time: $(date)"
    
# run in quiet mode to increase performance
ganache-cli > ganache.log 2>&1 &
cd ../ && ./deploy_step_tests.sh > /dev/null 2>&1 && cd test/

for f in $files_to_process; do
    ((count+=1))
    echo "Testing file ${f}(${count}/${number_of_files})"
    python3 -u test_step.py $f | tee -a test_step_result.log
done

kill_ganache
