/// @title Memory Manager
pragma solidity 0.4.24;

contract MemoryManager {
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
