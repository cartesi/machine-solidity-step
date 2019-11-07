// Copyright 2019 Cartesi Pte. Ltd.

// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.5.0;

//Libraries
import "./Step.sol";
import "./TestRamMMInstantiator.sol";


/// @title TestRamStep
/// @author Stephen Chen
/// @notice A mock Step contract to test RAM
/// @dev This should never be deployed to Main net.
/// @dev This contract is unsafe.
contract TestRamStep {
    // event Print(string message, uint value);
    Step step;
    TestRamMMInstantiator mm;

    event HTIFExit(uint256 _index, uint64 _exitCode, bool _halt);

    constructor(address stepAddress, address testRamMMAddress) public {
        step = Step(stepAddress);
        mm = TestRamMMInstantiator(testRamMMAddress);
    }

    function loop(uint mmIndex) public {
        bool halt = false;
        uint64 exitCode = 0;

        while (!halt) {
            step.step(mmIndex);
            (exitCode, halt) = mm.htifExit(mmIndex);
        }

        emit HTIFExit(mmIndex, exitCode, halt);
    }

}
