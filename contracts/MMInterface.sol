// Copyright 2019 Cartesi Pte. Ltd.

// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title Interface for memory manager instantiator
pragma solidity ^0.5.0;

import "./Instantiator.sol";

/// @title MMInterface
/// @author Augusto Teixeira
/// @notice Defines the Machine Manager interface
contract MMInterface is Instantiator {
    enum state {
        WaitingProofs,
        WaitingReplay,
        FinishedReplay
    }

    function getCurrentState(uint256 _index) public view
        returns (bytes32);

    function instantiate(address _provider, address _client, bytes32 _initialHash) public returns (uint256);
    function read(uint256 _index, uint64 _position) public returns (bytes8);
    function write(uint256 _index, uint64 _position, bytes8 _value) public;
    function newHash(uint256 _index) public view returns (bytes32);
    function finishProofPhase(uint256 _index) public;
    function finishReplayPhase(uint256 _index) public;
    function stateIsWaitingProofs(uint256 _index) public view returns (bool);
    function stateIsWaitingReplay(uint256 _index) public view returns (bool);
    function stateIsFinishedReplay(uint256 _index) public view returns (bool);
}
