// @title HTIF
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";

// Host-Target-Interface (HTIF) mediates communcation with external world.
// Its active addresses are 0x40000000(tohost) and 0x40000008(from host)
// Reference: The Core of Cartesi, v1.02 - Section 3.2 - The Board
library HTIF {

  uint64 constant HTIF_TOHOST_ADDR_CONST = 0x40008000;
  uint64 constant HTIF_FROMHOST_ADDR_CONST = 0x40008008;

  // event Print(string a, uint64 b);
  // \brief reads htif
  // \param pma_start_word first word, defines pma's start
  // \param pma_length_word second word, defines pma's length
  // \param offset can be uint8, uint16, uint32 or uint64
  // \param wordsize can be uint8, uint16, uint32 or uint64
  // \return bool if read was successfull
  // \return uint64 pval
  function htif_read(MemoryInteractor mi, uint256 mmIndex, uint64 pma_start_word, uint64 pma_length_word, uint64 addr, uint64 wordSize)
  public returns (bool, uint64) {
    // HTIF reads must be aligned and 8 bytes
    if(wordSize != 64 || (addr & 7) != 0) {
      return (false, 0);
    }

    if (addr == HTIF_TOHOST_ADDR_CONST){
      return (true, mi.read_htif_tohost(mmIndex));
    } else if (addr == HTIF_FROMHOST_ADDR_CONST){
      return (true, mi.read_htif_fromhost(mmIndex));
    } else {
      return (false, 0);
    }
  }

  // \brief write htif
  // \param pma_start_word first word, defines pma's start
  // \param pma_length_word second word, defines pma's length
  // \param offset can be uint8, uint16, uint32 or uint64
  // \param val value to be written
  // \param wordsize can be uint8, uint16, uint32 or uint64
  // \return bool if write was successfull
  function htif_write(MemoryInteractor mi, uint256 mmIndex, uint64 pma_start_word, uint64 pma_length_word, uint64 addr, uint64 val, uint64 wordSize)
  public returns (bool) {
    // HTIF writes must be aligned and 8 bytes
    if(wordSize != 64 || (addr & 7) != 0) {
      return false;
    }
    if (addr == HTIF_TOHOST_ADDR_CONST){
      return htif_write_tohost(mi, mmIndex, val);
    } else if (addr == HTIF_FROMHOST_ADDR_CONST){
      return htif_write_fromhost(mi, mmIndex, val);
    } else {
      return false;
    }
  }

  // Internal functions
  function htif_write_fromhost(MemoryInteractor mi, uint256 mmIndex, uint64 val)
  internal returns (bool){
    mi.write_htif_fromhost(mmIndex, val);
    // TO-DO: check if h is interactive? reset from host? poll_console?
    return true;
  }

  function htif_write_tohost(MemoryInteractor mi, uint256 mmIndex, uint64 tohost)
  internal returns (bool){
    uint32 device = uint32(tohost >> 56);
    uint32 cmd = uint32((tohost >> 48) & 0xff);
    uint64 payload = uint32((tohost & (~(uint256(1) >> 16))));

    mi.write_htif_tohost(mmIndex, tohost);

    if (device == 0 && cmd == 0 && (payload & 1) != 0) {
      return htif_write_halt(mi, mmIndex);
    } else if (device == 1 && cmd == 1) {
      return htif_write_putchar(mi, mmIndex);
    } else if (device == 1 && cmd == 0) {
      return htif_write_getchar(mi, mmIndex);
    }
    return true;
  }

  function htif_write_halt(MemoryInteractor mi, uint256 mmIndex) internal 
  returns (bool) {
    //set iflags to halted
    mi.set_iflags_H(mmIndex, true);
    return true;
  }
  function htif_write_putchar(MemoryInteractor mi, uint256 mmIndex) internal 
  returns (bool) {
    mi.write_htif_tohost(mmIndex, 0); // Acknowledge command (?)
    // TO-DO: what to do in the blockchain? Generate event?
    mi.write_htif_fromhost(mmIndex, (uint64(1) << 56) | uint64(1) << 48);
    return true;
  }

  function htif_write_getchar(MemoryInteractor mi, uint256 mmIndex) internal 
  returns (bool) {
    mi.write_htif_tohost(mmIndex, 0); // Acknowledge command (?)
    return true;
  }

  // getters
  function HTIF_TOHOST_ADDR() public returns (uint64) {
    return HTIF_TOHOST_ADDR_CONST;
  }
  function HTIF_FROMHOST_ADDR() public returns (uint64) {
    return HTIF_FROMHOST_ADDR_CONST;
  }
}
