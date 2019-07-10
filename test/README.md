# RiscV-Solidity Tests

There are three folders containing different types of tests  
1. Single Step - this will replay a single step from a file specified with the test script, revert is throwed if any failure.
2. Multiple Steps - this will replay multiple steps from a file specified with the test script, revert is throwed if any failure.
3. Ram Test - this will load a simple test program into the ram region, looping the steps until the machine halts, non-zero exit code will be returned if any failure.

## Prepare the Testing Environment ##

install ganache-cli with npm  
```shell
$ sudo npm install -g ganache-cli
```
install python 3.7 and pip  
```shell
$ sudo apt-get update
$ sudo apt-get install python3.7
$ sudo python3.7 -m pip install pip
```
install web3, py-solc-x with pip  
```shell
$ sudo python3.7 -m pip install web3
$ sudo python3.7 -m pip install py-solc-x
```
run install_solc.py  
```shell
$ python install_solc.py
```

## Single Step ##

```shell
$ ./prepare_python_tests.sh  
$ python test_single_step.py <path to single step .json file>  
```

## Multiple Steps ##

```shell
$ ./prepare_python_tests.sh  
$ python test_single_step.py <path to multiple steps .json file>  
```

## Test Ram ##

```shell
$ ./prepare_python_tests.sh  
$ python test_ram.py <path to test program .bin file>  
```