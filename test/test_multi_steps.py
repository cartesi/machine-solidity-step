import sys
import os
import json
from web3 import Web3
from solcx import install_solc
from solcx import get_solc_version, set_solc_version, compile_files

# start of main test

if len(sys.argv) != 2:
    print("Usage: python test_multi_steps.py <step file path OR directory path containing step files>")
    sys.exit(1)

#Connecting to node
endpoint = "http://127.0.0.1:8545"
w3 = Web3(Web3.HTTPProvider(endpoint))

if (not w3.isConnected()):
    print("Couldn't connect to node, exiting")
    sys.exit(1)

fake_address = Web3.toChecksumAddress("0000000000000000000000000000000000000001")
succ_num = 0
revert_num = 0
reverted_steps = []

with open(sys.argv[1]) as json_file:
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
    tx_hash = mm.functions.instantiate(w3.eth.coinbase, fake_address, entry["accesses"][0]["proof"]["root_hash"]).transact({'from': w3.eth.coinbase, 'gas': 6283185})
    receipt = w3.eth.waitForTransactionReceipt(tx_hash)
    mm_filter = mm.events.MemoryCreated.createFilter(fromBlock='latest')
    mm_index = mm_filter.get_all_entries()[0]['args']['_index']

    for rwentry in entry["accesses"]:
            if rwentry["type"] == "read":
                try:
                    tx_hash2 = mm.functions.proveRead(mm_index, rwentry["proof"]["address"], rwentry["read"], rwentry["proof"]["sibling_hashes"][::-1]).transact({'from': w3.eth.coinbase, 'gas': 6283185})
                    receipt = w3.eth.waitForTransactionReceipt(tx_hash2)
                    if receipt['status'] == 0:
                        raise ValueError(receipt['transactionHash'].hex())
                except ValueError as e:
                    print("proveRead REVERT transaction")
                    print(e)
            else:
                try:
                    tx_hash2 = mm.functions.proveWrite(mm_index, rwentry["proof"]["address"], rwentry["read"], rwentry["written"], rwentry["proof"]["sibling_hashes"][::-1]).transact({'from': w3.eth.coinbase, 'gas': 6283185})
                    receipt = w3.eth.waitForTransactionReceipt(tx_hash2)
                    if receipt['status'] == 0:
                        raise ValueError(receipt['transactionHash'].hex())
                except ValueError as e:
                    print("proveWrite REVERT transaction")
                    print(e)


    print("Calling Step: ")
    print(index)
    try:
        step_tx = step.functions.step(mm_index).transact({'from': w3.eth.coinbase, 'gas': 6283185})
        tx_receipt = w3.eth.waitForTransactionReceipt(step_tx)
        if receipt['status'] == 0:
            raise ValueError(receipt['transactionHash'].hex())
    except ValueError as e:
        print("REVERT step")
        print(e)
        revert_num += 1
        reverted_steps.append(index)
        break
    else:
        print("SUCCESS")
        succ_num += 1

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


