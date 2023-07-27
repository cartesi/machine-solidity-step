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

import "./interfaces/IUArchStep.sol";
import "./interfaces/IUArchState.sol";
import "./UArchExecuteInsn.sol";
import "./UArchCompat.sol";

contract UArchStep is IUArchStep, UArchExecuteInsn {
    /// @notice Run step
    /// @param state state of machine
    /// @return (uint64, bool) cycle number and if the machine halts
    function step(
        IUArchState.State memory state
    ) external override returns (uint64, bool) {
        uint64 ucycle = UArchCompat.readCycle(state);

        if (UArchCompat.readHaltFlag(state)) {
            require(
                state.accessLogs.current == state.accessLogs.logs.length,
                "access pointer should match accesses length when halt"
            );
            return (ucycle, true);
        }
        // early check if ucycle is uint64.max, so it'll be safe to uncheck increment later
        if (ucycle == type(uint64).max) {
            require(
                state.accessLogs.current == state.accessLogs.logs.length,
                "access pointer should match accesses length when cycle is uint64.max"
            );
            return (ucycle, false);
        }

        uint64 upc = UArchCompat.readPc(state);
        uint32 insn = readUint32(state, upc);
        uarchExecuteInsn(state, insn, upc);

        unchecked {
            ++ucycle;
        }
        UArchCompat.writeCycle(state, ucycle);

        require(
            state.accessLogs.current == state.accessLogs.logs.length,
            "access pointer should match accesses length"
        );
        return (ucycle, false);
    }
}
