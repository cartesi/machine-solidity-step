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

import "contracts/Memory.sol";
import "contracts/UArchConstants.sol";

///@dev This library mocks the `contracts/AccessLogs.sol` yet with a very different implementation.
/// `bytes32[] hashes` simulates the memory space with two separate regions.
/// The first 9 `bytes32` represents register space 0x320 - 0x440, where 0x438 is UX31, and 0x440 should never be accessed
/// Starting from the 10th `bytes32`, it represents memory space 0x70000000 -

library AccessLogs {
    struct Context {
        bytes32 currentRootHash;
        bytes32[] hashes;
        uint64[] words;
        uint128 currentHashIndex;
        uint128 currentWord;
    }

    function readWord(
        AccessLogs.Context memory a,
        Memory.PhysicalAddress readAddress
    ) internal pure returns (uint64) {
        (bytes8 val, , ) = accessWord(a, readAddress);
        return uint64SwapEndian(uint64(val));
    }

    function writeWord(
        AccessLogs.Context memory a,
        Memory.PhysicalAddress writeAddress,
        uint64 val
    ) internal pure {
        (, uint64 index, uint8 offset) = accessWord(a, writeAddress);
        bytes8 bytesValue = bytes8(uint64SwapEndian(val));
        a.hashes[index] =
            a.hashes[index] &
            ~(bytes32(
                0xffffffffffffffff000000000000000000000000000000000000000000000000
            ) >> (offset * 8 * 8));
        a.hashes[index] =
            a.hashes[index] |
            (bytes32(bytesValue) >> (offset * 8 * 8));
    }

    function writeRegion(
        AccessLogs.Context memory a,
        Memory.Region memory region,
        bytes32 newHash
    ) internal pure {}

    /// @notice Swap byte order of unsigned ints with 64 bytes
    /// @param num number to have bytes swapped
    function uint64SwapEndian(uint64 num) internal pure returns (uint64) {
        uint64 output = ((num & 0x00000000000000ff) << 56) |
            ((num & 0x000000000000ff00) << 40) |
            ((num & 0x0000000000ff0000) << 24) |
            ((num & 0x00000000ff000000) << 8) |
            ((num & 0x000000ff00000000) >> 8) |
            ((num & 0x0000ff0000000000) >> 24) |
            ((num & 0x00ff000000000000) >> 40) |
            ((num & 0xff00000000000000) >> 56);

        return output;
    }

    function accessWord(
        AccessLogs.Context memory a,
        Memory.PhysicalAddress paddr
    ) private pure returns (bytes8 val, uint64 index, uint8 offset) {
        uint64 position = Memory.PhysicalAddress.unwrap(paddr);
        uint64 distance;
        if (
            position >= UArchConstants.UCYCLE &&
            position <= UArchConstants.UX0 + (31 << 3)
        ) {
            // takes the first 9 slots
            distance = (position - UArchConstants.UCYCLE) / 8;
        } else if (position >= 0x70000000) {
            // takes slots from 10th
            distance = (position - 0x70000000 + 9 * 32) / 8;
        } else {
            revert("invalid memory access");
        }
        index = distance / 4;
        offset = uint8(distance % 4);
        val = bytes8(a.hashes[index] << (offset * 8 * 8));
    }
}
