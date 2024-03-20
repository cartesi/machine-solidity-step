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
import "src/Memory.sol";

pragma solidity ^0.8.0;

library MemoryAux {
    function strideFromPhysicalAddress(
        Memory.PhysicalAddress startAddress,
        Memory.AlignedSize alignedSize
    ) external pure returns (Memory.Stride) {
        return Memory.strideFromPhysicalAddress(startAddress, alignedSize);
    }

    function regionFromPhysicalAddress(
        Memory.PhysicalAddress startAddress,
        Memory.AlignedSize alignedSize
    ) external pure returns (Memory.Region memory) {
        return Memory.regionFromPhysicalAddress(startAddress, alignedSize);
    }
}
