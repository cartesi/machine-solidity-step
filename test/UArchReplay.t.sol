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
    string constant JSON_PATH = "./test/uarch-steps/";
    string constant CATALOG_PATH = "catalog.json";

    UArchState state;
    IUArchStep step;

    struct Catalog {
        string path;
        uint256 steps;
    }

    struct RawAccess {
        uint256 position;
        string accessType;
        string val;
    }

    function setUp() public {
        state = new UArchState();
        step = new UArchStep();
    }

    function testReplayLogs() public {
        Catalog[] memory catalog = loadCatalog(
            string.concat(JSON_PATH, CATALOG_PATH)
        );

        for (uint i = 0; i < catalog.length; i++) {
            console.log("Replaying file %s ...", catalog[i].path);
            // load json log
            IMemoryAccessLog.Access[] memory accesses = loadJsonLog(
                string.concat(JSON_PATH, catalog[i].path)
            );
            IMemoryAccessLog.AccessLogs memory accessLogs = IMemoryAccessLog
                .AccessLogs(accesses, 0);
            IUArchState.State memory s = IUArchState.State(
                address(state),
                accessLogs
            );
            step.step(s);
        }
    }

    function loadCatalog(
        string memory path
    ) private view returns (Catalog[] memory) {
        string memory json = vm.readFile(path);
        bytes memory raw = json.parseRaw("");
        Catalog[] memory catalog = abi.decode(raw, (Catalog[]));

        return catalog;
    }

    function loadJsonLog(
        string memory path
    ) private view returns (IMemoryAccessLog.Access[] memory) {
        string memory json = vm.readFile(path);
        bytes memory raw = json.parseRaw("");
        RawAccess[] memory ra = abi.decode(raw, (RawAccess[]));

        return fromRawArray(ra);
    }

    function fromRawArray(
        RawAccess[] memory rawAccesses
    ) private pure returns (IMemoryAccessLog.Access[] memory) {
        uint arrayLength = rawAccesses.length;
        IMemoryAccessLog.Access[]
            memory accesses = new IMemoryAccessLog.Access[](arrayLength);

        for (uint i = 0; i < arrayLength; i++) {
            accesses[i].val = bytes8(
                vm.parseBytes32(string.concat("0x", rawAccesses[i].val))
            );
            accesses[i].position = uint64(rawAccesses[i].position);
            accesses[i].accessType = (keccak256(
                abi.encodePacked(rawAccesses[i].accessType)
            ) == keccak256(abi.encodePacked("read")))
                ? IMemoryAccessLog.AccessType.Read
                : IMemoryAccessLog.AccessType.Write;
        }

        return accesses;
    }
}
