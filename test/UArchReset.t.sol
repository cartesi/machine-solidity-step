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
pragma solidity ^0.8.0;

import "forge-std/StdJson.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";

import "src/UArchConstants.sol";
import "src/UArchReset.sol";
import "./BufferAux.sol";

contract UArchReset_Test is Test {
    using Buffer for Buffer.Context;
    using BufferAux for Buffer.Context;
    using stdJson for string;

    // configure the tests
    string constant JSON_PATH = "./test/uarch-log/";
    string constant CATALOG_PATH = "catalog.json";
    string constant RESET_PATH = "uarch-reset-steps.json";

    uint256 constant siblingsLength = 42;

    struct Entry {
        string binaryFilename;
        string finalRootHash;
        string initialRootHash;
        string logFilename;
        bool proof;
        uint256 proofsFrequency;
        uint256 steps;
    }

    struct RawAccess {
        uint256 addressAccess;
        uint256 log2_size;
        string read_hash;
        string read_value;
        string[] sibling_hashes;
        string typeAccess;
        string written_hash;
    }
    // string val; omit val because it's not used in reset

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
                    != keccak256(abi.encodePacked("uarch-reset-steps.json"))
            ) {
                continue;
            }
            console.log("Replaying log file %s ...", catalog[i].logFilename);
            require(
                catalog[i].proofsFrequency == 1, "require proof in every step"
            );

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
        bytes memory raw = json.parseRaw("");
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
    {
        string memory key = ".accesses";
        bytes memory raw = rawJson.parseRaw(key);
        RawAccess[] memory rawAccesses = abi.decode(raw, (RawAccess[]));
        uint256 arrayLength = rawAccesses.length;
        assertEq(arrayLength, 1, "should be only 1 access in reset");

        Buffer.Context memory buffer = Buffer.Context(data, 0);

        if (
            keccak256(abi.encodePacked(rawAccesses[0].typeAccess))
                == keccak256(abi.encodePacked("read"))
        ) {
            revert("should'nt have read access in reset");
        }
        assertEq(
            rawAccesses[0].addressAccess,
            UArchConstants.RESET_POSITION,
            "position should be (0x400000)"
        );
        assertEq(
            rawAccesses[0].log2_size,
            UArchConstants.RESET_ALIGNED_SIZE,
            "log2Size should be 22"
        );

        buffer.writeBytes32(
            vm.parseBytes32(string.concat("0x", rawAccesses[0].read_hash))
        );

        for (uint256 i = 0; i < siblingsLength; i++) {
            buffer.writeBytes32(
                vm.parseBytes32(
                    string.concat("0x", rawAccesses[0].sibling_hashes[i])
                )
            );
        }
    }
}
