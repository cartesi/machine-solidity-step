import os
import json
from web3 import Web3
from solcx import install_solc
from solcx import get_solc_version, set_solc_version, compile_files

get_solc_version()

#Connecting to node
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))

if (w3.isConnected()):
    print("Connected to node\n")
else:
    print("Couldn't connect to node, exiting")
    sys.exit(1)

#step_compiled = compile_files([directory + 'Step.sol'])
with open('../test/new_data2.json') as json_file:
    jsonsteps = json.load(json_file)
with open('../build/contracts/Step.json') as json_file:
    step_data = json.load(json_file)

with open('../build/contracts/MMInstantiator.json') as json_file:
    mm_data = json.load(json_file)

step = w3.eth.contract(address="0x1129ff6c9fdBf42A354D45947D7fF882215b269a", abi=step_data['abi'])

mm = w3.eth.contract(address="0xd7050EB56aD6BAB2abAB82935B3f6B5868Fe7eCC", abi=mm_data['abi'])

for index, entry in enumerate(jsonsteps):
    tx_hash = mm.functions.instantiate(w3.eth.accounts[0], w3.eth.accounts[1], entry["accesses"][0]["proof"]["root_hash"]).transact({'from': w3.eth.coinbase, 'gas': 9007199254740991})

    for rwentry in entry["accesses"]:
        if rwentry["type"] == "read":
            tx_hash2 = mm.functions.proveRead(index, rwentry["proof"]["address"], rwentry["read"], rwentry["proof"]["sibling_hashes"][::-1]).transact({'from': w3.eth.accounts[1], 'gas': 9007199254740991})
        else:
            tx_hash2 = mm.functions.proveWrite(index, rwentry["proof"]["address"], rwentry["read"], rwentry["written"], rwentry["proof"]["sibling_hashes"][::-1]).transact({'from': w3.eth.accounts[1], 'gas': 9007199254740991})

        receipt = w3.eth.waitForTransactionReceipt(tx_hash2)

    print("Callin Step: ")
    print(index)
    stepResult = step.functions.step(index).transact({'from': w3.eth.accounts[0], 'gas': 9007199254740991})

    step_receipt = w3.eth.waitForTransactionReceipt(stepResult)

myfilter = step.eventFilter('StepGiven', {'fromBlock': 0,'toBlock': 'latest'});
eventlist = myfilter.get_all_entries()

for index, event in enumerate(eventlist):
    print("Index: ")
    print(index)
    print("StepGiven exit code:")
    print(event['args']['exitCode'])



