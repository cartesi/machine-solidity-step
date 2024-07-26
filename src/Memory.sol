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
pragma solidity ^0.8.0;

library Memory {
    // Specifies a memory region and it's merkle hash.
    // The size is given in the number of leaves in the tree,
    // and therefore are leaf-sized.
    // This means a `alignedSize` specifies a region the size of a leaf.
    // The address has to be aligned to a power-of-two.
    // By using an stride, we can guarantee that the address is aligned.
    // The address is given by `stride * (1 << log2s)`.
    struct Region {
        Stride stride;
        AlignedSize alignedSize;
    }

    function regionFromStride(Stride stride, AlignedSize alignedSize)
        internal
        pure
        returns (Region memory)
    {
        stride.validateStrideLength(alignedSize);
        return Region(stride, alignedSize);
    }

    function regionFromPhysicalAddress(
        PhysicalAddress startAddress,
        AlignedSize alignedSize
    ) internal pure returns (Region memory) {
        Stride stride = strideFromPhysicalAddress(startAddress, alignedSize);
        return regionFromStride(stride, alignedSize);
    }

    function regionFromLeafAddress(PhysicalAddress startAddress)
        internal
        pure
        returns (Region memory)
    {
        return regionFromPhysicalAddress(startAddress, alignedSizeFromLog2(0));
    }

    // Stride and PhysicalAddress
    //
    // When using memory address and a size in merkle trees to refer to a memory region,
    // the address/size have to be aligned to a power-of-two.
    // By using stride instead, we can guarantee that the address is aligned.
    // The address is given by `stride * (1 << log2s)`.
    // For convenince, we give both address and stride types, as well as conversion methods

    type Stride is uint64;

    uint64 constant MAX_STRIDE = MAX_SIZE - 1;

    using Memory for Stride;

    function strideFromPhysicalAddress(
        PhysicalAddress startAddress,
        AlignedSize alignedSize
    ) internal pure returns (Stride) {
        uint64 s = alignedSize.size();
        uint64 addr = PhysicalAddress.unwrap(startAddress);

        // assert memory address is leaf-aligned (32-byte long)
        assert(addr & LEAF_MASK == 0);
        uint64 position = PhysicalAddress.unwrap(startAddress) >> LOG2_LEAF;

        // assert position and size are aligned
        // position has to be a multiple of size
        // equivalent to: size = 2^a, position = 2^b, position = size * 2^c, where c >= 0
        assert(((s - 1) & position) == 0);
        uint64 stride = position / s;

        return Stride.wrap(stride);
    }

    function strideFromLeafAddress(PhysicalAddress startAddress)
        internal
        pure
        returns (Stride)
    {
        return strideFromPhysicalAddress(startAddress, alignedSizeFromLog2(0));
    }

    function validateStrideLength(Stride stride, AlignedSize alignedSize)
        internal
        pure
    {
        uint64 s = alignedSize.size();
        assert(Stride.unwrap(stride) * s < MAX_STRIDE);
    }

    // AlignedSize
    //
    // The size is given in the number of leaves in the tree,
    // and therefore are word-sized; a size of one (or log2size zero) means one word long.

    type AlignedSize is uint8;

    uint8 constant LOG2_WORD = 3;
    uint8 constant LOG2_LEAF = 5;
    uint8 constant LOG2_MAX_SIZE = 64 - LOG2_LEAF;
    uint64 constant LEAF_MASK = uint64(1 << LOG2_LEAF) - 1;
    uint64 constant MAX_SIZE = uint64(1 << LOG2_MAX_SIZE);

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

    type PhysicalAddress is uint64;

    function toPhysicalAddress(uint64 uint64Address)
        internal
        pure
        returns (PhysicalAddress)
    {
        return PhysicalAddress.wrap(uint64Address);
    }

    function truncateToLeaf(PhysicalAddress addr)
        internal
        pure
        returns (PhysicalAddress, uint64)
    {
        uint64 r = Memory.PhysicalAddress.unwrap(addr) & ~LEAF_MASK;
        PhysicalAddress truncated = Memory.PhysicalAddress.wrap(r);
        uint64 offset = minus(addr, truncated);
        return (truncated, offset);
    }

    function minus(PhysicalAddress lhs, PhysicalAddress rhs)
        internal
        pure
        returns (uint64)
    {
        return Memory.PhysicalAddress.unwrap(lhs)
            - Memory.PhysicalAddress.unwrap(rhs);
    }
}
