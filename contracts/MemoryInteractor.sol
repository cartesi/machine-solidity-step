/// @title MemoryInteractor.sol
pragma solidity ^0.5.0;

contract mmInterface {
  function read(uint256 _index, uint64 _address) external returns (bytes8);
  function write(uint256 _index, uint64 _address, bytes8 _value) external;
  function finishReplayPhase(uint256 _index) external;
}

contract MemoryInteractor {
  mmInterface mm;
  event PrintAddr(address a);
  //TO-DO: This will be an address.get(MMAddress) probably
  constructor(address _MemoryManagerAddress) public {
    mm = mmInterface(_MemoryManagerAddress);
    emit PrintAddr(_MemoryManagerAddress);
  }
  function memoryRead(uint256 _index, uint64 _address) public returns (bytes8){
    return mm.read(_index, _address);
  }

  function memoryWrite(uint256 _index, uint64 _address, bytes8 _value) public {
    return mm.write(_index, _address, _value);
  }
}


