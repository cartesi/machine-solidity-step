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

import "src/UArchStep.sol";

library UArchInterpret {
    /// @notice Run interpret until machine halts.
    /// @param accessLogs logs of machine access
    /// @return Returns an exit code
    function interpret(AccessLogs.Context memory accessLogs)
        internal
        pure
        returns (UArchStep.uarch_step_status)
    {
        UArchStep.uarch_step_status status;

        while (status != UArchStep.uarch_step_status.cycle_overflow) {
            status = UArchStep.step(accessLogs);

            if (
                status == UArchStep.uarch_step_status.success_and_uarch_halted
                    || status == UArchStep.uarch_step_status.uarch_halted
                    || status == UArchStep.uarch_step_status.halted
            ) {
                return status;
            }
        }
        return status;
    }
}
