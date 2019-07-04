import os
import sys
import json
import requests
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
            tx_hash = mm.functions.write(mm_index, position, b).transact({'from': w3.eth.accounts[1], 'gas': 9007199254740991})
            tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
        except ValueError as e:
            print(e)
        else:
            position += number_of_bytes

def test_ram(step, mm, mm_index, w3):
    print("Calling Step: ")
    try:
        step_tx = step.functions.step(mm_index).transact({'from': w3.eth.accounts[1], 'gas': 9007199254740991})
        tx_receipt = w3.eth.waitForTransactionReceipt(step_tx)
        mm_tx = mm.functions.htifExit(mm_index).transact({'from': w3.eth.accounts[1], 'gas': 9007199254740991})
        tx_receipt = w3.eth.waitForTransactionReceipt(mm_tx)
        mm_filter = mm.events.HTIFExit.createFilter(fromBlock='latest')
        htif_exit_code = mm_filter.get_all_entries()[0]['args']['_exitCode']
        print("exit code: " + str(htif_exit_code))
        if(htif_exit_code != 0):
            return False
    except ValueError as e:
        print("REVERT")
        print(e)
        return False
    else:
        print("SUCCESS")
        return True

# start of main test
get_solc_version()

fake_hash = bytes(32)
number_of_bytes = 8
succ_num = 0
revert_num = 0
reverted_steps = []

#Connecting to node
endpoint = "http://127.0.0.1:8545"
w3 = Web3(Web3.HTTPProvider(endpoint, request_kwargs={'timeout': 60}))

if (w3.isConnected()):
    print("Connected to node\n")
else:
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

tx_hash = mm.functions.instantiate(w3.eth.accounts[0], w3.eth.accounts[1], fake_hash).transact({'from': w3.eth.coinbase, 'gas': 9007199254740991})
tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
mm_filter = mm.events.MemoryCreated.createFilter(fromBlock='latest')
mm_index = mm_filter.get_all_entries()[0]['args']['_index']

# load shadows
position = 0
load_bytes_to_mm("./images-tests/shadow-tests.bin", position, mm_index, w3)

# load rom
position = 0x1000
load_bytes_to_mm("./images-tests/jump-to-ram.bin", position, mm_index, w3)

# load ram
position = 0x80000000
single_test = False if len(sys.argv) == 1 else True

if(single_test):
    load_bytes_to_mm(sys.argv[1], position, mm_index, w3)

    if(test_ram(step, mm, mm_index, w3)):
        succ_num += 1
    else:
        revert_num += 1
else:

    directory = "./images-tests/tests/"
    for f_index, filename in enumerate(os.listdir(directory)):
        if filename.endswith(".bin"):
            # snapshot evm
            headers = {'content-type': 'application/json'}
            payload = {"method": "evm_snapshot", "params": [], "jsonrpc": "2.0", "id": 0}
            response = requests.post(endpoint, data=json.dumps(payload), headers=headers).json()
            snapshot_id = response['result']

            print(str(f_index) + ", " + filename)

            load_bytes_to_mm(os.path.join(directory + filename), position, mm_index, w3)

            if(test_ram(step, mm, mm_index, w3)):
                succ_num += 1
            else:
                revert_num += 1
                reverted_steps.append(f_index)

            # revert evm
            payload = {"method": "evm_revert", "params": [snapshot_id], "jsonrpc": "2.0", "id": 0}
            response = requests.post(endpoint, data=json.dumps(payload), headers=headers).json()

print("Number of successes:")
print(succ_num)
print("Number of reverted transactions: ")
print(revert_num)
print("List of reverted indices: ")
print(reverted_steps)
