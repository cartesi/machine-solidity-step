// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./Step.sol";


/// @title TestRamStep
/// @author Stephen Chen
/// @dev This should never be deployed to Main net.
/// @dev This contract is unsafe.
contract TestRamStep is Step {
    constructor(address miAddress) Step(miAddress) {}
    /// @notice Run step define by a MemoryManager instance until halt.
    /// @param mmIndex Specific index of the Memory Manager that contains this Step's access logs
    /// @return Returns an cycle number.
    function stepUntilHalt(uint mmIndex) public returns (uint64) {
        uint64 halt = 0;

        while (halt == 0) {
            step(mmIndex);
            halt = mi.readIflagsH(mmIndex);
        }

        uint64 mcycle = mi.readMcycle(mmIndex);

        return mcycle;
    }

}
