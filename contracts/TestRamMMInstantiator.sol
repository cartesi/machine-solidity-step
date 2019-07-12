/// @title An instantiator of memory managers (specially for running test_ram.py)
pragma solidity ^0.5.0;

import "./Decorated.sol";
import "./MMInterface.sol";
import "./Merkle.sol";
import "./lib/BitsManipulationLibrary.sol";


contract TestRamMMInstantiator is MMInterface, Decorated {
  // the privider will fill the memory for the client to read and write
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
        mapping(uint64 => bytes8) memoryMap;
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
    event ValueReplay(bool _isRead, uint256 _index, uint64 _position, bytes8 _readValue, bytes8 _writtenValue);
    event HTIFExit(uint256 _index, uint64 _exitCode, bool _halt);
    event FinishedProofs(uint256 _index);
    event FinishedReplay(uint256 _index);

    function instantiate(address _provider, address _client, bytes32 _initialHash) public returns (uint256) {
        require(_provider != _client, "Provider and client need to differ");
        MMCtx storage currentInstance = instance[currentIndex];
        currentInstance.provider = _provider;
        currentInstance.client = _client;
        currentInstance.initialHash = _initialHash;
        currentInstance.newHash = _initialHash;
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
        revert("ProveRead shall not be called in TestRamMMInstantiator");
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
        revert("ProveWrite shall not be called in TestRamMMInstantiator");
    }

    /// @notice Stop memory insertion and start read and write phase
    function finishProofPhase(uint256 _index) public
        onlyInstantiated(_index)
    {
        instance[_index].currentState = state.WaitingReplay;
        emit FinishedProofs(_index);
    }

    /// @notice Perform a read in HTIF to get the arbitrary exit code
    function htifExit(uint256 _index) public
        onlyInstantiated(_index)
        returns (uint64, bool)
    {
        uint64 val = uint64(instance[_index].memoryMap[0x40008000]);
        bool halt = false;

        val = BitsManipulationLibrary.uint64SwapEndian(val);

        uint64 bit0 = val & 1;
        uint64 bits48To64 = val & (((2 ** 16) - 1) << 48);
        val = (val & ((2 ** 48) - 1)) >> 1;

        halt = (bit0 == 1) && (bits48To64 == 0);

        emit HTIFExit(_index, val, halt);
        return (val, halt);
    }

    /// @notice initialize the memory with value
    /// @param _position of the memory
    /// @param _value to be written
    function initMemory(uint256 _index, uint64 _position, bytes8 _value) public
        onlyInstantiated(_index)
    {
        require((_position & 7) == 0, "Position is not aligned");
        instance[_index].memoryMap[_position] = _value;
    }

    /// @notice Replays a read in memory that has been proved to be correct
    /// according to initial hash
    /// @param _position of the desired memory
    function read(uint256 _index, uint64 _position) public
        onlyInstantiated(_index)
        returns (bytes8)
    {
        require((_position & 7) == 0, "Position is not aligned");
        bytes8 value = instance[_index].memoryMap[_position];
        emit ValueReplay(
            true,
            _index,
            _position,
            value,
            0);
        return value;
    }

    /// @notice Replays a write in memory that was proved correct
    /// @param _position of the write
    /// @param _value to be written
    function write(uint256 _index, uint64 _position, bytes8 _value) public
        onlyInstantiated(_index)
    {
        require((_position & 7) == 0, "Position is not aligned");
        bytes8 oldValue = instance[_index].memoryMap[_position];
        instance[_index].memoryMap[_position] = _value;
        emit ValueReplay(
            false,
            _index,
            _position,
            oldValue,
            _value);
    }

    /// @notice Stop write (or read) phase
    function finishReplayPhase(uint256 _index) public
        onlyInstantiated(_index)
    {
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
                bytes32 _currentState)
    {
        MMCtx memory i = instance[_index];

        return (
            i.provider,
            i.client,
            i.initialHash,
            i.newHash,
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
