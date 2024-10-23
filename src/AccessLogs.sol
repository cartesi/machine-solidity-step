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

/// @dev This file is generated from templates/AccessLogs.sol.template, one should not modify the content directly

pragma solidity ^0.8.0;

import "./Buffer.sol";
import "./EmulatorConstants.sol";

library AccessLogs {
    using Buffer for Buffer.Context;
    using Memory for Memory.AlignedSize;
    using Memory for Memory.PhysicalAddress;

    struct Context {
        bytes32 currentRootHash;
        Buffer.Context buffer;
    }

    function machineWordToSolidityUint64(bytes8 word)
        internal
        pure
        returns (uint64)
    {
        return uint64(swapEndian(word));
    }

    function solidityUint64ToMachineWord(uint64 val)
        internal
        pure
        returns (bytes8)
    {
        return swapEndian(bytes8(val));
    }

    /// @notice Swap byte order of unsigned ints with 64 bits
    /// @param end1 bytes8 to have bytes swapped
    function swapEndian(bytes8 end1) internal pure returns (bytes8) {
        bytes8 end2 = ((end1 & 0x00000000000000ff) << 56)
            | ((end1 & 0x000000000000ff00) << 40)
            | ((end1 & 0x0000000000ff0000) << 24)
            | ((end1 & 0x00000000ff000000) << 8)
            | ((end1 & 0x000000ff00000000) >> 8)
            | ((end1 & 0x0000ff0000000000) >> 24)
            | ((end1 & 0x00ff000000000000) >> 40)
            | ((end1 & 0xff00000000000000) >> 56);

        return end2;
    }

    /// @dev bytes buffer layout is the same for `readWord` and `writeWord`,
    /// [32 bytes as read data], [59 * 32 bytes as sibling hashes]

    //
    // Read methods
    //
    function readRegion(
        AccessLogs.Context memory a,
        Memory.Region memory region
    ) internal pure returns (bytes32) {
        bytes32 drive = a.buffer.consumeBytes32();
        bytes32 rootHash = a.buffer.getRoot(region, drive);

        require(a.currentRootHash == rootHash, "Read region root doesn't match");

        return drive;
    }

    function readLeaf(AccessLogs.Context memory a, Memory.Stride readStride)
        internal
        pure
        returns (bytes32)
    {
        Memory.Region memory r =
            Memory.regionFromStride(readStride, Memory.alignedSizeFromLog2(0));
        return readRegion(a, r);
    }

    function readWord(
        AccessLogs.Context memory a,
        Memory.PhysicalAddress readAddress
    ) internal pure returns (uint64) {
        (Memory.PhysicalAddress leafAddress, uint64 wordOffset) =
            readAddress.truncateToLeaf();

        Memory.Region memory region = Memory.regionFromStride(
            Memory.strideFromLeafAddress(leafAddress),
            Memory.alignedSizeFromLog2(0)
        );

        bytes32 leaf = a.buffer.consumeBytes32();
        bytes32 rootHash =
            a.buffer.getRoot(region, keccak256(abi.encodePacked(leaf)));
        require(a.currentRootHash == rootHash, "Read word root doesn't match");

        bytes8 word = getBytes8FromBytes32AtOffset(leaf, wordOffset);
        return machineWordToSolidityUint64(word);
    }

    //
    // Write methods
    //
    function writeRegion(
        AccessLogs.Context memory a,
        Memory.Region memory region,
        bytes32 newHash
    ) internal pure {
        bytes32 oldDrive = a.buffer.consumeBytes32();
        (bytes32 rootHash,) = a.buffer.peekRoot(region, oldDrive);

        require(
            a.currentRootHash == rootHash, "Write region root doesn't match"
        );

        bytes32 newRootHash = a.buffer.getRoot(region, newHash);

        a.currentRootHash = newRootHash;
    }

    function writeLeaf(
        AccessLogs.Context memory a,
        Memory.Stride writeStride,
        bytes32 newHash
    ) internal pure {
        Memory.Region memory r =
            Memory.regionFromStride(writeStride, Memory.alignedSizeFromLog2(0));
        writeRegion(a, r, newHash);
    }

    function writeWord(
        AccessLogs.Context memory a,
        Memory.PhysicalAddress writeAddress,
        uint64 newValue
    ) internal pure {
        (Memory.PhysicalAddress leafAddress, uint64 wordOffset) =
            writeAddress.truncateToLeaf();

        Memory.Region memory region = Memory.regionFromStride(
            Memory.strideFromLeafAddress(leafAddress),
            Memory.alignedSizeFromLog2(0)
        );

        bytes32 oldLeaf = a.buffer.consumeBytes32();
        (bytes32 rootHash,) =
            a.buffer.peekRoot(region, keccak256(abi.encodePacked(oldLeaf)));

        require(a.currentRootHash == rootHash, "Write word root doesn't match");

        bytes32 newLeaf = setBytes8ToBytes32AtOffset(
            solidityUint64ToMachineWord(newValue), oldLeaf, wordOffset
        );

        bytes32 newRootHash =
            a.buffer.getRoot(region, keccak256(abi.encodePacked(newLeaf)));
        a.currentRootHash = newRootHash;
    }

    function getBytes8FromBytes32AtOffset(bytes32 source, uint64 offset)
        internal
        pure
        returns (bytes8)
    {
        return bytes8(source << (offset << Memory.LOG2_WORD));
    }

    function setBytes8ToBytes32AtOffset(
        bytes8 word,
        bytes32 leaf,
        uint64 offset
    ) internal pure returns (bytes32) {
        uint256 wordOffset = offset << Memory.LOG2_WORD;
        bytes32 toWrite = bytes32(word) >> wordOffset;

        bytes32 wordMask = bytes32(~bytes8(0));
        bytes32 mask = ~(wordMask >> wordOffset);

        return (leaf & mask) | toWrite;
    }
}
