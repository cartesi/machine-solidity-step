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

import "./UArchInterpret.sol";

pragma solidity ^0.8.0;

contract UArchInterpretTest is Test {
    using stdJson for string;
    using Memory for uint64;
    using AccessLogs for AccessLogs.Context;

    struct Entry {
        uint256 cycle;
        string path;
    }

    uint8 constant REGISTERS_LENGTH = 35;
    uint8 constant TEST_STATUS_X = 1;
    uint64 constant PMA_UARCH_RAM_START = 0x70000000;
    // test result code
    bytes8 constant TEST_SUCEEDED = 0x00000000be1e7aaa; // Indicates that test has passed
    bytes8 constant TEST_FAILED = 0x00000000deadbeef; // Indicates that test has failed
    // configure the tests
    string constant JSON_PATH = "./test/uarch-bin/";
    string constant CATALOG_PATH = "rv64ui-uarch-catalog.json";
    string constant ROM_PATH = "./test/uarch-bin/uarch-bootstrap.bin";

    function testBinaries() public {
        Entry[] memory catalog = loadCatalog(
            string.concat(JSON_PATH, CATALOG_PATH)
        );

        for (uint256 i = 0; i < catalog.length; i++) {
            console.log("Testing %s ...", catalog[i].path);
            AccessLogs.Context memory a = newAccessLogsContext();

            // load ramAccessLogs
            loadBin(
                a,
                PMA_UARCH_RAM_START,
                string.concat(JSON_PATH, catalog[i].path)
            );
            // init pc to ram start
            UArchCompat.writePc(a, PMA_UARCH_RAM_START);
            // init cycle to 0
            UArchCompat.writeCycle(a, 0);

            UArchInterpret.interpret(a);

            uint64 x = UArchCompat.readX(a, TEST_STATUS_X);
            assertEq(
                // read test result from the register
                x,
                uint64(TEST_SUCEEDED)
            );

            bool halt = UArchCompat.readHaltFlag(a);
            assertTrue(halt, "machine should halt");

            uint64 cycle = UArchCompat.readCycle(a);
            assertEq(cycle, catalog[i].cycle, "cycle values should match");
        }
    }

    function testStepEarlyReturn() public {
        AccessLogs.Context memory a = newAccessLogsContext();

        // init pc to ram start
        UArchCompat.writePc(a, PMA_UARCH_RAM_START);
        // init cycle to uint64.max
        UArchCompat.writeCycle(a, type(uint64).max);

        UArchInterpret.InterpreterStatus status = UArchInterpret.interpret(a);

        assertTrue(
            status == UArchInterpret.InterpreterStatus.Success,
            "machine shouldn't halt"
        );

        uint64 cycle = UArchCompat.readCycle(a);
        assertEq(
            cycle,
            type(uint64).max,
            "step should not advance when cycle is uint64.max"
        );

        // set machine to halt
        initHalt(a);

        status = UArchInterpret.interpret(a);

        assertTrue(
            status == UArchInterpret.InterpreterStatus.Halt,
            "machine should halt"
        );
    }

    function testIllegalInstruction() public {
        AccessLogs.Context memory a = newAccessLogsContext();

        // init pc to ram start
        UArchCompat.writePc(a, PMA_UARCH_RAM_START);
        // init cycle to 0
        UArchCompat.writeCycle(a, 0);

        vm.expectRevert("illegal instruction");
        UArchInterpret.interpret(a);
    }

    function initHalt(AccessLogs.Context memory a) private pure {
        a.writeWord(UArchConstants.UHALT.toPhysicalAddress(), 1);
    }

    function loadBin(
        AccessLogs.Context memory a,
        uint64 start,
        string memory path
    ) private view {
        bytes memory bytesData = vm.readFileBinary(path);

        // pad bytes to multiple of 8
        if (bytesData.length % 8 != 0) {
            uint number_of_bytes_missing = ((bytesData.length / 8) + 1) *
                8 -
                bytesData.length;
            bytes memory bytes_missing = new bytes(number_of_bytes_missing);
            bytesData = bytes.concat(bytesData, bytes_missing);
        }

        // allocate array for memory
        uint256 newBufferSize = bytesData.length +
            uint128(REGISTERS_LENGTH) *
            8;
        a.buffer = new bytes(newBufferSize);

        // load the data into AccessState
        for (uint64 i = 0; i < bytesData.length / 8; i++) {
            bytes8 bytes8Data;
            uint64 offset = i * 8;
            for (uint64 j = 0; j < 8; j++) {
                bytes8 tempBytes8 = bytesData[offset + j];
                tempBytes8 = tempBytes8 >> (j * 8);
                bytes8Data = bytes8Data | tempBytes8;
            }
            writeWordBytes8(a, start + offset, bytes8Data);
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

    function newAccessLogsContext()
        private
        pure
        returns (AccessLogs.Context memory)
    {
        return
            AccessLogs.Context(
                bytes32(0),
                new bytes(uint128(REGISTERS_LENGTH) * 8),
                0
            );
    }

    function writeWordBytes8(
        AccessLogs.Context memory a,
        uint64 writeAddress,
        bytes8 bytes8Val
    ) private pure {
        a.writeWord(
            writeAddress.toPhysicalAddress(),
            AccessLogs.uint64SwapEndian(uint64(bytes8Val))
        );
    }
}
