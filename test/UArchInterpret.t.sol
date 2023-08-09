// Copyright Cartesi and individual authors (see AUTHORS)
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

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

    uint8 constant REGISTERS_LENGTH = 42;
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
        Entry[] memory catalog =
            loadCatalog(string.concat(JSON_PATH, CATALOG_PATH));

        for (uint256 i = 0; i < catalog.length; i++) {
            console.log("Testing %s ...", catalog[i].path);
            AccessLogs.Context memory a = newAccessLogsContext();

            // load ramAccessLogs
            loadBin(a.buffer, string.concat(JSON_PATH, catalog[i].path));
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

        UArchStep.UArchStepStatus status = UArchInterpret.interpret(a);

        assertTrue(
            status == UArchStep.UArchStepStatus.CycleOverflow,
            "machine should be cycle overflow"
        );

        uint64 cycle = UArchCompat.readCycle(a);
        assertEq(
            cycle,
            type(uint64).max,
            "step should not advance when cycle is uint64.max"
        );

        // reset cycle to 0
        UArchCompat.writeCycle(a, 0);
        // set machine to halt
        UArchCompat.setHaltFlag(a);

        status = UArchInterpret.interpret(a);

        assertTrue(
            status == UArchStep.UArchStepStatus.UArchHalted,
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

    function loadBin(Buffer.Context memory buffer, string memory path)
        private
        view
    {
        bytes memory bytesData = vm.readFileBinary(path);
        buffer.data = bytes.concat(buffer.data, bytesData);
    }

    function loadCatalog(string memory path)
        private
        view
        returns (Entry[] memory)
    {
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
        return AccessLogs.Context(
            bytes32(0),
            Buffer.Context(new bytes(uint128(REGISTERS_LENGTH) * 8), 0)
        );
    }
}
