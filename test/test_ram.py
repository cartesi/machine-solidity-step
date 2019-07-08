import os
import sys
import json
from web3 import Web3
from solcx import install_solc
from solcx import get_solc_version, set_solc_version, compile_files

def bytes_from_file(filename, chunksize):
    with open(filename, "rb") as f:
        while True:
            chunk = f.read(chunksize)
            if chunk:
                yield chunk
            else:
                break

def load_bytes_to_mm(filename, position, mm_index, w3):
    print("loading file: " + filename + " to memory address: " + str(position))
    for b in bytes_from_file(filename, number_of_bytes):
        try:
            tx_hash = mm.functions.write(mm_index, position, b).transact({'from': w3.eth.accounts[0], 'gas': 9007199254740991})
            tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
        except ValueError as e:
            print(e)
        else:
            position += number_of_bytes

def test_ram(step, mm, mm_index, w3):
    print("Calling Step: ")
    halt = False
    cycle = 0
    htif_exit_code = 0
    
    while(True):
        try:
            step_tx = step.functions.step(mm_index).transact({'from': w3.eth.accounts[0], 'gas': 9007199254740991})
            tx_receipt = w3.eth.waitForTransactionReceipt(step_tx)
            step_filter = step.events.StepStatus.createFilter(fromBlock='latest')
            halt = step_filter.get_all_entries()[0]['args']['halt']
            if(halt):
                break
            cycle = step_filter.get_all_entries()[0]['args']['cycle']

        except ValueError as e:
            print("REVERT")
            print(e)

    mm_tx = mm.functions.htifExit(mm_index).transact({'from': w3.eth.accounts[0], 'gas': 9007199254740991})
    tx_receipt = w3.eth.waitForTransactionReceipt(mm_tx)
    mm_filter = mm.events.HTIFExit.createFilter(fromBlock='latest')
    htif_exit_code = mm_filter.get_all_entries()[0]['args']['_exitCode']
    print("cycles: " + str(cycle) + ", exit code: " + str(htif_exit_code))

# start of main test

if len(sys.argv) != 2:
    print("Usage: python test_ram.py <.bin file path OR directory path containing .bin files>")
    sys.exit(1)

fake_hash = bytes(32)
number_of_bytes = 8

#Connecting to node
endpoint = "http://127.0.0.1:8545"
w3 = Web3(Web3.HTTPProvider(endpoint, request_kwargs={'timeout': 60}))

if (not w3.isConnected()):
    print("Couldn't connect to node, exiting")
    sys.exit(1)

with open('../build/contracts/Step.json') as json_file:
    step_data = json.load(json_file)

with open('../build/contracts/TestRamMMInstantiator.json') as json_file:
    mm_data = json.load(json_file)

with open('./deployedAddresses.json') as json_file:
    deployedAddresses = json.load(json_file)

step = w3.eth.contract(address=deployedAddresses["step_address"], abi=step_data['abi'])
mm = w3.eth.contract(address=deployedAddresses["mm_address"], abi=mm_data['abi'])

tx_hash = mm.functions.instantiate(w3.eth.accounts[0], w3.eth.accounts[0], fake_hash).transact({'from': w3.eth.coinbase, 'gas': 9007199254740991})
tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
mm_filter = mm.events.MemoryCreated.createFilter(fromBlock='latest')
mm_index = mm_filter.get_all_entries()[0]['args']['_index']

# load shadows
position = 0
load_bytes_to_mm("./test_ram/shadow-tests.bin", position, mm_index, w3)

# load rom
position = 0x1000
load_bytes_to_mm("./test_ram/jump-to-ram.bin", position, mm_index, w3)

# load ram
position = 0x80000000
load_bytes_to_mm(sys.argv[1], position, mm_index, w3)

# run test program from ram
test_ram(step, mm, mm_index, w3)