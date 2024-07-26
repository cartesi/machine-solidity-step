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

import "./BufferAux.sol";
import "./MemoryAux.sol";

pragma solidity ^0.8.0;

contract MemoryTest is Test {
    using Memory for Memory.Stride;
    using Memory for uint64;
    using MemoryAux for Memory.PhysicalAddress;

    function testStrideAlignment() public {
        for (uint128 paddr = 8; paddr <= (1 << 63); paddr *= 2) {
            for (uint8 l = 0; ((1 << l) <= (paddr >> Memory.LOG2_LEAF)); ++l) {
                uint64(paddr).toPhysicalAddress().strideFromPhysicalAddress(
                    Memory.alignedSizeFromLog2(l)
                );

                // address has to be aligned with 8-byte word
                vm.expectRevert();
                uint64(paddr - 1).toPhysicalAddress().strideFromPhysicalAddress(
                    Memory.alignedSizeFromLog2(l)
                );

                if ((1 << l) == (paddr >> Memory.LOG2_LEAF)) {
                    // address has to be aligned with stride size
                    vm.expectRevert();
                    uint64(paddr + paddr / 2).toPhysicalAddress()
                        .strideFromPhysicalAddress(Memory.alignedSizeFromLog2(l));
                }
            }
        }
    }
}
