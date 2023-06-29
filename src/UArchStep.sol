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

import "./UArchExecuteInsn.sol";

library UArchStep {
    using UArchCompat for AccessLogs.Context;
    using UArchExecuteInsn for AccessLogs.Context;

    /// @notice Run step
    /// @param accessLogs logs of machine access
    /// @return (uint64, bool) cycle number, machine halt state
    function step(AccessLogs.Context memory accessLogs)
        internal
        pure
        returns (uint64, bool)
    {
        uint64 ucycle = accessLogs.readCycle();

        if (accessLogs.readHaltFlag()) {
            return (ucycle, true);
        }
        // early check if ucycle is uint64.max, so it'll be safe to uncheck increment later
        if (ucycle == type(uint64).max) {
            return (ucycle, false);
        }

        uint64 upc = accessLogs.readPc();
        uint32 insn = accessLogs.readUint32(upc);
        accessLogs.uarchExecuteInsn(insn, upc);

        unchecked {
            ++ucycle;
        }
        accessLogs.writeCycle(ucycle);

        return (ucycle, false);
    }
}
