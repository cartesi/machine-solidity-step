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

  function read_mie(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mie());
  }

  function read_mcause(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mcause());
  }

  function read_minstret(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_minstret());
  }

  function read_mcycle(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mcycle());
  }

  function read_mcounteren(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mcounteren());
  }

  function read_mepc(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mepc());
  }
  function read_mip(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mip());
  }
  function read_mtval(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mtval());
  }
  function read_mvendorid(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mvendorid());
  }
  function read_marchid(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_marchid());
  }
   function read_mimpid(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mimpid());
  }
  function read_mscratch(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mscratch());
  }

  function read_satp(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_satp());
  }
  function read_scause(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_scause());
  }

  function read_sepc(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_sepc());
  }

  function read_scounteren(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_scounteren());
  }
  function read_stval(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_stval());
  }
  function read_mideleg(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mideleg());
  }

  function read_medeleg(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_medeleg());
  }

  function read_mtvec(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mtvec());
  }

  function read_pc(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_pc());
  }

  function read_sscratch(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_sscratch());
  }

  function read_stvec(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_stvec());
  }

  function read_mstatus(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_mstatus());
  }

  function read_misa(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_misa());
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


