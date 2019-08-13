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

def load_bytes_to_mm(filename, position, mm_index, w3, debug):
    if(debug):
        print("loading file: " + filename + " to memory address: " + str(position))
    for b in bytes_from_file(filename, number_of_bytes):
        try:
            tx_hash = mm.functions.write(mm_index, position, b).transact({'from': w3.eth.coinbase, 'gas': 6283185})
            tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
        except ValueError as e:
            print(e)
        else:
            position += number_of_bytes

def test_ram(step, mm, mm_index, w3):
    #print("Calling Step: ")
    halt = False
    cycle = 0
    htif_exit_code = 0

    log = []
    
    while(True):
        try:
            step_tx = step.functions.step(mm_index).transact({'from': w3.eth.coinbase, 'gas': 6283185})
            tx_receipt = w3.eth.waitForTransactionReceipt(step_tx)

            # log the reads and writes via events
            log_index = 0
            step_log = {}
            step_log['init_cycles'] = cycle
            step_log['final_cycles'] = cycle + 1
            step_log['accesses'] = []

            mm_logs = mm.events.ValueReplay().processReceipt(tx_receipt)
            while(log_index < len(mm_logs)):
                replay_log = {}
                is_read = mm_logs[log_index]['args']['_isRead']
                position = mm_logs[log_index]['args']['_position']
                read_value = mm_logs[log_index]['args']['_readValue']
                written_value = mm_logs[log_index]['args']['_writtenValue']
                log_index += 1

                if (is_read):
                    replay_log['type'] = 'read'
                else:
                    replay_log['type'] = 'write'
                replay_log['read'] = read_value.hex()
                replay_log['written'] = written_value.hex()
                replay_log['proof'] = {}
                replay_log['proof']['address'] = position

                step_log['accesses'].append(replay_log)

            log.append(step_log)

            step_filter = step.events.StepStatus.createFilter(fromBlock='latest')
            halt = step_filter.get_all_entries()[0]['args']['halt']
            if(halt):
                # remove the last read checking halt flag
                log.pop(len(log) - 1)
                break
            cycle = step_filter.get_all_entries()[0]['args']['cycle']

        except ValueError as e:
            print("REVERT")
            print(e)

    mm_tx = mm.functions.htifExit(mm_index).transact({'from': w3.eth.coinbase, 'gas': 6283185})
    tx_receipt = w3.eth.waitForTransactionReceipt(mm_tx)
    mm_filter = mm.events.HTIFExit.createFilter(fromBlock='latest')
    htif_exit_code = mm_filter.get_all_entries()[0]['args']['_exitCode']
    print("cycles: " + str(cycle) + ", exit code: " + str(htif_exit_code))

    with open('ram_replay.json', 'w') as outfile:  
        json.dump(log, outfile)

# start of main test

if len(sys.argv) != 2:
    print("Usage: python test_ram.py <.bin file path OR directory path containing .bin files>")
    sys.exit(1)

fake_hash = bytes(32)
fake_address = Web3.toChecksumAddress("0000000000000000000000000000000000000001")
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

tx_hash = mm.functions.instantiate(w3.eth.coinbase, fake_address, fake_hash).transact({'from': w3.eth.coinbase, 'gas': 6283185})
tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
mm_filter = mm.events.MemoryCreated.createFilter(fromBlock='latest')
mm_index = mm_filter.get_all_entries()[0]['args']['_index']

# load shadows
position = 0
load_bytes_to_mm("./test_ram/shadow-tests.bin", position, mm_index, w3, False)

# load rom
position = 0x1000
load_bytes_to_mm("./test_ram/jump-to-ram.bin", position, mm_index, w3, False)

# load ram
position = 0x80000000
load_bytes_to_mm(sys.argv[1], position, mm_index, w3, True)

# run test program from ram
test_ram(step, mm, mm_index, w3)
