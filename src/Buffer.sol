// Copyright 2023 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @dev This file is generated from helper_scripts/generate_AccessLogs.sh, one should not modify the content directly

pragma solidity ^0.8.0;

import "./Memory.sol";

library Buffer {
    using Buffer for Buffer.Context;
    using Memory for Memory.AlignedSize;

    struct Context {
        bytes data;
        uint256 offset;
    }

    function consumeBytes8(Buffer.Context memory buffer)
        internal
        pure
        returns (bytes8)
    {
        bytes8 b8 = bytes8(buffer.peekBytes32());
        buffer.offset += 8;

        return b8;
    }

    function consumeBytes32(Buffer.Context memory buffer)
        internal
        pure
        returns (bytes32)
    {
        bytes32 b32 = buffer.peekBytes32();
        buffer.offset += 32;

        return b32;
    }

    function peekBytes32(Buffer.Context memory buffer)
        internal
        pure
        returns (bytes32)
    {
        bytes32 temp;
        bytes memory data = buffer.data;
        uint256 offset = buffer.offset;

        // Get 32 bytes from data
        assembly {
            temp := mload(add(data, add(offset, 32)))
        }
        return temp;
    }

    function peekRoot(
        Buffer.Context memory buffer,
        Memory.Region memory region,
        bytes32 drive
    ) internal pure returns (bytes32, uint8) {
        // require that multiplier makes sense!
        uint8 logOfSize = region.alignedSize.log2();
        require(logOfSize <= LOG2RANGE, "Cannot be bigger than the tree itself");

        uint64 stride = Memory.Stride.unwrap(region.stride);
        uint8 nodesCount = LOG2RANGE - logOfSize;

        for (uint64 i = 0; i < nodesCount; i++) {
            Buffer.Context memory siblings =
                Buffer.Context(buffer.data, buffer.offset + (i << 5));

            if (isEven(stride >> i)) {
                drive =
                    keccak256(abi.encodePacked(drive, siblings.peekBytes32()));
            } else {
                drive =
                    keccak256(abi.encodePacked(siblings.peekBytes32(), drive));
            }
        }

        return (drive, nodesCount);
    }

    function getRoot(
        Buffer.Context memory buffer,
        Memory.Region memory region,
        bytes32 drive
    ) internal pure returns (bytes32, uint8) {
        (bytes32 root, uint8 nodesCount) = buffer.peekRoot(region, drive);
        buffer.offset += uint128(nodesCount) << 5;

        return (root, nodesCount);
    }

    uint8 constant LOG2RANGE = 61;

    function isEven(uint64 x) private pure returns (bool) {
        return x % 2 == 0;
    }
}
