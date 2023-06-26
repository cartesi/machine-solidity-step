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
/// `bytes buffer` simulates the memory space with two separate regions.
/// The first 280 bytes are reserved for register space: 0x320 - 0x438 (35 * 8)
/// Following next will be continuous memory space: 0x70000000 -

library AccessLogs {
    using AccessLogs for bytes;

    struct Context {
        bytes32 currentRootHash;
        bytes buffer;
        uint128 pointer;
    }

    function readWord(
        AccessLogs.Context memory a,
        Memory.PhysicalAddress readAddress
    ) internal pure returns (uint64) {
        (bytes32 val, ) = accessWord(a, readAddress);
        return uint64SwapEndian(uint64(bytes8(val)));
    }

    function writeWord(
        AccessLogs.Context memory a,
        Memory.PhysicalAddress writeAddress,
        uint64 val
    ) internal pure {
        (bytes32 bytes32Value, uint128 index) = accessWord(a, writeAddress);
        bytes8 bytesValue = bytes8(uint64SwapEndian(val));
        bytes32Value =
            bytes32Value &
            0x0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffff;
        bytes32Value = bytes32Value | bytes32(bytesValue);

        a.buffer.writeBytes32(index, bytes32Value);
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

    function writeBytes32(
        bytes memory data,
        uint128 offset,
        bytes32 val
    ) internal pure {
        assembly {
            mstore(add(data, add(offset, 32)), val)
        }
    }

    function toBytes32(
        bytes memory data,
        uint128 offset
    ) internal pure returns (bytes32) {
        bytes32 temp;
        // Get 32 bytes from data
        assembly {
            temp := mload(add(data, add(offset, 32)))
        }
        return temp;
    }

    function accessWord(
        AccessLogs.Context memory a,
        Memory.PhysicalAddress paddr
    ) private pure returns (bytes32 val, uint128 index) {
        uint64 position = Memory.PhysicalAddress.unwrap(paddr);
        if (
            position >= UArchConstants.UCYCLE &&
            position <= UArchConstants.UX0 + (31 << 3)
        ) {
            index = (position - UArchConstants.UCYCLE);
        } else if (position >= 0x70000000) {
            index = (position - 0x70000000) + 35 * 8;
        } else {
            revert("invalid memory access");
        }

        val = a.buffer.toBytes32(index);
    }
}
