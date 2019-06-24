/// @title MemoryInteractor.sol
pragma solidity ^0.5.0;

import "../contracts/ShadowAddresses.sol";
import "../contracts/HTIF.sol";
import "../contracts/CLINT.sol";
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

  constructor(address _mmAddress) public {
    mm = mmInterface(_mmAddress);
  }

  // Change phase
  function finishReplayPhase(uint256 _mmIndex) public {
    mm.finishReplayPhase(_mmIndex);
  }
  // Reads
  function read_x(uint256 _mmIndex, uint64 _registerIndex) public returns (uint64){
      //Address = registerIndex * sizeof(uint64)
    return memoryRead(_mmIndex, _registerIndex * 8);
  }

  function read_clint_mtimecmp(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, CLINT.CLINT_MTIMECMP());
  }

  function read_htif_fromhost(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, HTIF.HTIF_FROMHOST_ADDR());
  }

  function read_htif_tohost(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, HTIF.HTIF_TOHOST_ADDR());
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

  function read_ilrsc(uint256 _mmIndex) public returns (uint64) {
    return memoryRead(_mmIndex, ShadowAddresses.get_ilrsc());
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

  function read_memory(uint256 _mmIndex, uint64 paddr, uint64 wordSize) public returns (uint64) {
    // get relative address from unaligned paddr
    uint64 closestStartAddr = paddr & uint64(~7);
    uint64 relAddr = paddr - closestStartAddr;

    // value just like its on MM, without endianess swap
    uint64 val = pure_memoryRead(_mmIndex, closestStartAddr);

    // mask to clean a piece of the value that was on memory
    uint64 value_mask = ((2 ** wordSize) - 1) << (64 - (relAddr*8 + wordSize));
    val = (val & value_mask) << relAddr*8;
    return BitsManipulationLibrary.uint64_swapEndian(val);
  }

  // Sets
  function set_priv(uint256 _mmIndex, uint64 new_priv) public {
    write_iflags_PRV(_mmIndex, new_priv);
    write_ilrsc(_mmIndex, uint64(-1)); // invalidate reserved address
  }

  function set_iflags_I(uint256 _mmIndex, bool idle) public {
    uint64 iflags = read_iflags(_mmIndex);
    uint64 maskI = 2;

    if (idle) {
      iflags = (iflags | maskI);
    } else {
      iflags = (iflags & ~maskI);
    }

    memoryWrite(_mmIndex, ShadowAddresses.get_iflags(), iflags);
  }

  function set_iflags_H(uint256 _mmIndex, bool halt) public {
    uint64 iflags = read_iflags(_mmIndex);
    uint64 maskH = 1;

    if (halt) {
      iflags = (iflags | maskH);
    } else {
      iflags = (iflags & ~maskH);
    }

    memoryWrite(_mmIndex, ShadowAddresses.get_iflags(), iflags);
  }

  function set_mip(uint256 _mmIndex, uint64 mask) public {
    uint64 mip = read_mip(_mmIndex);
    mip |= mask;

    write_mip(_mmIndex, mip);

    set_iflags_I(_mmIndex, false);
  }

  function reset_mip(uint256 _mmIndex, uint64 mask) public {
    uint64 mip = read_mip(_mmIndex);
    mip &= ~mask;
    write_mip(_mmIndex, mip);
  }

  // Writes
  function write_mie(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_mie(), _value);
  }

  function write_stvec(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_stvec(), _value);
  }

  function write_sscratch(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_sscratch(), _value);
  }

  function write_mip(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_mip(), _value);
  }

  function write_satp(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_satp(), _value);
  }

  function write_medeleg(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_medeleg(), _value);
  }

  function write_mideleg(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_mideleg(), _value);
  }

  function write_mtvec(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_mtvec(), _value);
  }

  function write_mcounteren(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_mcounteren(), _value);
  }

  function write_minstret(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_minstret(), _value);
  }

  function write_mscratch(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_mscratch(), _value);
  }

  function write_scounteren(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, ShadowAddresses.get_scounteren(), _value);
  }

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

  function write_clint_mtimecmp(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, CLINT.CLINT_MTIMECMP(), _value);
  }

  function write_htif_fromhost(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, HTIF.HTIF_FROMHOST_ADDR(), _value);
  }

  function write_htif_tohost(uint256 _mmIndex, uint64 _value) public {
    memoryWrite(_mmIndex, HTIF.HTIF_TOHOST_ADDR(), _value);
  }

  function write_iflags_PRV(uint256 _mmIndex, uint64 _new_priv) public {
    uint64 iflags = read_iflags(_mmIndex);
    uint64 priv_mask = 3 << 2;

    // Clears bits 3 and 2 of iflags and use or to set new value
    iflags = (iflags & (~priv_mask)) | (_new_priv << 2);

    memoryWrite(_mmIndex, ShadowAddresses.get_iflags(), iflags);
  }

  function write_memory(uint256 _mmIndex, uint64 paddr, uint64 value, uint64 wordSize) public {
    uint64 numberOfBytes = wordSize / 8;

    if (numberOfBytes == 8) {
      memoryWrite(_mmIndex, paddr, value);
    } else {
      // get relative address from unaligned paddr
      uint64 closestStartAddr = paddr & uint64(~7);
      uint64 relAddr = paddr - closestStartAddr;

      // oldValue just like its on MM, without endianess swap
      uint64 oldVal = pure_memoryRead(_mmIndex, closestStartAddr);

      // Mask to clean a piece of the value that was on memory
      uint64 old_value_mask = ((2 ** wordSize) - 1) << (64 - (relAddr*8 + wordSize));
      uint64 value_mask = ((2 ** wordSize) - 1) << (64 - wordSize);

      // value is big endian, need to swap before further operation
      uint64 value_swap = BitsManipulationLibrary.uint64_swapEndian(value);

      uint64 newValue = ((oldVal & ~old_value_mask) | ((value_swap & value_mask) >> (relAddr * 8)));
      newValue = BitsManipulationLibrary.uint64_swapEndian(newValue);

      memoryWrite(_mmIndex, closestStartAddr, newValue);
    }
  }

  function write_x(uint256 _mmIndex, uint64 _registerIndex, uint64 _value) public {
    //Address = registerIndex * sizeof(uint64)
    //bytes8 bytesValue = bytes8(BitsManipulationLibrary.uint64_swapEndian(_value));
    memoryWrite(_mmIndex, _registerIndex * 8, _value);
  }

  // Internal functions
  function memoryRead(uint256 _index, uint64 _address) public returns (uint64){
    //return uint64(mm.read(_index, _address));
    return BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(_index, _address))
    );
  }

  // Memory Read endianess swap
  function pure_memoryRead(uint256 _index, uint64 _address) public returns (uint64){
    return uint64(mm.read(_index, _address));
  }

  function memoryWrite(uint256 _index, uint64 _address, uint64 _value) public {
    bytes8 bytesValue = bytes8(BitsManipulationLibrary.uint64_swapEndian(_value));
    mm.write(_index, _address, bytesValue);
  }

  // Memory Write without endianess swap
  function pure_memoryWrite(uint256 _index, uint64 _address, uint64 _value) public {
    mm.write(_index, _address, bytes8(_value));
  }
}

