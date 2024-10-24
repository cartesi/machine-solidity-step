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

import "src/EmulatorConstants.sol";
import "src/SendCmioResponse.sol";
import "./BufferAux.sol";

contract SendCmioResponse_Test is Test {
    using Buffer for Buffer.Context;
    using BufferAux for Buffer.Context;
    using stdJson for string;

    // configure the tests
    string constant JSON_PATH = "./test/uarch-log/";
    string constant CATALOG_PATH = "catalog.json";
    string constant SEND_CMIO_RESPONSE_PATH = "send-cmio-response-steps.json";

    uint256 constant siblingsLength = 59;

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

    function testSendCmioResponse() public {
        Entry[] memory catalog =
            loadCatalog(string.concat(JSON_PATH, CATALOG_PATH));
        string memory resetLog =
            string.concat(JSON_PATH, SEND_CMIO_RESPONSE_PATH);

        // all tests combined can easily run out of gas, stop metering
        // also raise memory_limit in foundry.toml per https://github.com/foundry-rs/foundry/issues/3971
        vm.pauseGasMetering();
        // create a large buffer and reuse it
        bytes memory buffer = new bytes(100 * (siblingsLength + 1) * 32);

        for (uint256 i = 0; i < catalog.length; i++) {
            if (
                keccak256(abi.encodePacked(catalog[i].logFilename))
                    != keccak256(abi.encodePacked("send-cmio-response-steps.json"))
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

            // Prepare arguments for sendCmioResponse
            // These values are hard-coded in order to match the values used when generating the test log file
            uint16 reason = 1;
            bytes memory response = bytes("This is a test cmio response");
            require(
                response.length == 28,
                "The response data must match the hard-coded value in the test log file"
            );
            bytes memory paddedResponse = new bytes(32);
            for (uint256 j = 0; j < response.length; j++) {
                paddedResponse[j] = response[j];
            }
            bytes32 paddedResponseHash = keccak256(paddedResponse);
            // call sendCmioResponse
            SendCmioResponse.sendCmioResponse(
                accessLogs, reason, paddedResponseHash, uint32(response.length)
            );
            // ensure that the final root hash matches the expected value
            assertEq(
                accessLogs.currentRootHash,
                finalRootHash,
                "final root hash must match"
            );
        }
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
        pure
    {
        string memory key = ".accesses";
        bytes memory raw = rawJson.parseRaw(key);
        RawAccess[] memory rawAccesses = abi.decode(raw, (RawAccess[]));
        uint256 arrayLength = rawAccesses.length;

        Buffer.Context memory buffer = Buffer.Context(data, 0);

        for (uint256 i = 0; i < arrayLength; i++) {
            if (rawAccesses[i].log2_size == 3) {
                buffer.writeBytes32(
                    vm.parseBytes32(
                        string.concat("0x", rawAccesses[i].read_value)
                    )
                );
            } else {
                buffer.writeBytes32(
                    vm.parseBytes32(
                        string.concat("0x", rawAccesses[i].read_hash)
                    )
                );
            }

            for (uint256 j = 0; j < rawAccesses[i].sibling_hashes.length; j++) {
                buffer.writeBytes32(
                    vm.parseBytes32(
                        string.concat("0x", rawAccesses[i].sibling_hashes[j])
                    )
                );
            }
        }
    }
}
