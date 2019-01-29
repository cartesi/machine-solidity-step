/// @title MemoryInteractor.sol
pragma solidity ^0.5.0;

import "../contracts/AddressTracker.sol";
import "./lib/BitsManipulationLibrary.sol";

contract mmInterface {
  function read(uint256 _index, uint64 _address) external returns (bytes8);
  function write(uint256 _index, uint64 _address, bytes8 _value) external;
  function finishReplayPhase(uint256 _index) external;
}

contract MemoryInteractor {
  mmInterface mm;

  constructor(address _addressTrackerAddress) public {
    address _mmAddress = AddressTracker(_addressTrackerAddress).getMMAddress();
    mm = mmInterface(_mmAddress);
  }

  function read_x(uint256 _mmIndex, uint64 _registerIndex) public returns (uint64){
    return BitsManipulationLibrary.uint64_swapEndian(
      //Address = registerIndex * sizeof(uint64)
      uint64(mm.read(_mmIndex, _registerIndex * 8))
    );
  }
  function memoryRead(uint256 _index, uint64 _address) public returns (uint64){
    return BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(_index, _address))
    );
  }

  function write_x(uint256 _mmIndex, uint64 _registerIndex, uint64 _value) public {
    bytes8 bytesValue = bytes8(BitsManipulationLibrary.uint64_swapEndian(_value));
    //Address = registerIndex * sizeof(uint64)
    mm.write(_mmIndex, _registerIndex * 8, bytesValue);
  }

  function memoryWrite(uint256 _index, uint64 _address, uint64 _value) public {
    bytes8 bytesValue = bytes8(BitsManipulationLibrary.uint64_swapEndian(_value));
    mm.write(_index, _address, bytesValue);
  }
}


