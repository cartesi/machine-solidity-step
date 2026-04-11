// THIS IS AUTO GENERATED, ONLY EDIT THE TEMPLATE

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
pragma solidity ^0.8.30;

import "forge-std/console.sol";
import "forge-std/Test.sol";

import "src/Buffer.sol";
import "src/EmulatorConstants.sol";
import "src/UArchReset.sol";
import "./AccessLogJsonParse.sol";
import "./BufferAux.sol";

contract UArchReset_Test is AccessLogJsonParse {
    using Buffer for Buffer.Context;
    using BufferAux for Buffer.Context;

    // configure the tests
    string constant JSON_PATH = "./test/uarch-log/";
    string constant CATALOG_PATH = "catalog.json";
    string constant RESET_PATH = "reset-uarch-steps.json";

    uint256 constant siblingsLength = 42;

    struct Entry {
        string binaryFilename;
        string finalRootHash;
        string initialRootHash;
        string logFilename;
        uint256 steps;
    }

    string constant ENTRY_TYPE_DESCRIPTION =
        "Entry(string binaryFilename,string finalRootHash,string initialRootHash,string logFilename,uint256 steps)";

    function testReset() public {
        Entry[] memory catalog =
            loadCatalog(string.concat(JSON_PATH, CATALOG_PATH));
        string memory resetLog = string.concat(JSON_PATH, RESET_PATH);

        // all tests combined can easily run out of gas, stop metering
        // also raise memory_limit in foundry.toml per https://github.com/foundry-rs/foundry/issues/3971
        vm.pauseGasMetering();
        // create a large buffer and reuse it
        bytes memory buffer = new bytes(100 * (siblingsLength + 1) * 32);

        for (uint256 i = 0; i < catalog.length; i++) {
            if (
                keccak256(abi.encodePacked(catalog[i].logFilename))
                    != keccak256(abi.encodePacked("reset-uarch-steps.json"))
            ) {
                continue;
            }
            console.log("Replaying log file %s ...", catalog[i].logFilename);

            string memory rj = loadJsonLog(resetLog);

            bytes32 initialRootHash =
                vm.parseBytes32(string.concat("0x", catalog[i].initialRootHash));
            bytes32 finalRootHash =
                vm.parseBytes32(string.concat("0x", catalog[i].finalRootHash));

            loadBufferFromRawJson(buffer, rj);

            AccessLogs.Context memory accessLogs =
                AccessLogs.Context(initialRootHash, Buffer.Context(buffer, 0));

            // initialRootHash is passed and will be updated through out the step
            UArchReset.reset(accessLogs);

            assertEq(
                accessLogs.currentRootHash,
                finalRootHash,
                "final root hash must match"
            );
        }

        // load json log
    }

    function loadCatalog(string memory path)
        private
        view
        returns (Entry[] memory)
    {
        string memory json = vm.readFile(path);
        bytes memory raw =
            vm.parseJsonTypeArray(json, ".", ENTRY_TYPE_DESCRIPTION);
        Entry[] memory catalog = abi.decode(raw, (Entry[]));

        return catalog;
    }

    function loadJsonLog(string memory path)
        private
        view
        returns (string memory)
    {
        return vm.readFile(path);
    }

    function loadBufferFromRawJson(bytes memory data, string memory rawJson)
        private
        pure
    {
        bytes memory raw = vm.parseJsonTypeArray(
            rawJson, ".accesses", RAW_ACCESS_TYPE_DESCRIPTION
        );
        RawAccess[] memory rawAccesses = abi.decode(raw, (RawAccess[]));
        assertEq(rawAccesses.length, 1, "should be only 1 access in reset");

        RawAccess memory a = rawAccesses[0];
        if (keccak256(bytes(a.accessType)) == keccak256(bytes("read"))) {
            revert("should'nt have read access in reset");
        }
        assertEq(
            a.accessAddress,
            EmulatorConstants.UARCH_STATE_START_ADDRESS,
            "position should be (0x400000)"
        );
        assertEq(
            a.log2_size,
            EmulatorConstants.UARCH_STATE_LOG2_SIZE,
            "log2Size should be 22"
        );

        Buffer.Context memory buffer = Buffer.Context(data, 0);
        _fillBufferFromRawAccesses(rawAccesses, buffer, siblingsLength);
    }
}
