/// @title Memory Manager
pragma solidity 0.4.24;

contract MemoryManager {
  // temporary contract to help build the RiscV emulator
  // anyone can read or write any value on memory.
  // In the oficial implementation, only the provider will be able to write
  // Every write or read will have to come with a proof that the value is correct
  event ReadMemory(uint64 position, uint64 value);
  event WriteMemory(uint64 position, uint64 value);

  mapping(uint64 => uint64) memoryMapping;

  function read(uint64 position) public returns (uint64){
    emit ReadMemory(position, memoryMapping[position]);
    return memoryMapping[position];
  }

  function write(uint64 position, uint64 value) public{
    memoryMapping[position] = value;
    emit WriteMemory(position, value);
  }
}
