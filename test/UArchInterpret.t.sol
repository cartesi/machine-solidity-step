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
import "forge-std/StdJson.sol";
import "./IUArchInterpret.sol";
import "./UArchStateAux.sol";
import "./UArchStepAux.sol";
import "./UArchInterpret.sol";
import "contracts/UArchStep.sol";
import "contracts/interfaces/IUArchState.sol";
import "contracts/interfaces/IMemoryAccessLog.sol";

pragma solidity ^0.8.0;

contract UArchInterpretTest is Test {
    using stdJson for string;

    struct Entry {
        uint256 cycle;
        string path;
    }

    uint8 constant TEST_STATUS_X = 1;
    uint64 constant PMA_UARCH_RAM_START = 0x70000000;
    // little endian constants
    bytes8 constant LITTLE_PMA_UARCH_RAM_START = 0x0000007000000000;
    // test result code
    bytes8 constant TEST_SUCEEDED = 0x00000000be1e7aaa; // Indicates that test has passed
    bytes8 constant TEST_FAILED = 0x00000000deadbeef; // Indicates that test has failed
    // configure the tests
    string constant JSON_PATH = "./test/uarch-bin/";
    string constant CATALOG_PATH = "rv64ui-uarch-catalog.json";
    string constant ROM_PATH = "./test/uarch-bin/uarch-bootstrap.bin";

    UArchStateAux sa;
    IUArchStep step;
    IUArchInterpret inter;

    function testBinaries() public {
        Entry[] memory catalog = loadCatalog(
            string.concat(JSON_PATH, CATALOG_PATH)
        );

        for (uint i = 0; i < catalog.length; i++) {
            console.log("Testing %s ...", catalog[i].path);

            // create fresh machine state for every test
            sa = new UArchStateAux();
            // use `UArchStepAux` to bypass `current` check, as we don't know how many accesses are in the binary
            step = new UArchStepAux();
            inter = new UArchInterpret(step);
            // load ram
            loadBin(
                PMA_UARCH_RAM_START,
                string.concat(JSON_PATH, catalog[i].path)
            );
            // init pc to ram start
            initPC();
            // init cycle to 0
            initCYCLE();

            IMemoryAccessLog.Access[]
                memory accesses = new IMemoryAccessLog.Access[](0);
            IMemoryAccessLog.AccessLogs memory accessLogs = IMemoryAccessLog
                .AccessLogs(accesses, 0);
            IUArchState.State memory state = IUArchState.State(sa, accessLogs);

            inter.interpret(state);

            assertEq(
                // read test result from the register
                sa.readX(accessLogs, TEST_STATUS_X),
                uint64(TEST_SUCEEDED)
            );
            assertTrue(sa.readHaltFlag(accessLogs), "machine should halt");
            assertEq(
                sa.readCycle(accessLogs),
                catalog[i].cycle,
                "cycle values should match"
            );
        }
    }

    function testStepEarlyReturn() public {
        // create fresh machine state for every test
        sa = new UArchStateAux();
        step = new UArchStep();
        inter = new UArchInterpret(step);
        // init pc to ram start
        initPC();
        // init cycle to uint64.max
        initMaxCYCLE();

        IMemoryAccessLog.Access[]
            memory accesses = new IMemoryAccessLog.Access[](2);
        IMemoryAccessLog.AccessLogs memory accessLogs = IMemoryAccessLog
            .AccessLogs(accesses, 0);
        IUArchState.State memory state = IUArchState.State(sa, accessLogs);

        IUArchInterpret.InterpreterStatus status = inter.interpret(state);

        assertTrue(
            status == IUArchInterpret.InterpreterStatus.Success,
            "machine shouldn't halt"
        );
        assertEq(
            sa.readCycle(accessLogs),
            type(uint64).max,
            "step should not advance when cycle is uint64.max"
        );

        // set machine to halt
        initHalt();

        status = inter.interpret(state);

        assertTrue(
            status == IUArchInterpret.InterpreterStatus.Halt,
            "machine should halt"
        );
    }

    function testIllegalInstruction() public {
        // create fresh machine state for every test
        sa = new UArchStateAux();
        // use `UArchStepAux` to bypass `current` check, as we don't care in this case
        step = new UArchStepAux();
        inter = new UArchInterpret(step);
        // init pc to ram start
        initPC();
        // init cycle to 0
        initCYCLE();

        IMemoryAccessLog.Access[]
            memory accesses = new IMemoryAccessLog.Access[](0);
        IMemoryAccessLog.AccessLogs memory accessLogs = IMemoryAccessLog
            .AccessLogs(accesses, 0);
        IUArchState.State memory state = IUArchState.State(sa, accessLogs);

        vm.expectRevert("illegal instruction");
        inter.interpret(state);
    }

    function testCurrentPointer() public {
        // create fresh machine state for every test
        sa = new UArchStateAux();
        step = new UArchStep();
        inter = new UArchInterpret(step);
        // init pc to ram start
        initPC();
        // NOP = ADDI x0, x0, 0 = 0x00000013
        sa.loadMemory(PMA_UARCH_RAM_START, bytes8(0x1300000000000000));

        IMemoryAccessLog.Access[]
            memory accesses = new IMemoryAccessLog.Access[](0);
        IMemoryAccessLog.AccessLogs memory accessLogs = IMemoryAccessLog
            .AccessLogs(accesses, 0);
        IUArchState.State memory state = IUArchState.State(sa, accessLogs);

        vm.expectRevert("access pointer should match accesses length");
        inter.interpret(state);

        // init cycle to uint64.max
        initMaxCYCLE();

        vm.expectRevert(
            "access pointer should match accesses length when cycle is uint64.max"
        );
        inter.interpret(state);

        // set machine to halt
        initHalt();

        vm.expectRevert(
            "access pointer should match accesses length when halt"
        );
        inter.interpret(state);
    }

    function initCYCLE() private {
        sa.loadMemory(sa.UCYCLE(), 0);
    }

    function initMaxCYCLE() private {
        sa.loadMemory(sa.UCYCLE(), 0xffffffffffffffff);
    }

    function initHalt() private {
        sa.loadMemory(sa.UHALT(), 0x0100000000000000);
    }

    function initPC() private {
        sa.loadMemory(sa.UPC(), LITTLE_PMA_UARCH_RAM_START);
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

    function loadCatalog(
        string memory path
    ) private view returns (Entry[] memory) {
        string memory json = vm.readFile(path);
        bytes memory raw = json.parseRaw("");
        Entry[] memory catalog = abi.decode(raw, (Entry[]));

        return catalog;
    }
}
