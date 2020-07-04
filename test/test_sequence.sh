#!/bin/sh

testFilesPath=$1
echo "Starting single threaded tests using $testFilesPath folder"
count=$(ls $testFilesPath/*.br | wc -l)
echo "$count files were found"

files=$(ls -d $testFilesPath/*.br)

for testFile in $files
do
    echo "Executing test for the file $testFile"
    brotli -d -c $testFile | docker run -i --entrypoint ./machine-test cartesi/test sequence --network Istanbul --contracts-config sequence_contracts.json --cin
done
