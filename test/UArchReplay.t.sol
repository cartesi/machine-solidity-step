// Copyright 2023 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "forge-std/StdJson.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";
import "contracts/UArchState.sol";
import "contracts/UArchStep.sol";
import "contracts/interfaces/IUArchStep.sol";
import "contracts/interfaces/IMemoryAccessLog.sol";

contract UArchReplayTest is Test {
    using stdJson for string;

    // configure the tests
    string constant JSON_PATH = "./test/uarch-log/";
    string constant CATALOG_PATH = "catalog.json";

    UArchState state;
    IUArchStep step;

    struct Entry {
        string path;
        bool proof;
        uint256 steps;
    }

    struct RawAccess {
        uint256 position;
        RawProof rawProof;
        string accessType;
        string val;
    }

    struct RawProof {
        uint256 log2Root;
        uint256 log2Target;
        string rootHash;
        string[] rawSiblings;
        uint256 targetPosition;
        string targetHash;
    }

    struct Proof {
        bytes32 targetHash;
        bytes32[] siblings;
    }

    function setUp() public {
        state = new UArchState();
        step = new UArchStep();
    }

    function testReplayLogs() public {
        Entry[] memory catalog = loadCatalog(
            string.concat(JSON_PATH, CATALOG_PATH)
        );

        // all tests combined can easily run out of gas, stop metering
        // also raise memory_limit in foundry.toml per https://github.com/foundry-rs/foundry/issues/3971
        vm.pauseGasMetering();

        for (uint256 i = 0; i < catalog.length; i++) {
            console.log("Replaying file %s ...", catalog[i].path);
            string memory rj = loadJsonLog(
                string.concat(JSON_PATH, catalog[i].path)
            );
            for (uint256 j = 0; j < catalog[i].steps; j++) {
                console.log("Replaying step %d ...", j);
                // load json log
                (
                    RawAccess[] memory rawAccesses,
                    IMemoryAccessLog.Access[] memory accesses,
                    bytes32[][] memory proofs,
                    bytes32[] memory oldHashes
                ) = fromRawArray(rj, j);

                IMemoryAccessLog.AccessLogs memory accessLogs = IMemoryAccessLog
                    .AccessLogs(accesses, 0);
                IUArchState.State memory s = IUArchState.State(
                    state,
                    accessLogs,
                    vm.parseBytes32(
                        string.concat("0x", rawAccesses[0].rawProof.rootHash)
                    ),
                    oldHashes,
                    proofs,
                    0
                );
                step.step(s);
            }
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

    function loadJsonLog(
        string memory path
    ) private view returns (string memory) {
        return vm.readFile(path);
    }

    function fromRawArray(
        string memory rawJson,
        uint256 stepIndex
    )
        private
        pure
        returns (
            RawAccess[] memory,
            IMemoryAccessLog.Access[] memory,
            bytes32[][] memory,
            bytes32[] memory
        )
    {
        string memory key = string.concat(
            string.concat(".steps[", vm.toString(stepIndex)),
            "].accesses"
        );
        bytes memory raw = rawJson.parseRaw(key);
        RawAccess[] memory rawAccesses = abi.decode(raw, (RawAccess[]));

        uint256 arrayLength = rawAccesses.length;
        IMemoryAccessLog.Access[]
            memory accesses = new IMemoryAccessLog.Access[](arrayLength);
        uint256 writeCount;
        bytes32[][] memory proofs = new bytes32[][](arrayLength);

        for (uint256 i = 0; i < arrayLength; i++) {
            accesses[i].val = bytes8(
                vm.parseBytes32(string.concat("0x", rawAccesses[i].val))
            );
            accesses[i].position = uint64(rawAccesses[i].position);
            if (
                keccak256(abi.encodePacked(rawAccesses[i].accessType)) ==
                keccak256(abi.encodePacked("write"))
            ) {
                writeCount++;
            }

            uint256 siblingsLength = rawAccesses[i].rawProof.rawSiblings.length;
            proofs[i] = new bytes32[](siblingsLength);

            for (uint256 j = 0; j < siblingsLength; j++) {
                // proofs should be loaded in reverse order
                proofs[i][siblingsLength - j - 1] = vm.parseBytes32(
                    string.concat("0x", rawAccesses[i].rawProof.rawSiblings[j])
                );
            }
        }

        bytes32[] memory oldHashes = new bytes32[](writeCount);
        writeCount = 0;

        for (uint256 i = 0; i < arrayLength; i++) {
            if (
                keccak256(abi.encodePacked(rawAccesses[i].accessType)) ==
                keccak256(abi.encodePacked("write"))
            ) {
                oldHashes[writeCount] = vm.parseBytes32(
                    string.concat("0x", rawAccesses[i].rawProof.targetHash)
                );
                writeCount++;
            }
        }

        return (rawAccesses, accesses, proofs, oldHashes);
    }
}
