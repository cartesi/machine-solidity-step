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

/// @dev This file is generated from C++ by generate_UArchSolidity.lua

pragma solidity ^0.8.30;

import "./EmulatorCompat.sol";

library SendCmioResponse {
    function sendCmioResponse(
        AccessLogs.Context memory a,
        uint16 reason,
        bytes32 dataHash,
        uint32 dataLength
    ) internal pure {
        if (!EmulatorCompat.readIflagsY(a)) {
            EmulatorCompat.throwRuntimeError(a, "iflags.Y is not set");
        }
        // A zero length data is a valid response. We just skip writing to the rx buffer.
        if (dataLength > 0) {
            // Find the write length: the smallest power of 2 that is >= dataLength and >= tree leaf size
            uint32 writeLengthLog2Size = EmulatorCompat.uint32Log2(dataLength);
            if (
                writeLengthLog2Size < EmulatorConstants.HASH_TREE_LOG2_WORD_SIZE
            ) {
                writeLengthLog2Size = EmulatorConstants.HASH_TREE_LOG2_WORD_SIZE; // minimum write size is the tree leaf size
            }
            if (
                EmulatorCompat.uint32ShiftLeft(1, writeLengthLog2Size)
                    < dataLength
            ) {
                writeLengthLog2Size += 1;
            }
            if (
                writeLengthLog2Size
                    > EmulatorConstants.AR_CMIO_RX_BUFFER_LOG2_SIZE
            ) {
                EmulatorCompat.throwRuntimeError(
                    a, "CMIO response data is too large"
                );
            }
            EmulatorCompat.writeMemoryWithPadding(
                a,
                EmulatorConstants.AR_CMIO_RX_BUFFER_START,
                dataHash,
                dataLength,
                writeLengthLog2Size
            );
        }
        // Write data length and reason to fromhost
        uint64 mask16 = EmulatorCompat.uint64ShiftLeft(1, 16) - 1;
        uint64 mask32 = EmulatorCompat.uint64ShiftLeft(1, 32) - 1;
        uint64 yieldData = EmulatorCompat.uint64ShiftLeft(
            (uint64(reason) & mask16), 32
        ) | (uint64(dataLength) & mask32);
        EmulatorCompat.writeHtifFromhost(a, yieldData);
        // Reset iflags.Y
        EmulatorCompat.writeIflagsY(a, 0);
    }
}
