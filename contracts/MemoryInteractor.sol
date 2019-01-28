/// @title MemoryInteractor.sol
pragma solidity ^0.5.0;

import "../contracts/AddressTracker.sol";
import "../contracts/ShadowAddresses.sol";
import "./lib/BitsManipulationLibrary.sol";

contract mmInterface {
  function read(uint256 _index, uint64 _address) external returns (bytes8);
  function write(uint256 _index, uint64 _address, bytes8 _value) external;
  function finishReplayPhase(uint256 _index) external;
}
// TO-DO: Rewrite this - MemoryRead/MemoryWrite should be private/internal and
// all reads/writes should be specific.

contract MemoryInteractor {
  mmInterface mm;

  constructor(address _addressTrackerAddress) public {
    address _mmAddress = AddressTracker(_addressTrackerAddress).getMMAddress();
    mm = mmInterface(_mmAddress);
  }
  // Sets
  function set_priv(uint256 _mmIndex, uint64 new_priv){
    write_iflags_PRV(_mmIndex, new_priv);
    write_ilrsc(_mmIndex, -1); // invalidate reserved address
  }

  // Reads
  function read_x(uint256 _mmIndex, uint64 _registerIndex) public returns (uint64){
    return memoryRead(_mmIndex, _registerIndex * 8);
  }
  function read_mideleg(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mideleg());
  }

  function read_medeleg(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_medeleg());
  }

  function read_pc(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_pc());
  }

  function read_stvec(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_stvec());
  }

  function read_mstatus(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mstatus());
  }

  function read_iflags(uint256 _mmIndex) public returns (uint64){
    return memoryRead(_mmIndex, ShadowAddresses.get_iflags());
  }

  function read_iflags_PRV(uint256 _mmIndex) public returns (uint64){
    return (memoryRead(_mmIndex, ShadowAddresses.get_iflags()) >> 2) & 3;
  }

  function memoryRead(uint256 _index, uint64 _address) public returns (uint64){
    return BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(_index, _address))
    );
  }

  // Writes

  function write_scause(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_scause(), _value);
  }

  function write_sepc(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_sepc(), _value);
  }

  function write_stval(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_stval(), _value);
  }

  function write_mstatus(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_mstatus(), _value);
  }

  function write_mcause(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_mcause(), _value);
  }
  function write_mepc(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_mepc(), _value);
  }
  function write_mtval(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_mtval(), _value);
  }
  function write_pc(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_pc(), _value);
  }
  function write_ilrsc(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_ilrsc(), _value);
  }

  function write_iflags_PRV(uint256 _mmIndex, uint64 _new_priv) public {
    uint64 iflags = read_iflags(_mmIndex);
    uint64 priv_mask = 3 << 2;

    // Clears bits 3 and 2 of iflags and use or to set new value
    iflags = (iflags & (~priv_mask)) | (_new_priv << 2);

    memoryWrite(_mmIndex, ShadowAddresses.get_iflags(), iflags);
  }

  function write_x(uint256 _mmIndex, uint64 _registerIndex, uint64 _value) public {
    //Address = registerIndex * sizeof(uint64)
    memoryWrite(_mmIndex, _registerIndex * 8, _value);
  }

  function memoryWrite(uint256 _index, uint64 _address, uint64 _value) public {
    bytes8 bytesValue = bytes8(BitsManipulationLibrary.uint64_swapEndian(_value));
    mm.write(_index, _address, bytesValue);
  }
}


