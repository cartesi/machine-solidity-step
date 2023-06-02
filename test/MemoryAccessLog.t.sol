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
import "contracts/Merkle.sol";
import "contracts/MemoryAccessLog.sol";
import "contracts/UArchCompat.sol";
import "contracts/interfaces/IMemoryAccessLog.sol";

pragma solidity ^0.8.0;

contract MemoryAccessLogTest is Test {
    using MemoryAccessLog for IMemoryAccessLog.AccessLogs;

    bytes32[] siblings;
    bytes32 rootHash;
    uint64 position = 800;

    function setUp() public {
        siblings.push(keccak256(abi.encodePacked(bytes8(0))));
        for (uint256 i = 1; i < 61; i++) {
            siblings.push(
                keccak256(abi.encodePacked(siblings[i - 1], siblings[i - 1]))
            );
        }
        rootHash = keccak256(abi.encodePacked(siblings[60], siblings[60]));
    }

    function testReadWord() public {
        IMemoryAccessLog.Access[]
            memory accesses = new IMemoryAccessLog.Access[](1);
        accesses[0] = IMemoryAccessLog.Access(position, 0);
        IMemoryAccessLog.AccessLogs memory accessLogs = IMemoryAccessLog
            .AccessLogs(accesses, 0);

        // generate proper proofs
        bytes32[][] memory proofs = new bytes32[][](1);
        proofs[0] = siblings;

        vm.expectRevert("Read machine hash doesn't match");
        accessLogs.readWord(bytes32(0), proofs, position);

        assertEq(
            accessLogs.readWord(rootHash, proofs, position),
            0,
            "readWord value doesn't match"
        );

        vm.expectRevert("Position and access address mismatch");
        accessLogs.readWord(rootHash, proofs, position + 1);

        accessLogs = IMemoryAccessLog.AccessLogs(accesses, 1);
        vm.expectRevert("Too many accesses");
        accessLogs.readWord(rootHash, proofs, position);
    }

    function testWriteWord() public {
        IMemoryAccessLog.Access[]
            memory accesses = new IMemoryAccessLog.Access[](1);
        uint64 valueWritten = 1;
        bytes8 bytes8ValueWritten = bytes8(
            UArchCompat.uint64SwapEndian(valueWritten)
        );
        accesses[0] = IMemoryAccessLog.Access(position, bytes8ValueWritten);
        IMemoryAccessLog.AccessLogs memory accessLogs = IMemoryAccessLog
            .AccessLogs(accesses, 0);

        // generate proper proofs
        bytes32[][] memory proofs = new bytes32[][](1);
        bytes32[] memory oldHashes = new bytes32[](1);
        proofs[0] = siblings;
        oldHashes[0] = siblings[0];

        vm.expectRevert("Write machine hash doesn't match");
        accessLogs.writeWord(
            bytes32(0),
            oldHashes,
            proofs,
            0,
            position,
            valueWritten
        );

        // write should succeed
        bytes32 newMachineHash = accessLogs.writeWord(
            rootHash,
            oldHashes,
            proofs,
            0,
            position,
            valueWritten
        );

        assertEq(
            newMachineHash,
            Merkle.getRootWithValue(position, bytes8ValueWritten, siblings),
            "machine hash should match after value written"
        );

        // write should fail
        vm.expectRevert(bytes("Written value mismatch"));
        accessLogs.writeWord(
            rootHash,
            oldHashes,
            proofs,
            0,
            position,
            valueWritten + 1
        );
    }
}
