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

/// @title MetaStep
/// @notice State transition function that takes the machine from micro-state s[i] to s[i + 1]

pragma solidity ^0.8.0;

import "./UArchStep.sol";
import "./UArchReset.sol";

library MetaStep {
    using AccessLogs for AccessLogs.Context;

    /// @notice Run meta-step
    function step(uint256 counter, AccessLogs.Context memory accessLogs)
        internal
        pure
        returns (UArchStep.UArchStepStatus)
    {
        UArchStep.UArchStepStatus status = UArchStep.step(accessLogs);
        bytes32 machineState = accessLogs.currentRootHash;

        if (
            counter
                == (counter >> EmulatorConstants.LOG2_CYCLES_TO_RESET)
                    << EmulatorConstants.LOG2_CYCLES_TO_RESET
        ) {
            // if counter is a multiple of (1 << EmulatorConstants.LOG2_CYCLES_TO_RESET), run uarch reset
            UArchReset.reset(accessLogs);
            machineState = accessLogs.currentRootHash;
        }

        require(
            accessLogs.buffer.data.length == accessLogs.buffer.offset,
            "buffer should be fully consumed"
        );

        return status;
    }
}
