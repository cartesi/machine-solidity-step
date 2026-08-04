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

    uint256 constant siblingsLength = 42;

    struct Entry {
        string binaryFilename;
        string finalRootHash;
        string initialRootHash;
        string logFilename;
        uint256 steps;
    }

    string constant ENTRY_TYPE_DESCRIPTION =
        "CatalogEntryJson(string binaryFilename,string finalRootHash,string initialRootHash,string logFilename,uint256 steps)";

    function testReset() public {
        Entry[] memory catalog =
            loadCatalog(string.concat(JSON_PATH, CATALOG_PATH));

        // all tests combined can easily run out of gas, stop metering
        // also raise memory_limit in foundry.toml per https://github.com/foundry-rs/foundry/issues/3971
        vm.pauseGasMetering();
        // create a large buffer and reuse it
        bytes memory buffer = new bytes(100 * (siblingsLength + 1) * 32);
        // count the fixtures replayed below, so a missing entry fails loudly
        uint256 found = 0;

        for (uint256 i = 0; i < catalog.length; i++) {
            // run the plain reset log, the rejected-input log (whose final
            // root hash is the recorded revert root hash), and the
            // accepted-input log (which reads the manual yield but does not
            // revert, so its final root hash is the post-reset root)
            if (
                keccak256(abi.encodePacked(catalog[i].logFilename))
                        != keccak256(abi.encodePacked("reset-uarch-steps.json"))
                    && keccak256(abi.encodePacked(catalog[i].logFilename))
                        != keccak256(
                            abi.encodePacked("reset-uarch-rejected-steps.json")
                        )
                    && keccak256(abi.encodePacked(catalog[i].logFilename))
                        != keccak256(
                            abi.encodePacked("reset-uarch-accepted-steps.json")
                        )
            ) {
                continue;
            }
            found++;
            console.log("Replaying log file %s ...", catalog[i].logFilename);

            string memory rj =
                loadJsonLog(string.concat(JSON_PATH, catalog[i].logFilename));

            bytes32 initialRootHash =
                vm.parseBytes32(catalog[i].initialRootHash);
            bytes32 finalRootHash = vm.parseBytes32(catalog[i].finalRootHash);

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
        assertEq(
            found,
            3,
            "catalog is missing one of the reset-uarch-{steps,rejected-steps,accepted-steps}.json entries"
        );
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
        Buffer.Context memory buffer = Buffer.Context(data, 0);
        _fillBufferFromRawAccesses(rawAccesses, buffer);
    }
}
