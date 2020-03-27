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

def bytes_from_file(filename, chunksize):
    with open(filename, "rb") as f:
        while True:
            chunk = f.read(chunksize)
            if chunk:
                yield chunk
            else:
                break

def load_bytes_to_mm(filename, position, mm_index, w3):
    number_of_bytes = 8
    initial_position = position
    loaded_bytes = 0
    total_bytes = os.path.getsize(filename)
    for b in bytes_from_file(filename, number_of_bytes):
        tx_hash = mm.functions.write(mm_index, position, b).transact({'from': w3.eth.coinbase, 'gas': 6283185})
        tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)

        if tx_receipt['status'] == 0:
            raise ValueError(receipt['transactionHash'].hex())
        position += number_of_bytes
        loaded_bytes += len(b)
        sys.stdout.write("\rLoading file %s to address %d, bytes loaded: %d/%d" % (filename, initial_position, loaded_bytes, total_bytes))
        sys.stdout.flush()
    print("")

def test_ram(step, mm, mm_index, w3):
    halt = False
    cycle = 0
    htif_exit_code = 0

    log = []
   
    while(True):
        try:
            step_tx = step.functions.step(mm_index).transact({'from': w3.eth.coinbase, 'gas': 6283185})
            tx_receipt = w3.eth.waitForTransactionReceipt(step_tx)

            if tx_receipt['status'] == 0:
                raise ValueError(tx_receipt['transactionHash'].hex())
            # log the reads and writes via events
            #log_index = 0
            #step_log = {}
            #step_log['init_cycles'] = cycle
            #step_log['final_cycles'] = cycle + 1
            #step_log['accesses'] = []
            
            #mm_logs = mm.events.ValueReplay().processReceipt(tx_receipt)
            #while(log_index < len(mm_logs)):
            #    replay_log = {}
            #    is_read = mm_logs[log_index]['args']['_isRead']
            #    position = mm_logs[log_index]['args']['_position']
            #    read_value = mm_logs[log_index]['args']['_readValue']
            #    written_value = mm_logs[log_index]['args']['_writtenValue']
            #    log_index += 1

            #    if (is_read):
            #        replay_log['type'] = 'read'
            #    else:
            #        replay_log['type'] = 'write'
            #    replay_log['read'] = read_value.hex()
            #    replay_log['written'] = written_value.hex()
            #    replay_log['proof'] = {}
            #    replay_log['proof']['address'] = position

            #    step_log['accesses'].append(replay_log)

            #log.append(step_log)
            
            step_filter = step.events.StepStatus.createFilter(fromBlock='latest')
            halt = step_filter.get_all_entries()[0]['args']['halt']
            if halt:
                # remove the last read checking halt flag
            #    log.pop(len(log) - 1)
                break
            cycle = step_filter.get_all_entries()[0]['args']['cycle']
            sys.stdout.write("\rCurrent stepping cycles is: %d" % cycle)
            sys.stdout.flush()

        except ValueError as e:
            print("REVERT")
            print(e)
    
    mm_tx = mm.functions.htifExit(mm_index).transact({'from': w3.eth.coinbase, 'gas': 6283185})
    tx_receipt = w3.eth.waitForTransactionReceipt(mm_tx)
    if tx_receipt['status'] == 0:
        raise ValueError(receipt['transactionHash'].hex())

    mm_filter = mm.events.HTIFExit.createFilter(fromBlock='latest')
    htif_exit_code = mm_filter.get_all_entries()[0]['args']['_exitCode']
    sys.stdout.write("\rResult cycles: %d, exit code: %d\n" % (cycle, htif_exit_code))
    sys.stdout.flush()
    return True

    #with open('ram_replay.json', 'w') as outfile:  
        #json.dump(log, outfile)

# start of main test

if len(sys.argv) != 2:
    print("Usage: python test_ram.py <.bin file path>")
    sys.exit(1)

fake_hash = bytes(32)
fake_address = Web3.toChecksumAddress("0000000000000000000000000000000000000001")

#Connecting to node
endpoint = "http://127.0.0.1:8545"
w3 = Web3(Web3.HTTPProvider(endpoint, request_kwargs={'timeout': 60}))

if not w3.isConnected():
    print("Couldn't connect to node, exiting")
    sys.exit(1)

networkId = w3.net.version

with open('../build/contracts/Step.json') as json_file:
    step_data = json.load(json_file)

with open('../build/contracts/TestRamMMInstantiator.json') as json_file:
    mm_data = json.load(json_file)

step = w3.eth.contract(address=step_data['networks'][networkId]['address'], abi=step_data['abi'])
mm = w3.eth.contract(address=mm_data['networks'][networkId]['address'], abi=mm_data['abi'])

tx_hash = mm.functions.instantiate(fake_address, w3.eth.coinbase, fake_hash).transact({'from': w3.eth.coinbase, 'gas': 6283185})
tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
if tx_receipt['status'] == 0:
    raise ValueError(receipt['transactionHash'].hex())

mm_filter = mm.events.MemoryCreated.createFilter(fromBlock='latest')
mm_index = mm_filter.get_all_entries()[0]['args']['_index']

tx_hash = mm.functions.finishProofPhase(mm_index).transact({'from': w3.eth.coinbase, 'gas': 6283185})
tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
if tx_receipt['status'] == 0:
    raise ValueError(tx_receipt['transactionHash'].hex())


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
