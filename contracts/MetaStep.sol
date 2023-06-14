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

import "./interfaces/IMetaStep.sol";
import "./interfaces/IUArchStep.sol";
import "./UArchConstants.sol";
import "./UArchState.sol";

contract MetaStep is IMetaStep {
    using AccessLogs for AccessLogs.Context;

    UArchState immutable ustate;
    IUArchStep immutable ustep;

    constructor(IUArchStep stepInterface, UArchState stateImpl) {
        ustate = stateImpl;
        ustep = stepInterface;
    }

    /// @notice Run meta-step
    function step(
        AccessLogs.Context memory accessLogs
    )
        external
        override
        returns (uint64 cycle, bool halt, bytes32 machineState)
    {
        AccessLogs.Context memory accessLogsAfterStep;
        IUArchState.State memory state = IUArchState.State(ustate, accessLogs);

        (cycle, halt, accessLogsAfterStep) = ustep.step(state);
        machineState = accessLogsAfterStep.currentRootHash;

        if (
            cycle ==
            (cycle >> ustate.LOG2_CYCLES_TO_RESET()) <<
                ustate.LOG2_CYCLES_TO_RESET()
        ) {
            // if cycle is a multiple of (1 << UArchConstants.LOG2_CYCLES_TO_RESET), run uarch reset
            accessLogsAfterStep.writeRegion(
                Memory.regionFromPhysicalAddress(
                    Memory.PhysicalAddress.wrap(ustate.RESET_POSITION()),
                    Memory.AlignedSize.wrap(ustate.RESET_ALIGNED_SIZE())
                ),
                ustate.PRESTINE_STATE()
            );
            machineState = accessLogsAfterStep.currentRootHash;
        }
    }
}
