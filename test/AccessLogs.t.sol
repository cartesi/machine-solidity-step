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

import "ready_src/AccessLogs.sol";
import "./BufferAux.sol";

pragma solidity ^0.8.0;

contract AccessLogsTest is Test {
    using AccessLogs for AccessLogs.Context;
    using AccessLogs for bytes8;
    using Buffer for Buffer.Context;
    using BufferAux for Buffer.Context;
    using Memory for uint64;

    bytes32[] hashes;
    bytes32 rootHash;
    uint64 position = 800;

    function setUp() public {
        // the hashes include 62 elements, the hash at access position, and other 61 siblings
        // hash value at access position
        hashes.push(
            keccak256(abi.encodePacked(bytes8(0x0000000000000001).swapEndian()))
        );
        // direct sibling hash
        hashes.push(
            keccak256(abi.encodePacked(bytes8(0x0000000000000002).swapEndian()))
        );
        for (uint256 i = 2; i < 62; i++) {
            hashes.push(
                keccak256(abi.encodePacked(hashes[i - 1], hashes[i - 2]))
            );
        }
        rootHash = rootFromHashes(hashes[0]);
    }

    function testReadWord() public {
        AccessLogs.Context memory accessLogs = AccessLogs.Context(
            rootHash,
            readBufferFromHashes(bytes8(0x0000000000000001).swapEndian())
        );

        assertEq(accessLogs.readWord(position.toPhysicalAddress()), 1);
    }

    function testReadWordRoot() public {
        AccessLogs.Context memory accessLogs = AccessLogs.Context(
            rootHash,
            readBufferFromHashes(bytes8(0x0000000000000001).swapEndian())
        );

        // loxa vm.expectRevert("Read region root doesn't match");
        accessLogs.readWord((position + 8).toPhysicalAddress());
    }

    function testReadWordValue() public {
        AccessLogs.Context memory accessLogs = AccessLogs.Context(
            rootHash,
            readBufferFromHashes(bytes8(0x0000000000000002).swapEndian())
        );

        vm.expectRevert("Read value doesn't match");
        accessLogs.readWord(position.toPhysicalAddress());
    }

    function testWriteWord() public view {
        AccessLogs.Context memory accessLogs =
            AccessLogs.Context(rootHash, writeBufferFromHashes());
        uint64 valueWritten = 1;

        // // write should succeed
        accessLogs.writeWord(position.toPhysicalAddress(), valueWritten);
    }

    function testWriteWordRootValue() public {
        hashes[0] = (
            keccak256(abi.encodePacked(bytes8(0x0000000000000002).swapEndian()))
        );
        AccessLogs.Context memory accessLogs =
            AccessLogs.Context(rootHash, writeBufferFromHashes());
        uint64 valueWritten = 1;

        vm.expectRevert("Write region root doesn't match");
        accessLogs.writeWord(position.toPhysicalAddress(), valueWritten);
    }

    function testWriteWordRootPosition() public {
        AccessLogs.Context memory accessLogs =
            AccessLogs.Context(rootHash, writeBufferFromHashes());
        uint64 valueWritten = 1;

        vm.expectRevert("Write region root doesn't match");
        accessLogs.writeWord((position + 8).toPhysicalAddress(), valueWritten);
    }

    function testEndianSwap() public {
        assertEq(
            bytes8(0x0000000000008000).swapEndian(), bytes8(0x0080000000000000)
        );
        assertEq(
            bytes8(0x0000000070000000).swapEndian(), bytes8(0x0000007000000000)
        );
        assertEq(
            bytes8(0x0080000000000000).swapEndian(), bytes8(0x0000000000008000)
        );
        assertEq(
            bytes8(0x0000007000000000).swapEndian(), bytes8(0x0000000070000000)
        );
    }

    function readBufferFromHashes(bytes8 word)
        private
        view
        returns (Buffer.Context memory)
    {
        Buffer.Context memory buffer =
            Buffer.Context(new bytes((62 << 5) + 8), 0);
        buffer.writeBytes8(word);

        for (uint256 i = 0; i < 62; i++) {
            buffer.writeBytes32(hashes[i]);
        }

        // reset offset for replay
        buffer.offset = 0;

        return buffer;
    }

    function writeBufferFromHashes()
        private
        view
        returns (Buffer.Context memory)
    {
        Buffer.Context memory buffer = Buffer.Context(new bytes(62 << 5), 0);

        for (uint256 i = 0; i < 62; i++) {
            buffer.writeBytes32(hashes[i]);
        }

        // reset offset for replay
        buffer.offset = 0;

        return buffer;
    }

    function rootFromHashes(bytes32 drive) private view returns (bytes32) {
        Buffer.Context memory buffer = Buffer.Context(new bytes(61 << 5), 0);

        for (uint256 i = 0; i < 61; i++) {
            buffer.writeBytes32(hashes[i + 1]);
        }

        // reset offset for replay
        buffer.offset = 0;
        (bytes32 root,) = buffer.peekRoot(
            Memory.regionFromStride(
                Memory.strideFromWordAddress(position.toPhysicalAddress()),
                Memory.alignedSizeFromLog2(0)
            ),
            drive
        );

        return root;
    }
}
