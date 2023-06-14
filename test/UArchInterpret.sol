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

import "./IUArchInterpret.sol";
import "contracts/UArchStep.sol";

contract UArchInterpret is IUArchInterpret {
    /// @notice Run interpret until machine halts.
    /// @param state state of machine
    /// @return Returns an exit code
    function interpret(
        IUArchState.State memory state
    ) external override returns (InterpreterStatus) {
        uint64 ucycle;
        bool halt;

        while (ucycle < type(uint64).max) {
            (ucycle, halt) = UArchStep.step(state);

            if (halt) {
                return InterpreterStatus.Halt;
            }
        }
        return InterpreterStatus.Success;
    }
}
