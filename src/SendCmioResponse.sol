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

/// @title SendCmioResponse
/// @notice Sends a CMIO response
//:#include macro.pp
/// DEV_COMMENT(templates/SendCmioResponse.sol.template)

pragma solidity ^0.8.30;

import "./EmulatorCompat.sol";

library SendCmioResponse {
    using Memory for uint64;
    using AccessLogs for AccessLogs.Context;

    // START OF AUTO-GENERATED CODE

    function sendCmioResponse(
        AccessLogs.Context memory a,
        uint16 reason,
        bytes32 dataHash,
        uint32 dataLength,
        bytes32 revertRootHash
    ) internal pure {
        // This function cannot fail. When a failure is detected, the operation is a no-op instead,
        // so the honest party can always log and prove the resulting state transition.
        // A response to a machine that is not waiting on a manual yield is a no-op.
        if (!EmulatorCompat.readIflagsY(a)) {
            return;
        }
        if (reason == EmulatorConstants.HTIF_YIELD_REASON_ADVANCE_STATE) {
            // Advance-state responses are the input boundary of the rollups flow. They only apply to a
            // machine waiting for an input on an rx-accepted manual yield. Sending one to a machine that
            // yielded manual with any other reason (e.g., rejected an input or threw an exception) is a no-op.
            uint64 tohost = EmulatorCompat.readHtifTohost(a);
            if (!EmulatorCompat.isYieldedManualWith(
                    tohost,
                    EmulatorConstants.HTIF_YIELD_MANUAL_REASON_RX_ACCEPTED
                )) {
                return;
            }
        }
        // A zero length data is a valid response. We just skip writing to the rx buffer.
        uint32 writeLengthLog2Size = 0;
        if (dataLength > 0) {
            // Find the write length: the smallest power of 2 that is >= dataLength and >= tree leaf size
            writeLengthLog2Size = EmulatorCompat.uint32Log2(dataLength);
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
            // A response with data that does not fit in the rx buffer is a no-op
            if (
                writeLengthLog2Size
                    > EmulatorConstants.AR_CMIO_RX_BUFFER_LOG2_SIZE
            ) {
                return;
            }
        }
        if (reason == EmulatorConstants.HTIF_YIELD_REASON_ADVANCE_STATE) {
            uint64 mcycle = EmulatorCompat.readMcycle(a);
            uint64 maxMcycles = EmulatorCompat.uint64ShiftLeft(
                1,
                uint32(
                    EmulatorConstants.ROLLUP_LOG2_MAX_MCYCLES_PER_ADVANCE_STATE
                )
            ) - 1;
            uint64 maxUint64 = ~uint64(0);
            uint64 imcyclemax = mcycle > maxUint64 - maxMcycles
                ? maxUint64
                : mcycle + maxMcycles;
            EmulatorCompat.writeImcyclemax(a, imcyclemax);
            // Record the machine root hash to revert to in case the response is eventually rejected
            EmulatorCompat.writeRevertRootHash(a, revertRootHash);
        }
        if (dataLength > 0) {
            a.writeRegion(
                Memory.regionFromPhysicalAddress(
                    EmulatorConstants.AR_CMIO_RX_BUFFER_START
                    .toPhysicalAddress(),
                    Memory.alignedSizeFromLog2(
                        uint8(
                            writeLengthLog2Size
                                - EmulatorConstants.HASH_TREE_LOG2_WORD_SIZE
                        )
                    )
                ),
                dataHash
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

    // END OF AUTO-GENERATED CODE
}
