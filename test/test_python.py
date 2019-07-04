import sys
import os
import json
import requests
from web3 import Web3
from solcx import install_solc
from solcx import get_solc_version, set_solc_version, compile_files

get_solc_version()

succ_num = 0
revert_num = 0

reverted_steps = []
#Connecting to node
endpoint = "http://127.0.0.1:8545"
w3 = Web3(Web3.HTTPProvider(endpoint))

if (w3.isConnected()):
    print("Connected to node\n")
else:
    print("Couldn't connect to node, exiting")
    sys.exit(1)

#step_compiled = compile_files([directory + 'Step.sol'])
with open('../test/p-sb.json') as json_file:
    jsonsteps = json.load(json_file)
with open('../build/contracts/Step.json') as json_file:
    step_data = json.load(json_file)

with open('../build/contracts/MMInstantiator.json') as json_file:
    mm_data = json.load(json_file)

with open('./deployedAddresses.json') as json_file:
    deployedAddresses = json.load(json_file)

step = w3.eth.contract(address=deployedAddresses["step_address"], abi=step_data['abi'])

mm = w3.eth.contract(address=deployedAddresses["mm_address"], abi=mm_data['abi'])

for index, entry in enumerate(jsonsteps):
    tx_hash = mm.functions.instantiate(w3.eth.accounts[0], w3.eth.accounts[1], entry["accesses"][0]["proof"]["root_hash"]).transact({'from': w3.eth.coinbase, 'gas': 9007199254740991})
    receipt = w3.eth.waitForTransactionReceipt(tx_hash)
    mm_filter = mm.events.MemoryCreated.createFilter(fromBlock='latest')
    mm_index = mm_filter.get_all_entries()[0]['args']['_index']
    
    # snapshot evm
    headers = {'content-type': 'application/json'}
    payload = {"method": "evm_snapshot", "params": [], "jsonrpc": "2.0", "id": 0}
    response = requests.post(endpoint, data=json.dumps(payload), headers=headers).json()
    snapshot_id = response['result']

    for rwentry in entry["accesses"]:
            if rwentry["type"] == "read":
                try:
                    tx_hash2 = mm.functions.proveRead(mm_index, rwentry["proof"]["address"], rwentry["read"], rwentry["proof"]["sibling_hashes"][::-1]).transact({'from': w3.eth.accounts[1], 'gas': 9007199254740991})
                    receipt = w3.eth.waitForTransactionReceipt(tx_hash2)
                except ValueError as e:
                    print("proveRead REVERT trasaction")
                    print(e)
            else:
                try:
                    tx_hash2 = mm.functions.proveWrite(mm_index, rwentry["proof"]["address"], rwentry["read"], rwentry["written"], rwentry["proof"]["sibling_hashes"][::-1]).transact({'from': w3.eth.accounts[1], 'gas': 9007199254740991})
                    receipt = w3.eth.waitForTransactionReceipt(tx_hash2)
                except ValueError as e:
                    print("proveWrite REVERT trasaction")
                    print(e)


    print("Callin Step: ")
    print(index)
    try:
        step_tx = step.functions.step(mm_index).transact({'from': w3.eth.accounts[0], 'gas': 9007199254740991})
        tx_receipt = w3.eth.waitForTransactionReceipt(step_tx)
    except ValueError as e:
        print("REVERT trasaction")
        print(e)
        revert_num += 1
        reverted_steps.append(index)
    else:
        print("SUCCESS")
        succ_num += 1
        
        # revert evm
        payload = {"method": "evm_revert", "params": [snapshot_id], "jsonrpc": "2.0", "id": 0}
        response = requests.post(endpoint, data=json.dumps(payload), headers=headers).json()


#myfilter = step.eventFilter('StepGiven', {'fromBlock': 0,'toBlock': 'latest'})
#eventlist = myfilter.get_all_entries()

print("Number of successes:")
print(succ_num)
print("Number of reverted transactions: ")
print(revert_num)
print("List of reverted indexes: ")
print(reverted_steps)

for entry in reverted_steps:
    print(jsonsteps[entry]["brackets"][len(jsonsteps[entry]["brackets"]) - 2])
#for index, event in enumerate(eventlist):
#    print("Index: ")
#    print(index)
#    print("StepGiven exit code:")
#    print(event['args']['exitCode'])


