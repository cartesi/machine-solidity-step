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

library Memory {
    //
    // AlignedSize
    //
    // The size is given in the number of leaves in the tree,
    // and therefore are word-sized; a size of one (or log2size zero) means one word long.

    type AlignedSize is uint8;

    uint64 constant MAX_SIZE = (1 << 61);
    using Memory for AlignedSize;

    function alignedSizeFromLog2(uint8 s) internal pure returns (AlignedSize) {
        return AlignedSize.wrap(s);
    }

    function log2(AlignedSize s) internal pure returns (uint8) {
        return AlignedSize.unwrap(s);
    }

    function size(AlignedSize s) internal pure returns (uint64) {
        return uint64(1 << s.log2());
    }

    //
    // Stride and MemoryAddress
    //
    // When using memory address and a size in merkle trees to refer to a memory region,
    // the address/size have to be aligned to a power-of-two.
    // By using stride instead, we can guarantee that the address is aligned.
    // The address is given by `stride * (1 << log2s)`.
    // For convenince, we give both address and stride types, as well as conversion methods

    type Stride is uint64;
    type MemoryAddress is uint64;

    uint64 constant MAX_STRIDE = MAX_SIZE - 1;
    using Memory for Stride;

    function strideFromAddress(
        MemoryAddress startAddress,
        AlignedSize alignedSize
    ) internal pure returns (Stride) {
        uint64 s = alignedSize.size();
        uint64 addr = MemoryAddress.unwrap(startAddress);
        // assert memory address is word-aligned
        assert(addr & 7 == 0);
        uint64 position = MemoryAddress.unwrap(startAddress) >> 3;
        // assert memory address and size are aligned
        assert(((s - 1) & position) == 0);
        uint64 stride = position / s;
        return Stride.wrap(stride);
    }

    function strideFromWordAddress(
        MemoryAddress startAddress
    ) internal pure returns (Stride) {
        return strideFromAddress(startAddress, alignedSizeFromLog2(0));
    }

    function validateStrideLength(
        Stride stride,
        AlignedSize alignedSize
    ) internal pure {
        uint64 s = alignedSize.size();
        assert(Stride.unwrap(stride) * s < MAX_STRIDE);
    }

    // Specifies a memory region and it's merkle hash.
    // The size is given in the number of leaves in the tree,
    // and therefore are word-sized.
    // This means a `alignedSize` specifies a region the size of a word.
    // The address has to be aligned to a power-of-two.
    // By using an stride, we can guarantee that the address is aligned.
    // The address is given by `stride * (1 << log2s)`.
    struct Region {
        Stride stride;
        AlignedSize alignedSize;
    }

    function regionFromStride(
        Stride stride,
        AlignedSize alignedSize
    ) internal pure returns (Region memory) {
        stride.validateStrideLength(alignedSize);
        return Region(stride, alignedSize);
    }

    function regionFromMemoryAddress(
        MemoryAddress startAddress,
        AlignedSize alignedSize
    ) internal pure returns (Region memory) {
        Stride stride = strideFromAddress(startAddress, alignedSize);
        return regionFromStride(stride, alignedSize);
    }

    function regionFromWordAddress(
        MemoryAddress startAddress
    ) internal pure returns (Region memory) {
        return regionFromMemoryAddress(startAddress, alignedSizeFromLog2(0));
    }
}
