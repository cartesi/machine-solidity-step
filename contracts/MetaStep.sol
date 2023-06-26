// Copyright 2023 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title MetaStep
/// @notice State transition function that takes the machine from micro-state s[i] to s[i + 1]

pragma solidity ^0.8.0;

import "./UArchStep.sol";

library MetaStep {
    using AccessLogs for AccessLogs.Context;

    /// @notice Run meta-step
    function step(
        uint256 counter,
        AccessLogs.Context memory accessLogs
    ) internal pure returns (uint64 cycle, bool halt, bytes32 machineState) {
        (cycle, halt) = UArchStep.step(accessLogs);
        machineState = accessLogs.currentRootHash;

        if (
            counter ==
            (counter >> UArchConstants.LOG2_CYCLES_TO_RESET) <<
                UArchConstants.LOG2_CYCLES_TO_RESET
        ) {
            // if counter is a multiple of (1 << UArchConstants.LOG2_CYCLES_TO_RESET), run uarch reset
            accessLogs.writeRegion(
                Memory.regionFromPhysicalAddress(
                    Memory.PhysicalAddress.wrap(UArchConstants.RESET_POSITION),
                    Memory.AlignedSize.wrap(UArchConstants.RESET_ALIGNED_SIZE)
                ),
                UArchConstants.PRESTINE_STATE
            );
            machineState = accessLogs.currentRootHash;
        }

        require(
            accessLogs.buffer.length == accessLogs.pointer,
            "buffer should be fully consumed"
        );
    }
}
