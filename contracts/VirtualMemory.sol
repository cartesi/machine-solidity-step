// @title Virtual Memory
pragma solidity ^0.5.0;

import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "../contracts/MemoryInteractor.sol";
import "../contracts/PMA.sol";
import "../contracts/CLINT.sol";
import "../contracts/HTIF.sol";
import "../contracts/Exceptions.sol";

library VirtualMemory {

  // Variable positions on their respective array.
  // This is not an enum because enum assumes the type from the number of variables
  // So we would have to explicitly cast to uint256 on every single access
  uint256 constant priv = 0;
  uint256 constant mode= 1;
  uint256 constant vaddr_shift = 2;
  uint256 constant pte_size_log2= 3;
  uint256 constant vpn_bits= 4;
  uint256 constant satp_ppn_bits = 5;

  uint256 constant vaddr_mask = 0;
  uint256 constant pte_addr = 1;
  uint256 constant mstatus = 2;
  uint256 constant satp = 3;
  uint256 constant vpn_mask = 4;
  uint256 constant pte = 5;

  // Write/Read Virtual Address variable indexes
  uint256 constant offset = 0;
  uint256 constant pma_start = 1;
  uint256 constant pma_length = 2;
  uint256 constant paddr = 3;
  uint256 constant val = 4;

  // \brief Read word to virtual memory
  // \param wordsize can be uint8, uint16, uint32 or uint64
  // \param vaddr is the words virtual address 
  // \returns True if write was succesfull, false if not.
  // \returns Word with receiveing value.
  function read_virtual_memory(MemoryInteractor mi, uint256 mmIndex, uint256 wordSize, uint64 vaddr)
  public returns(bool, uint64) {
    uint64[6] memory uint64vars;
    if (vaddr & (wordSize/8 - 1) != 0){
      // Word is not aligned - raise exception
      Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_LOAD_ADDRESS_MISALIGNED(), vaddr);
      return (false, 0);
    } else {
     (bool translate_success, uint64 paddr) = translate_virtual_address(mi, mmIndex, vaddr, RiscVConstants.PTE_XWR_WRITE_SHIFT());
      if (!translate_success) {
        // translation failed - raise exception
        Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_LOAD_PAGE_FAULT(), vaddr);
        return (false, 0);
      }
      (uint64vars[pma_start], uint64vars[pma_length]) = PMA.find_pma_entry(mi, mmIndex, paddr);
      if (PMA.pma_get_istart_E(uint64vars[pma_start]) || !PMA.pma_get_istart_R(uint64vars[pma_start])) {
        // PMA is either excluded or we dont have permission to write - raise exception
        Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_LOAD_ACCESS_FAULT(), vaddr);
        return (false, 0);
      } else if (PMA.pma_get_istart_M(uint64vars[pma_start])) {
         return (true, mi.read_memory(mmIndex, paddr));
      }else {
        bool success = false;
        if (PMA.pma_is_HTIF(uint64vars[pma_start])) {
          (success, uint64vars[val]) = HTIF.htif_read(mi, mmIndex, uint64vars[pma_start], uint64vars[pma_length], paddr, wordSize);
        } else if (PMA.pma_is_CLINT(uint64vars[pma_start])) {
         (success, uint64vars[val]) = CLINT.clint_read(mi, mmIndex, uint64vars[pma_start], uint64vars[pma_length], paddr, wordSize);
        }
        if (!success) {
          Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_LOAD_ACCESS_FAULT(), vaddr);
        }
        return (success, uint64vars[val]);
      }
    }
  }

  // \brief Writes word to virtual memory
  // \param wordsize can be uint8, uint16, uint32 or uint64
  // \param vaddr is the words virtual address 
  // \param val is the value to be written
  // \returns True if write was succesfull, false if not.
  function write_virtual_memory(MemoryInteractor mi, uint256 mmIndex, uint64 wordSize, uint64 vaddr, uint64 val)
  public returns (bool) {
    uint64[6] memory uint64vars;

    if (vaddr & ((wordSize / 8) - 1) != 0){
      // Word is not aligned - raise exception
      Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_STORE_AMO_ADDRESS_MISALIGNED(), vaddr);
      return false;
    } else {
      bool translate_success;
     (translate_success, uint64vars[paddr]) = translate_virtual_address(mi, mmIndex, vaddr, RiscVConstants.PTE_XWR_WRITE_SHIFT());
      if (!translate_success) {
        // translation failed - raise exception
        Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_STORE_AMO_PAGE_FAULT(), vaddr);
        return false;
      }
      (uint64vars[pma_start], uint64vars[pma_length]) = PMA.find_pma_entry(mi, mmIndex, uint64vars[paddr]);

      if (PMA.pma_get_istart_E(uint64vars[pma_start]) || !PMA.pma_get_istart_W(uint64vars[pma_start])) {
        // PMA is either excluded or we dont have permission to write - raise exception
        Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_STORE_AMO_ACCESS_FAULT(), vaddr);
        return false;
      } else if (PMA.pma_get_istart_M(uint64vars[pma_start])) {
         //write to memory
         mi.write_memory(mmIndex, uint64vars[paddr], val, wordSize);
         return true;
      } else {

        if (PMA.pma_is_HTIF(uint64vars[pma_start])) {
          if (!HTIF.htif_write(mi, mmIndex, uint64vars[pma_start], uint64vars[pma_length], PMA.pma_get_start(uint64vars[pma_start]), val, wordSize)) {
            Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_STORE_AMO_ACCESS_FAULT(), vaddr);
            return false;
          }
        } else if (PMA.pma_is_CLINT(uint64vars[pma_start])) {
            if (!CLINT.clint_write(mi, mmIndex, uint64vars[pma_start], uint64vars[pma_length], PMA.pma_get_start(uint64vars[pma_start]), val, wordSize)) {
            Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_STORE_AMO_ACCESS_FAULT(), vaddr);
            return false;
          }
        }
        return true;
      }
    }
  }
  // Finds the physical address associated to the virtual address (vaddr).
  // Walks the page table until it finds a valid one. Returns a bool if the physical
  // address was succesfully found along with the address. Returns false and zer0
  // if something went wrong.

  // Virtual Address Translation proccess is defined, step by step on the following Reference:
  // Reference: riscv-priv-spec-1.10.pdf - Section 4.3.2, page 62.
  function translate_virtual_address(MemoryInteractor mi, uint256 mmIndex, uint64 vaddr, int xwr_shift)
  public returns(bool, uint64) {
    //TO-DO: check shift + mask
    //TO-DO: use bitmanipulation right shift

    // Through arrays we force variables that were being put on stack to be stored
    // in memory. It is more expensive, but the stack only supports 16 variables.
    uint64[6] memory uint64vars;
    int[6] memory intvars;

    // Reads privilege level on iflags register. The privilege level is located
    // on bits 2 and 3.
    // Reference: The Core of Cartesi, v1.02 - figure 1.
    intvars[priv] = (mi.memoryRead(mmIndex, ShadowAddresses.get_iflags()) >> 2) & 3;
    //emit Print("priv", uint(priv));

    //read_mstatus
    uint64vars[mstatus] = mi.memoryRead(mmIndex, ShadowAddresses.get_mstatus());

    //emit Print("mstatus", uint(mstatus));
    // When MPRV is set, data loads and stores use privilege in MPP
    // instead of the current privilege level (code access is unaffected)
    //TO-DO: Check this &/&& and shifts
    if((uint64vars[mstatus] & RiscVConstants.MSTATUS_MPRV_MASK() != 0) && (xwr_shift != RiscVConstants.PTE_XWR_CODE_SHIFT())){
      intvars[priv] = (uint64vars[mstatus] & RiscVConstants.MSTATUS_MPP_MASK())  >> RiscVConstants.MSTATUS_MPP_SHIFT();//(uint64vars[mstatus] >> RiscVConstants.MSTATUS_MPP_SHIFT()) & 3;
    }
    // Physical memory is mediated by Machine-mode so, if privilege is M-mode it 
    // does not use virtual Memory
    // Reference: riscv-priv-spec-1.7.pdf - Section 3.3, page 32.
    if(intvars[priv] == RiscVConstants.PRV_M()){
      return(true, vaddr);
    }

    // SATP - Supervisor Address Translation and Protection Register
    // Holds MODE, Physical page number (PPN) and address space identifier (ASID)
    // MODE is located on bits 60 to 63 for RV64.
    // Reference: riscv-priv-spec-1.10.pdf - Section 4.1.12, page 56.
    uint64vars[satp] = mi.memoryRead(mmIndex, ShadowAddresses.get_satp());
    //emit Print("satp", satp);
    // In RV64, mode can be
    //   0: Bare: No translation or protection
    //   8: sv39: Page-based 39-bit virtual addressing
    //   9: sv48: Page-based 48-bit virtual addressing
    // Reference: riscv-priv-spec-1.10.pdf - Table 4.3, page 57.
    intvars[mode] = (uint64vars[satp] >> 60) & 0xf;
    //emit Print("mode", uint(mode));

    if(intvars[mode] == 0){
      return(true, vaddr);
    } else if(intvars[mode] < 8 || intvars[mode] > 9){
      return(false, 0);
    }
    // Here we know we are in sv39 or sv48 modes

    // Page table hierarchy of sv39 has 3 levels, and sv48 has 4 levels
    int levels = intvars[mode] - 8 + 3;
    // Page offset are bits located from 0 to 11.
    // Then come levels virtual page numbers (VPN)
    // The rest of vaddr must be filled with copies of the
    // most significant bit in VPN[levels]
    // Hence, the use of arithmetic shifts here
    // Reference: riscv-priv-spec-1.10.pdf - Figure 4.16, page 63.

    //TO-DO: Use bitmanipulation library for arithmetic shift
    intvars[vaddr_shift] = RiscVConstants.XLEN() - (RiscVConstants.PG_SHIFT() + levels * 9);
    if(((int64(vaddr) << intvars[vaddr_shift]) >> intvars[vaddr_shift]) != int64(vaddr)){
      return(false, 0);
    }
    // The least significant 44 bits of satp contain the physical page number
    // for the root page table
    // Reference: riscv-priv-spec-1.10.pdf - Figure 4.12, page 57.
    intvars[satp_ppn_bits] = 44;
    // Initialize pte_addr with the base address for the root page table
    uint64vars[pte_addr] = (uint64vars[satp] & ((uint64(1) << intvars[satp_ppn_bits]) -1)) << RiscVConstants.PG_SHIFT();
    // All page table entries have 8 bytes
    // Each page table has 4k/pte_size entries
    // To index all entries, we need vpn_bits
    // Reference: riscv-priv-spec-1.10.pdf - Section 4.4.1, page 63.
    intvars[pte_size_log2] = 3;
    intvars[vpn_bits] = 12 - intvars[pte_size_log2];
    uint64vars[vpn_mask] = uint64((1 << intvars[vpn_bits]) - 1);

    for(int i = 0; i < levels; i++) {
      // Mask out VPN[levels -i-1]
      intvars[vaddr_shift] = RiscVConstants.PG_SHIFT() + intvars[vpn_bits] * (levels -1 -i);
      uint64 vpn = (vaddr >> intvars[vaddr_shift]) & uint64vars[vpn_mask];
      // Add offset to find physical address of page table entry
      uint64vars[pte_addr] += vpn << intvars[pte_size_log2];
      //Read page table entry from physical memory
      bool read_ram_succ;
      (read_ram_succ, uint64vars[pte]) = read_ram_uint64(mi, mmIndex, uint64vars[pte_addr]);

      if(!read_ram_succ){
        return(false, 0);
      }

      // The OS can mark page table entries as invalid,
      // but these entries shouldn't be reached during page lookups
      //TO-DO: check if condition
      if((uint64vars[pte] & RiscVConstants.PTE_V_MASK()) == 0){
        return(false, 0);
      }
      // Clear all flags in least significant bits, then shift back to multiple of page size to form physical address
      uint64 ppn = (uint64vars[pte] >> 10) << RiscVConstants.PG_SHIFT();
      // Obtain X, W, R protection bits
      // X, W, R bits are located on bits 1 to 3 on physical address
      // Reference: riscv-priv-spec-1.10.pdf - Figure 4.18, page 63.
      int xwr = (uint64vars[pte] >> 1) & 7;
      // xwr !=0 means we are done walking the page tables
      if(xwr !=0){
        // These protection bit combinations are reserved for future use
        if(xwr == 2 || xwr == 6){
          return (false, 0);
        }
        // (We know we are not PRV_M if we reached here)
        if(intvars[priv] == RiscVConstants.PRV_S()){
          // If SUM is set, forbid S-mode code from accessing U-mode memory
          //TO-DO: check if condition
          if((uint64vars[pte] & RiscVConstants.PTE_U_MASK() != 0) && ((uint64vars[mstatus] & RiscVConstants.MSTATUS_SUM_MASK())) == 0){
            return (false, 0);
          }
        }else{
          // Forbid U-mode code from accessing S-mode memory
          if((uint64vars[pte] & RiscVConstants.PTE_U_MASK()) == 0){
            return (false, 0);
          }
        }
        // MXR allows to read access to execute-only pages
        if(uint64vars[mstatus] & RiscVConstants.MSTATUS_MXR_MASK() != 0){
          //Set R bit if X bit is set
          xwr = xwr | (xwr >> 2);
        }
        // Check protection bits against request access
        if(((xwr >> xwr_shift) & 1) == 0){
          return (false, 0);
        }
        // Check page, megapage, and gigapage alignment
        uint64vars[vaddr_mask] = (uint64(1) << intvars[vaddr_shift]) - 1;
        if(ppn & uint64vars[vaddr_mask] != 0){
          return (false, 0);
        }
        // Decide if we need to update access bits in pte
        bool update_pte = (uint64vars[pte] & RiscVConstants.PTE_A_MASK() == 0) || ((uint64vars[pte] & RiscVConstants.PTE_D_MASK() == 0) && xwr_shift == RiscVConstants.PTE_XWR_WRITE_SHIFT());

        uint64vars[pte] |= RiscVConstants.PTE_A_MASK();

        if(xwr_shift == RiscVConstants.PTE_XWR_WRITE_SHIFT()){
          uint64vars[pte] = uint64vars[pte] | RiscVConstants.PTE_D_MASK();
        }
        // If so, update pte
        if(update_pte){
          write_ram_uint64(mi, mmIndex, uint64vars[pte_addr], uint64vars[pte]);
        }
        // Add page offset in vaddr to ppn to form physical address
        return(true, (vaddr & uint64vars[vaddr_mask]) | (ppn & ~uint64vars[vaddr_mask]));
      }else {
        uint64vars[pte_addr] = ppn;
      }
    }
    return(false, 0);
  }

  function read_ram_uint64(MemoryInteractor mi, uint256 mmIndex, uint64 paddr)
  internal returns (bool, uint64) {
    uint64 val;
    (uint64 pma_start, uint64 pma_length) = PMA.find_pma_entry(mi, mmIndex, paddr);
    if (!PMA.pma_get_istart_M(pma_start) || !PMA.pma_get_istart_R(pma_start)) {
      return (false, 0);
    }
    return (true, mi.read_memory(mmIndex, paddr));
  }

  function write_ram_uint64(MemoryInteractor mi, uint256 mmIndex, uint64 paddr, uint64 val)
  internal returns (bool) {
    (uint64 pma_start, uint64 pma_length) = PMA.find_pma_entry(mi, mmIndex, paddr);
    if (!PMA.pma_get_istart_M(pma_start) || !PMA.pma_get_istart_W(pma_start)) {
      return false;
    }
    mi.write_memory(mmIndex, paddr, val, 64);
    return true;
  }

}
