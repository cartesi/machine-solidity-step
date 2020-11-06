# Copyright 2019 Cartesi Pte. Ltd.

# Licensed under the Apache License, Version 2.0 (the "License"); you may not use
# this file except in compliance with the License. You may obtain a copy of the
# License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.


import os
import sys
import json
from web3 import Web3
from web3.auto import w3

def test_json_steps(json_steps, w3, start):

    succ_num = 0
    reverted_steps = []
    total = len(jsonsteps)

    provider = w3.eth.coinbase
    client = w3.eth.accounts[1]

    for index, entry in enumerate(jsonsteps):
        if index < start:
            continue
        snapshot_id = w3.testing.snapshot()
        tx_hash = mm.functions.instantiate(provider, client, jsonsteps[index]["accesses"][0]["proof"]["root_hash"]).transact({'from': provider, 'gas': 6283185})
        tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
        mm_filter = mm.events.MemoryCreated.createFilter(fromBlock='latest')
        mm_index = mm_filter.get_all_entries()[0]['args']['_index']

        for rwentry in entry["accesses"]:
            op_type = rwentry.get("operation", None) or rwentry["type"]
            if op_type.upper() == "READ":
                try:
                    tx_hash2 = mm.functions.proveRead(mm_index, rwentry["proof"]["address"], rwentry["read"], rwentry["proof"]["sibling_hashes"][::-1]).transact({'from': provider, 'gas': 6283185})
                    receipt = w3.eth.waitForTransactionReceipt(tx_hash2)
                    if receipt['status'] == 0:
                        raise ValueError(receipt['transactionHash'].hex())
                except ValueError as e:
                    print("proveRead REVERT transaction")
                    print(e)
            else:
                try:
                    tx_hash2 = mm.functions.proveWrite(mm_index, rwentry["proof"]["address"], rwentry["read"], rwentry["written"], rwentry["proof"]["sibling_hashes"][::-1]).transact({'from': provider, 'gas': 6283185})
                    receipt = w3.eth.waitForTransactionReceipt(tx_hash2)
                    if receipt['status'] == 0:
                        raise ValueError(receipt['transactionHash'].hex())
                except ValueError as e:
                    print("proveWrite REVERT transaction")
                    print(e)

        try:
            tx_hash = mm.functions.finishProofPhase(mm_index).transact({'from': provider, 'gas': 6283185})
            tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
            if receipt['status'] == 0:
                raise ValueError(receipt['transactionHash'].hex())
        except ValueError as e:
            print("finishProofPhase REVERT transaction")
            print(e)

        try:
            (positions, values, operations) = mm.functions.getRWArrays(mm_index).transact({'from': provider, 'gas': 6283185})
            tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
            if receipt['status'] == 0:
                raise ValueError(receipt['transactionHash'].hex())
        except ValueError as e:
            print("getRWArrats REVERT transaction")
            print(e)

        print("Calling Step ({}/{}):".format(index + 1, total))
        try:
            step_tx = step.functions.step(positions, values, operations).transact({'from': client, 'gas': 6283185})
            tx_receipt = w3.eth.waitForTransactionReceipt(step_tx)
            if receipt['status'] == 0:
                raise ValueError(receipt['transactionHash'].hex())
        except ValueError as e:
            print("REVERT step")
            print(e)
            reverted_steps.append(index)
            break
        else:
            print("SUCCESS")
            succ_num += 1
        finally:
            w3.testing.revert(snapshot_id)

    print("Number of successful steps: {}".format(succ_num))

    revert_num = len(reverted_steps)
    if revert_num > 0:
        print("Number of reverted steps: {}".format(revert_num))
        print("List of reverted steps: {}".format(reverted_steps))
        for entry in reverted_steps:
            print(jsonsteps[entry]["brackets"][len(jsonsteps[entry]["brackets"]) - 2])
        return False

    return True

# start of main test

if len(sys.argv) < 2 or len(sys.argv) > 3:
    print("Usage: python test_steps.py <step file path> <number of steps to skip>(optional)")
    sys.exit(1)

start = 0
if len(sys.argv) == 3:
    start = int(sys.argv[2])

#Connecting to node
endpoint = "http://127.0.0.1:8545"
w3 = Web3(Web3.HTTPProvider(endpoint, request_kwargs={"timeout": 240}))

if not w3.isConnected():
    print("Couldn't connect to node, exiting")
    sys.exit(1)

networkId = w3.net.version

with open('../deployments/localhost/Step.json') as json_file:
    step_data = json.load(json_file)

with open('../deployments/localhost/MMInstantiator.json') as json_file:
    mm_data = json.load(json_file)

step = w3.eth.contract(address=step_data['address'], abi=step_data['abi'])
mm = w3.eth.contract(address=mm_data['address'], abi=mm_data['abi'])

with open(sys.argv[1]) as json_file:
    jsonsteps = json.load(json_file)
test_json_steps(jsonsteps, w3, start)
