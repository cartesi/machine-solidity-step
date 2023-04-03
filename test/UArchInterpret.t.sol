// Copyright 2023 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "./UArchStateAux.sol";
import "./UArchInterpret.sol";
import "contracts/UArchStep.sol";
import "contracts/interfaces/IUArchState.sol";
import "contracts/interfaces/IMemoryAccessLog.sol";

pragma solidity ^0.8.0;

contract UArchInterpretTest is Test {
    // constant addresses
    uint64 constant UCYCLE = 0x320;
    uint64 constant UPC = 0x330;

    uint64 constant TEST_STATUS_X = 1;
    uint64 constant PMA_UARCH_RAM_START = 0x70000000;
    // little endian constants
    bytes8 constant LITTLE_PMA_UARCH_RAM_START = 0x0000007000000000;
    // test result code
    bytes8 constant TEST_SUCEEDED = 0x00000000be1e7aaa; // Indicates that test has passed
    bytes8 constant TEST_FAILED = 0x00000000deadbeef; // Indicates that test has failed
    // configure the tests
    string constant RAM_PATH_PREFIX = "./test/uarch-bin/rv64ui-uarch-";
    string constant ROM_PATH = "./test/uarch-bin/uarch-bootstrap.bin";
    // instructions to be tested
    string[] INSTRUCTIONS = [
        "add",
        "addi",
        "addiw",
        "addw",
        "and",
        "andi",
        "auipc",
        "beq",
        "bge",
        "bgeu",
        "blt",
        "bltu",
        "bne",
        "jal",
        "jalr",
        "lb",
        "lbu",
        "ld",
        "lh",
        "lhu",
        "lui",
        "lw",
        "lwu",
        "or",
        "ori",
        "sb",
        "sd",
        "sh",
        "simple",
        "sll",
        "slli",
        "slliw",
        "sllw",
        "slt",
        "slti",
        "sltiu",
        "sltu",
        "sra",
        "srai",
        "sraiw",
        "sraw",
        "srl",
        "srli",
        "srliw",
        "srlw",
        "sub",
        "subw",
        "sw",
        "xor",
        "xori"
    ];

    UArchStateAux sa;
    IUArchStep step;
    IUArchInterpret inter;

    function testBinaries() public {
        for (uint i = 0; i < INSTRUCTIONS.length; i++) {
            console.log(
                string.concat(string.concat("Testing ", INSTRUCTIONS[i]), "...")
            );

            // create fresh machine state for every test
            sa = new UArchStateAux();
            step = new UArchStep();
            inter = new UArchInterpret(step);
            // load ram
            loadBin(
                PMA_UARCH_RAM_START,
                string.concat(
                    string.concat(RAM_PATH_PREFIX, INSTRUCTIONS[i]),
                    ".bin"
                )
            );
            // init pc to ram start
            initPC();
            // init cycle to 1
            initCYCLE();

            IMemoryAccessLog.Access[]
                memory accesses = new IMemoryAccessLog.Access[](0);
            IMemoryAccessLog.AccessLogs memory accessLogs = IMemoryAccessLog
                .AccessLogs(accesses, 0);
            IUArchState.State memory state = IUArchState.State(
                address(sa),
                accessLogs
            );

            inter.interpret(state);

            assertEq(
                // read test result from the register
                sa.readX(accessLogs, TEST_STATUS_X),
                uint64(TEST_SUCEEDED)
            );
            console.log(sa.readCycle(accessLogs));
            console.log(string.concat(INSTRUCTIONS[i], " finished!"));
        }
    }

    function initCYCLE() private {
        sa.loadMemory(UCYCLE, 0);
    }

    function initPC() private {
        sa.loadMemory(UPC, LITTLE_PMA_UARCH_RAM_START);
    }

    function loadBin(uint64 start, string memory path) private {
        bytes memory bytesData = vm.readFileBinary(path);

        // pad bytes to multiple of 8
        if (bytesData.length % 8 != 0) {
            uint number_of_bytes_missing = ((bytesData.length / 8) + 1) *
                8 -
                bytesData.length;
            bytes memory bytes_missing = new bytes(number_of_bytes_missing);
            bytesData = bytes.concat(bytesData, bytes_missing);
        }

        // load the data into AccessState
        for (uint64 i = 0; i < bytesData.length / 8; i++) {
            bytes8 bytes8Data;
            uint64 offset = i * 8;
            for (uint64 j = 0; j < 8; j++) {
                bytes8 tempBytes8 = bytesData[offset + j];
                tempBytes8 = tempBytes8 >> (j * 8);
                bytes8Data = bytes8Data | tempBytes8;
            }
            sa.loadMemory(start + offset, bytes8Data);
        }
    }
}
