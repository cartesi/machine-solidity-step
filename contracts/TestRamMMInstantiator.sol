// Copyright 2019 Cartesi Pte. Ltd.

// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.5.0;

import "@cartesi/arbitration/contracts/MMInstantiator.sol";
import "@cartesi/util/contracts/BitsManipulationLibrary.sol";


/// @title Test RAM MM Instantiator
/// @author Stephen Chen
/// @notice A mock memory manager for running test_ram.py
/// @dev This should never be deployed to Main net.
/// @dev This contract is unsafe.
contract TestRamMMInstantiator is MMInstantiator {
  // the provider will fill the memory for the client to read and write
  // memory starts with hash and all values that are inserted are first verified
  // then client can read inserted values and write some more
  // finally the provider has to update the hash to account for writes

    struct MemoryMap {
        mapping(uint64 => bytes8) map;
    }
    mapping(uint256 => MemoryMap) internal ramInstance;
    event HTIFExit(uint256 _index, uint64 _exitCode, bool _halt);

    /// @notice Stop memory insertion and start read and write phase
    function finishProofPhase(uint256 _index) public
        onlyInstantiated(_index)
        //onlyBy(instance[_index].provider)
        increasesNonce(_index)
    {
        require(instance[_index].currentState == state.WaitingProofs, "CurrentState is not WaitingProofs, cannot finishProofPhase");
        instance[_index].currentState = state.WaitingReplay;
        emit FinishedProofs(_index);
    }

    /// @notice Replays a read in memory that has been proved to be correct
    /// according to initial hash
    /// @param _position of the desired memory
    function read(uint256 _index, uint64 _position) public
        onlyInstantiated(_index)
        //onlyBy(instance[_index].client)
        increasesNonce(_index)
        returns (bytes8)
    {
        require(instance[_index].currentState == state.WaitingReplay, "CurrentState is not WaitingReplay, cannot read");
        require((_position & 7) == 0, "Position is not aligned");
        bytes8 value = ramInstance[_index].map[_position];
        emit ValueRead(
            _index,
            _position,
            value);
        return value;
    }

    /// @notice Replays a write in memory that was proved correct
    /// @param _position of the write
    /// @param _value to be written
    function write(uint256 _index, uint64 _position, bytes8 _value) public
        //onlyBy(instance[_index].client)
        increasesNonce(_index)
        onlyInstantiated(_index)
    {
        require(instance[_index].currentState == state.WaitingReplay, "CurrentState is not WaitingReplay, cannot write");
        require((_position & 7) == 0, "Position is not aligned");
        bytes8 oldValue = ramInstance[_index].map[_position];
        ramInstance[_index].map[_position] = _value;
        emit ValueWritten(
            _index,
            _position,
            _value);
    }

    /// @notice Stop write (or read) phase
    function finishReplayPhase(uint256 _index) public
        onlyInstantiated(_index)
        //onlyBy(instance[_index].client)
        increasesNonce(_index)
    {
        require(instance[_index].currentState == state.WaitingReplay, "CurrentState is not WaitingReplay, cannot finishReplayPhase");
        //require(instance[_index].historyPointer == instance[_index].history.length, "History pointer does not match length");
        //delete(instance[_index].history);
        //delete(instance[_index].historyPointer);
        //instance[_index].currentState = state.FinishedReplay;

        //deactivate(_index);
        //emit FinishedReplay(_index);
    }

    /// @notice Perform a read in HTIF to get the arbitrary exit code
    function htifExit(uint256 _index) public
        onlyInstantiated(_index)
        returns (uint64)
    {
        uint64 val = uint64(ramInstance[_index].map[0x40008000]);
        bool halt = false;

        val = BitsManipulationLibrary.uint64SwapEndian(val);

        uint64 bit0 = val & 1;
        uint64 payload = val << 16 >> 17;

        halt = (bit0 == 1);

        emit HTIFExit(_index, payload, halt);
        return payload;
    }
}
