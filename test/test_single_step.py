import os
import sys
import json
import requests
from web3 import Web3
from solcx import install_solc
from solcx import get_solc_version, set_solc_version, compile_files

def test_json_steps(json_steps, w3):

    tx_hash = mm.functions.instantiate(w3.eth.accounts[0], w3.eth.accounts[1], jsonsteps[0]["accesses"][0]["proof"]["root_hash"]).transact({'from': w3.eth.coinbase, 'gas': 9007199254740991})
    tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
    mm_filter = mm.events.MemoryCreated.createFilter(fromBlock='latest')
    mm_index = mm_filter.get_all_entries()[0]['args']['_index']

    for index, entry in enumerate(jsonsteps):
        for rwentry in entry["accesses"]:
            if rwentry["operation"] == "READ":
                try:
                    tx_hash2 = mm.functions.proveRead(mm_index, rwentry["proof"]["address"], rwentry["read"], rwentry["proof"]["sibling_hashes"][::-1]).transact({'from': w3.eth.accounts[1], 'gas': 9007199254740991})
                    receipt = w3.eth.waitForTransactionReceipt(tx_hash2)
                except ValueError as e:
                    print("READ REVERT")
            else:
                try:
                    tx_hash2 = mm.functions.proveWrite(mm_index, rwentry["proof"]["address"], rwentry["read"], rwentry["written"], rwentry["proof"]["sibling_hashes"][::-1]).transact({'from': w3.eth.accounts[1], 'gas': 9007199254740991})
                    receipt = w3.eth.waitForTransactionReceipt(tx_hash2)
                except ValueError as e:
                    print("WRITE REVERT")

        print("Callin Step: ")
        try:
            step_tx = step.functions.step(mm_index).transact({'from': w3.eth.accounts[0], 'gas': 9007199254740991})
            tx_receipt = w3.eth.waitForTransactionReceipt(step_tx)
        except ValueError as e:
            print("REVERT")
            print(e)
        else:
            print("SUCCESS")

# start of main test

if len(sys.argv) != 2:
    print("Usage: python test_multi_steps.py <step file path OR directory path containing step files>")
    sys.exit(1)

#Connecting to node
endpoint = "http://127.0.0.1:8545"
w3 = Web3(Web3.HTTPProvider(endpoint, request_kwargs={'timeout': 60}))

if (not w3.isConnected()):
    print("Couldn't connect to node, exiting")
    sys.exit(1)

#step_compiled = compile_files([directory + 'Step.sol'])
#with open('../test/step_dumps/add_instruction_step.json') as json_file:
#    jsonsteps = json.load(json_file)
with open('../build/contracts/Step.json') as json_file:
    step_data = json.load(json_file)

with open('../build/contracts/MMInstantiator.json') as json_file:
    mm_data = json.load(json_file)

with open('./deployedAddresses.json') as json_file:
    deployedAddresses = json.load(json_file)

step = w3.eth.contract(address=deployedAddresses["step_address"], abi=step_data['abi'])
mm = w3.eth.contract(address=deployedAddresses["mm_address"], abi=mm_data['abi'])

with open(sys.argv[1]) as json_file:
    jsonsteps = json.load(json_file)
test_json_steps(jsonsteps, w3)