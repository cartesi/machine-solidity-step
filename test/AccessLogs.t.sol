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

import "contracts/AccessLogs.sol";
import "contracts/Memory.sol";

pragma solidity ^0.8.0;

contract AccessLogsTest is Test {
    using AccessLogs for AccessLogs.Context;
    using AccessLogs for uint64;
    using AccessLogs for bytes;
    using Memory for uint64;

    bytes32[] hashes;
    bytes32 rootHash;
    uint64 position = 800;

    function setUp() public {
        // the hashes include 62 elements, the hash at access position, and other 61 siblings
        // hash value at access position
        hashes.push(keccak256(abi.encodePacked(bytes8(0))));
        // direct sibling hash
        hashes.push(keccak256(abi.encodePacked(bytes8(0))));
        for (uint256 i = 2; i < 62; i++) {
            hashes.push(
                keccak256(abi.encodePacked(hashes[i - 1], hashes[i - 1]))
            );
        }
        rootHash = keccak256(abi.encodePacked(hashes[61], hashes[61]));
    }

    function testReadWord() public {
        AccessLogs.Context memory accessLogs = AccessLogs.Context(
            rootHash,
            readBufferFromHashes(bytes32(bytes8(uint64(1).uint64SwapEndian()))),
            0
        );

        vm.expectRevert("Read value doesn't match");
        accessLogs.readWord(position.toPhysicalAddress());

        vm.expectRevert("Read region root doesn't match");
        accessLogs.readWord((position + 1).toPhysicalAddress());

        accessLogs =
            AccessLogs.Context(rootHash, readBufferFromHashes(bytes32(0)), 0);
        accessLogs.readWord(position.toPhysicalAddress());
    }

    function testWriteWord() public {
        hashes[0] =
            (keccak256(abi.encodePacked(bytes8(uint64(1).uint64SwapEndian()))));
        AccessLogs.Context memory accessLogs =
            AccessLogs.Context(rootHash, writeBufferFromHashes(), 0);
        uint64 valueWritten = 1;

        vm.expectRevert("Write region root doesn't match");
        accessLogs.writeWord(position.toPhysicalAddress(), valueWritten);

        hashes[0] = (keccak256(abi.encodePacked(bytes8(0))));
        accessLogs = AccessLogs.Context(rootHash, writeBufferFromHashes(), 0);
        vm.expectRevert("Write region root doesn't match");
        accessLogs.writeWord((position + 1).toPhysicalAddress(), valueWritten);

        // write should succeed
        accessLogs.writeWord(position.toPhysicalAddress(), valueWritten);
    }

    function testEndianSwap() public {
        assertEq(AccessLogs.uint64SwapEndian(0x8000), 0x0080000000000000);
        assertEq(AccessLogs.uint64SwapEndian(0x70000000), 0x0000007000000000);
        assertEq(AccessLogs.uint64SwapEndian(0x0080000000000000), 0x8000);
        assertEq(AccessLogs.uint64SwapEndian(0x0000007000000000), 0x70000000);
    }

    function readBufferFromHashes(bytes32 word)
        private
        view
        returns (bytes memory)
    {
        bytes memory buffer = new bytes(62 * 32 + 8);
        uint128 pointer = 0;
        buffer.writeBytes32(pointer, word);
        pointer += 8;

        for (uint256 i = 0; i < 62; i++) {
            buffer.writeBytes32(pointer, hashes[i]);
            pointer += 32;
        }

        return buffer;
    }

    function writeBufferFromHashes() private view returns (bytes memory) {
        bytes memory buffer = new bytes(62 * 32);
        uint128 pointer = 0;

        for (uint256 i = 0; i < 62; i++) {
            buffer.writeBytes32(pointer, hashes[i]);
            pointer += 32;
        }

        return buffer;
    }
}
