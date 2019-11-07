// Copyright 2019 Cartesi Pte. Ltd.

// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.5.0;

import "@cartesi/util/contracts/Decorated.sol";
import "@cartesi/util/contracts/Merkle.sol";
import "@cartesi/arbitration/contracts/MMInterface.sol";


/// @title Mock Memory Manager Instantiator.
/// @author Felipe Argento
/// @notice A mock Memory Manager for testing purposes
/// @dev This should never be deployed to Main net.
/// @dev This contract is unsafe.
contract MockMMInstantiator is MMInterface, Decorated {
  // the provider will fill the memory for the client to read and write
  // memory starts with hash and all values that are inserted are first verified
  // then client can read inserted values and write some more
  // finally the provider has to update the hash to account for writes

    struct ReadWrite {
        bool wasRead;
        uint64 position;
        bytes8 value;
    }

    // IMPLEMENT GARBAGE COLLECTOR AFTER AN INSTACE IS FINISHED!
    struct MMCtx {
        address provider;
        address client;
        bytes32 initialHash;
        bytes32 newHash; // hash after some write operations have been proved
        ReadWrite[] history;
        uint historyPointer;
        state currentState;
    }

    mapping(uint256 => MMCtx) internal instance;

    // These are the possible states and transitions of the contract.
    //
    // +---+
    // |   |
    // +---+
    //   |
    //   | instantiate
    //   v
    // +---------------+    | proveRead
    // | WaitingProofs |----| proveWrite
    // +---------------+
    //   |
    //   | finishProofPhase
    //   v
    // +----------------+    |read
    // | WaitingReplay  |----|write
    // +----------------+
    //   |
    //   | finishReplayPhase
    //   v
    // +----------------+
    // | FinishedReplay |
    // +----------------+
    //

    event MemoryCreated(uint256 _index, bytes32 _initialHash);
    event ValueProved(uint256 _index, bool _wasRead, uint64 _position, bytes8 _value);
    event ValueRead(uint256 _index, uint64 _position, bytes8 _value);
    event ValueWritten(uint256 _index, uint64 _position, bytes8 _value);
    event FinishedProofs(uint256 _index);
    event FinishedReplay(uint256 _index);

    function instantiate(address _provider, address _client, bytes32 _initialHash) public returns (uint256) {
        require(_provider != _client, "Provider and client need to differ");
        MMCtx storage currentInstance = instance[currentIndex];
        currentInstance.provider = _provider;
        currentInstance.client = _client;
        currentInstance.initialHash = _initialHash;
        currentInstance.newHash = _initialHash;
        currentInstance.historyPointer = 0;
        currentInstance.currentState = state.WaitingProofs;
        emit MemoryCreated(currentIndex, _initialHash);

        active[currentIndex] = true;
        return currentIndex++;
    }

    /// @notice Proves that a certain value in current memory is correct
    // @param _position The address of the value to be confirmed
    // @param _value The value in that address to be confirmed
    // @param proof The proof that this value is correct
    function proveRead(
        uint256 _index,
        uint64 _position,
        bytes8 _value,
        bytes32[] memory proof) public
    {
        require(Merkle.getRoot(_position, _value, proof) == instance[_index].newHash, "Merkle proof does not match");
        instance[_index].history.push(ReadWrite(true, _position, _value));
        emit ValueProved(
            _index,
            true,
            _position,
            _value
        );
    }

    /// @notice Register a write operation and update newHash
    /// @param _position to be written
    /// @param _oldValue before write
    /// @param _newValue to be written
    /// @param proof The proof that the old value was correct
    function proveWrite(
        uint256 _index,
        uint64 _position,
        bytes8 _oldValue,
        bytes8 _newValue,
        bytes32[] memory proof) public
    {
        // check proof of old value
        require(Merkle.getRoot(_position, _oldValue, proof) == instance[_index].newHash, "Merkle proof of write does not match");
        // update root
        instance[_index].newHash = Merkle.getRoot(_position, _newValue, proof);
        instance[_index].history.push(ReadWrite(false, _position, _newValue));
        emit ValueProved(
            _index,
            false,
            _position,
            _newValue
        );
    }

    /// @notice Stop memory insertion and start read and write phase
    function finishProofPhase(uint256 _index) public
    {
        instance[_index].currentState = state.WaitingReplay;
        emit FinishedProofs(_index);
    }

    /// @notice Replays a read in memory that has been proved to be correct
    /// according to initial hash
    /// @param _position of the desired memory
    function read(uint256 _index, uint64 _position) public
        returns (bytes8)
    {
        require((_position & 7) == 0, "Read Position is not aligned");
        uint pointer = instance[_index].historyPointer;
        ReadWrite storage  pointInHistory = instance[_index].history[pointer];
        require(pointInHistory.wasRead, "Read PointInHistory has not been read");
        require(pointInHistory.position == _position, "Read PointInHistory's position does not match");
        bytes8 value = pointInHistory.value;
        delete(instance[_index].history[pointer]);
        instance[_index].historyPointer++;
        emit ValueRead(_index, _position, value);
        return value;
    }

    /// @notice Replays a write in memory that was proved correct
    /// @param _position of the write
    /// @param _value to be written
    function write(uint256 _index, uint64 _position, bytes8 _value) public
    {
        require((_position & 7) == 0, "Write Position is not aligned");
        uint pointer = instance[_index].historyPointer;
        ReadWrite storage pointInHistory = instance[_index].history[pointer];
        require(!pointInHistory.wasRead, "Write PointInHistory was not write");
        require(pointInHistory.position == _position, "Write PointInHistory's position does not match");
        require(pointInHistory.value == _value, "Write PointInHistory's value does not match");
        delete(instance[_index].history[pointer]);
        instance[_index].historyPointer++;
        emit ValueWritten(_index, _position, _value);
    }

    /// @notice Stop write (or read) phase
    function finishReplayPhase(uint256 _index) public
    {
        delete(instance[_index].history);
        delete(instance[_index].historyPointer);
        instance[_index].currentState = state.FinishedReplay;

        deactivate(_index);
        emit FinishedReplay(_index);
    }

    // getter methods
    function isConcerned(uint256 _index, address _user) public view returns (bool) {
        return ((instance[_index].provider == _user) || (instance[_index].client == _user));
    }

    function getState(uint256 _index) public view
        onlyInstantiated(_index)
        returns (address _provider,
                address _client,
                bytes32 _initialHash,
                bytes32 _newHash,
                uint _numberSubmitted,
                bytes32 _currentState)
    {
        MMCtx memory i = instance[_index];

        return (
            i.provider,
            i.client,
            i.initialHash,
            i.newHash,
            i.history.length,
            getCurrentState(_index)
        );
    }

    function getSubInstances(uint256)
        public view returns (address[] memory, uint256[] memory)
    {
        address[] memory a = new address[](0);
        uint256[] memory i = new uint256[](0);
        return (a, i);
    }

    function provider(uint256 _index) public view
        onlyInstantiated(_index)
        returns (address)
    { return instance[_index].provider; }

    function client(uint256 _index) public view
        onlyInstantiated(_index)
        returns (address)
    { return instance[_index].client; }

    function initialHash(uint256 _index) public view
        onlyInstantiated(_index)
        returns (bytes32)
    { return instance[_index].initialHash; }

    function newHash(uint256 _index) public view
        onlyInstantiated(_index)
        returns (bytes32)
    { return instance[_index].newHash; }

    // state getters

    function getCurrentState(uint256 _index) public view
        onlyInstantiated(_index)
        returns (bytes32)
    {
        if (instance[_index].currentState == state.WaitingProofs) {
            return "WaitingProofs";
        }
        if (instance[_index].currentState == state.WaitingReplay) {
            return "WaitingReplay";
        }
        if (instance[_index].currentState == state.FinishedReplay) {
            return "FinishedReplay";
        }
        require(false, "Unrecognized state");
    }

    // remove these functions and change tests accordingly
    function stateIsWaitingProofs(uint256 _index) public view
        onlyInstantiated(_index)
        returns (bool)
    { return instance[_index].currentState == state.WaitingProofs; }

    function stateIsWaitingReplay(uint256 _index) public view
        onlyInstantiated(_index)
        returns (bool)
    { return instance[_index].currentState == state.WaitingReplay; }

    function stateIsFinishedReplay(uint256 _index) public view
        onlyInstantiated(_index)
        returns (bool)
    { return instance[_index].currentState == state.FinishedReplay; }
}
