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

import "src/AccessLogs.sol";
import "./BufferAux.sol";

pragma solidity ^0.8.0;

library ExternalAccessLogs {
    function readWord(
        AccessLogs.Context memory a,
        Memory.PhysicalAddress readAddress
    ) external pure returns (uint64) {
        return AccessLogs.readWord(a, readAddress);
    }

    function writeWord(
        AccessLogs.Context memory a,
        Memory.PhysicalAddress writeAddress,
        uint64 newValue
    ) external pure {
        AccessLogs.writeWord(a, writeAddress, newValue);
    }
}

contract AccessLogsTest is Test {
    using AccessLogs for AccessLogs.Context;
    using AccessLogs for bytes8;
    using Buffer for Buffer.Context;
    using BufferAux for Buffer.Context;
    using Memory for uint64;

    uint64 position = 800; // position of the word being tested
    bytes8 initialWordAtPosition; // bytes of the word at position
    bytes32 initialReadLeaf; // leaf containing the word at position
    bytes32[] siblingHashes; // siblings of the leaf containing position

    function setUp() public {
        initialWordAtPosition = bytes8(0x0000000000000001).swapEndian();
        initialReadLeaf = patchLeaf(
            bytes32(type(uint256).max), initialWordAtPosition, position
        );
        for (uint256 i = 0; i < 59; i++) {
            siblingHashes.push(keccak256(abi.encodePacked(bytes8(uint64(i)))));
        }
    }

    function verifyWord(bytes32 h, uint64 p, uint64 w) internal {
        (Buffer.Context memory buffer,) =
            makeReadBuffer(bytes8(w).swapEndian(), false);
        AccessLogs.Context memory accessLogs = AccessLogs.Context(h, buffer);
        assertEq(accessLogs.readWord(p.toPhysicalAddress()), w);
    }

    function testReadWordHappyPath() public {
        (Buffer.Context memory buffer, bytes32 rootHash) = makeReadBuffer(
            bytes8(0x0000000000000001).swapEndian(),
            /*withReadValueMismatch=*/
            false
        );
        AccessLogs.Context memory accessLogs =
            AccessLogs.Context(rootHash, buffer);
        assertEq(accessLogs.readWord(position.toPhysicalAddress()), 1);
    }

    function testReadWordBadRegion() public {
        (Buffer.Context memory buffer, bytes32 rootHash) = makeReadBuffer(
            bytes8(0x0000000000000001).swapEndian(),
            /*withReadValueMismatch=*/
            false
        );
        AccessLogs.Context memory accessLogs =
            AccessLogs.Context(rootHash, buffer);
        vm.expectRevert("Read word root doesn't match");
        ExternalAccessLogs.readWord(
            accessLogs, (position + 32).toPhysicalAddress()
        );
    }

    function testReadWordWrongValue() public {
        (Buffer.Context memory buffer, bytes32 rootHash) = makeReadBuffer(
            bytes8(0x0000000000000001).swapEndian(),
            /*withReadValueMismatch=*/
            true
        );
        AccessLogs.Context memory accessLogs =
            AccessLogs.Context(rootHash, buffer);
        vm.expectRevert("Read word root doesn't match");
        ExternalAccessLogs.readWord(accessLogs, position.toPhysicalAddress());
    }

    function testWriteWordHappyPath() public {
        uint64 wordWritten = 3;
        (Buffer.Context memory buffer, bytes32 rootHash) = makeWriteBuffer(
            initialReadLeaf,
            // bytes8(wordWritten).swapEndian(),
            /* withReadValueMismatch= */
            false
        );
        AccessLogs.Context memory accessLogs =
            AccessLogs.Context(rootHash, buffer);
        accessLogs.writeWord(position.toPhysicalAddress(), wordWritten);
        verifyWord(accessLogs.currentRootHash, position, wordWritten);
    }

    function testWriteWordBadRegion() public {
        uint64 wordWritten = 3;
        (Buffer.Context memory buffer, bytes32 rootHash) = makeWriteBuffer(
            initialReadLeaf,
            /* withReadValueMismatch= */
            false
        );
        AccessLogs.Context memory accessLogs =
            AccessLogs.Context(rootHash, buffer);
        vm.expectRevert("Write word root doesn't match");
        ExternalAccessLogs.writeWord(
            accessLogs, (position + 32).toPhysicalAddress(), wordWritten
        );
    }

    function testWriteWordReadMismatch() public {
        uint64 wordWritten = 3;
        (Buffer.Context memory buffer, bytes32 rootHash) = makeWriteBuffer(
            initialReadLeaf,
            // bytes8(wordWritten).swapEndian(),
            /* withReadValueMismatch= */
            true
        );
        AccessLogs.Context memory accessLogs =
            AccessLogs.Context(rootHash, buffer);
        vm.expectRevert("Write word root doesn't match");
        ExternalAccessLogs.writeWord(
            accessLogs, position.toPhysicalAddress(), wordWritten
        );
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

    function makeLeaf(bytes8 word, uint64 wordPosition)
        public
        view
        returns (bytes32)
    {
        uint64 leafPosition = wordPosition & ~uint64(31);
        uint64 offset = position - leafPosition;
        bytes32 leaf = bytes32(word) >> (offset << Memory.LOG2_WORD);
        return leaf;
    }

    function patchLeaf(bytes32 currentLeaf, bytes8 newWord, uint64 wordPosition)
        public
        view
        returns (bytes32)
    {
        uint64 leafPosition = wordPosition & ~uint64(31);
        uint64 offset = position - leafPosition;

        bytes32 erase_mask = bytes32(bytes8(type(uint64).max));
        erase_mask = erase_mask >> (offset << Memory.LOG2_WORD);
        erase_mask = ~erase_mask;

        bytes32 result = currentLeaf & erase_mask;
        result = result | (bytes32(newWord) >> (offset << Memory.LOG2_WORD));
        return result;
    }

    function makeReadBuffer(bytes8 readWord, bool withReadValueMismatch)
        private
        view
        returns (Buffer.Context memory, bytes32)
    {
        Buffer.Context memory buffer =
            Buffer.Context(new bytes((59 << Memory.LOG2_LEAF) + 32 + 32), 0);
        bytes32 readData = patchLeaf(initialReadLeaf, readWord, position);

        // write leaf data, leaf hash and sibling hashes
        buffer.writeBytes32(readData);
        bytes32 readHash = keccak256(abi.encodePacked(readData));
        if (withReadValueMismatch) {
            readHash = keccak256(abi.encodePacked(bytes8(readHash)));
        }

        for (uint256 i = 0; i < 59; i++) {
            buffer.writeBytes32(siblingHashes[i]);
        }
        // compute root hash and rewind buffer
        buffer.offset = 0;
        bytes32 rootHash = bubbleHashUp(readHash);
        return (buffer, rootHash);
    }

    function makeWriteBuffer(bytes32 readLeaf, bool withReadValueMismatch)
        private
        view
        returns (Buffer.Context memory, bytes32)
    {
        Buffer.Context memory buffer = Buffer.Context(
            new bytes((59 << Memory.LOG2_LEAF) + 32 + 32 + 32), 0
        );

        // write leaf data, leaf hash and sibling hashes
        buffer.writeBytes32(readLeaf);
        bytes32 readHash = keccak256(abi.encodePacked(readLeaf));
        if (withReadValueMismatch) {
            readHash = keccak256(abi.encodePacked(bytes8(readHash)));
        }

        for (uint256 i = 0; i < 59; i++) {
            buffer.writeBytes32(siblingHashes[i]);
        }

        // compute root hash and rewind buffer
        bytes32 rootHash = bubbleHashUp(readHash);
        buffer.offset = 0;
        return (buffer, rootHash);
    }

    function bubbleHashUp(bytes32 hash) private view returns (bytes32) {
        uint64 addr = position >> Memory.LOG2_LEAF;
        for (uint256 i = 0; i < 59; i++) {
            if (addr & 1 == 0) {
                hash = keccak256(abi.encodePacked(hash, siblingHashes[i]));
            } else {
                hash = keccak256(abi.encodePacked(siblingHashes[i], hash));
            }
            addr = addr >> 1;
        }
        return hash;
    }
}
