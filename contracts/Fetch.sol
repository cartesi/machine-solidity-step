/// @title Fetch
pragma solidity ^0.5.0;

import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./lib/BitsManipulationLibrary.sol";
import "../contracts/MemoryInteractor.sol";
import "../contracts/PMA.sol";

contract Fetch {
  MemoryInteractor mi;
  uint256 mmIndex;
   // Through struct we force variables that were being put on stack to be stored
  // in memory. It is more expensive, but the stack only supports 16 variables.
  struct TranslateVars{
    int priv;
    int mode;
    int vaddr_shift;
    int pte_size_log2;
    int vpn_bits;
    int satp_ppn_bits;

//    uint64 vaddr;
    uint64 vaddr_mask;
    uint64 pte_addr;
    uint64 mstatus;
    uint64 satp;
    uint64 vpn_mask;

  }

  function fetch_insn(uint256 _mmIndex, address _memoryInteractorAddress) public returns (fetch_status, uint32, uint64){
    mi = MemoryInteractor(_memoryInteractorAddress); 
    mmIndex = _mmIndex;

    bool translateBool;
    uint64 paddr;

    //read_pc
    uint64 pc = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_pc()))
    );
    (translateBool, paddr) = translate_virtual_address(pc, RiscVConstants.PTE_XWR_CODE_SHIFT());

    //translate_virtual_address failed
    if(!translateBool){
      //raise_exception(CAUSE_FETCH_PAGE_FAULT)

      //returns fetch_exception and returns zero as insn and pc
      return (fetch_status.exception, 0, 0);
    }

    // Finds the range in memory in which the physical address is located
    // Returns start and length words from pma
    (uint64 pma_start, uint64 pma_length) = PMA.find_pma_entry(mi, mmIndex, paddr);

    //emit Print("pma_entry.start", pma_entry.start);
    //emit Print("pma_entry.length", pma_entry.length);

    // M flag defines if the pma range is in memory 
    // X flag defines if the pma is executable
    // If the pma is not memory or not executable - this is a pma violation
    // Reference: The Core of Cartesi, v1.02 - section 3.2 the board - page 5.

    if(!PMA.pma_get_istart_M(pma_start) || !PMA.pma_get_istart_X(pma_start)){

      //emit Print("CAUSE_FETCH_FAULT", paddr);
      //raise_exception(CAUSE_FETCH_FAULT)
//      return fetch_status.exception;
    }

    //emit Print("paddr/insn", paddr);
    //will this actually return the instruction? Should it be 32bits?
    uint32 insn = uint32(BitsManipulationLibrary.uint64_swapEndian(
      uint64(mi.memoryRead(mmIndex, paddr))
    ));
    //emit Print("insn", uint(insn));
    return (fetch_status.success, insn, pc);

  }
  // Finds the physical address associated to the virtual address (vaddr).
  // Walks the page table until it finds a valid one. Returns a bool if the physical
  // address was succesfully found along with the address. Returns false and zer0
  // if something went wrong.

  // Virtual Address Translation proccess is defined, step by step on the following Reference:
  // Reference: riscv-priv-spec-1.10.pdf - Section 4.3.2, page 62.
  function translate_virtual_address(uint64 vaddr, int xwr_shift) public returns(bool, uint64){
    //TO-DO: check shift + mask
    //TO-DO: use bitmanipulation right shift
    TranslateVars memory vars;

    // Reads privilege level on iflags register. The privilege level is located
    // on bits 2 and 3.
    // Reference: The Core of Cartesi, v1.02 - figure 1.
    vars.priv = (BitsManipulationLibrary.uint64_swapEndian(
      uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_iflags())
    )) >> 2) & 3;
    //emit Print("priv", uint(priv));

    //read_mstatus
    vars.mstatus = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_mstatus()))
    );

    //emit Print("mstatus", uint(mstatus));
    // When MPRV is set, data loads and stores use privilege in MPP
    // instead of the current privilege level (code access is unaffected)
    //TO-DO: Check this &/&& and shifts
    if((vars.mstatus & RiscVConstants.MSTATUS_MPRV() != 0) && (xwr_shift != RiscVConstants.PTE_XWR_CODE_SHIFT())){
      vars.priv = (vars.mstatus >> RiscVConstants.MSTATUS_MPP_SHIFT()) & 3;
    }
    // Physical memory is mediated by Machine-mode so, if privilege is M-mode it 
    // does not use virtual Memory
    // Reference: riscv-priv-spec-1.7.pdf - Section 3.3, page 32.
    if(vars.priv == RiscVConstants.PRV_M()){
      return(true, vaddr);
    }

    // SATP - Supervisor Address Translation and Protection Register
    // Holds MODE, Physical page number (PPN) and address space identifier (ASID)
    // MODE is located on bits 60 to 63 for RV64.
    // Reference: riscv-priv-spec-1.10.pdf - Section 4.1.12, page 56.
    vars.satp = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mi.memoryRead(mmIndex, ShadowAddresses.get_satp()))
    );
    //emit Print("satp", satp);
    // In RV64, mode can be
    //   0: Bare: No translation or protection
    //   8: sv39: Page-based 39-bit virtual addressing
    //   9: sv48: Page-based 48-bit virtual addressing
    // Reference: riscv-priv-spec-1.10.pdf - Table 4.3, page 57.
    vars.mode = (vars.satp >> 60) & 0xf;
    //emit Print("mode", uint(mode));

    if(vars.mode == 0){
      return(true, vaddr);
    } else if(vars.mode < 8 || vars.mode > 9){
      return(false, 0);
    }
    // Here we know we are in sv39 or sv48 modes

    // Page table hierarchy of sv39 has 3 levels, and sv48 has 4 levels
    int levels = vars.mode - 8 + 3;
    // Page offset are bits located from 0 to 11.
    // Then come levels virtual page numbers (VPN)
    // The rest of vaddr must be filled with copies of the
    // most significant bit in VPN[levels]
    // Hence, the use of arithmetic shifts here
    // Reference: riscv-priv-spec-1.10.pdf - Figure 4.16, page 63.

    //TO-DO: Use bitmanipulation library for arithmetic shift
    vars.vaddr_shift = RiscVConstants.XLEN() - (RiscVConstants.PG_SHIFT() + levels * 9);
    if(((int64(vaddr) << vars.vaddr_shift) >> vars.vaddr_shift) != int64(vaddr)){
      return(false, 0);
    }
    // The least significant 44 bits of satp contain the physical page number
    // for the root page table
    // Reference: riscv-priv-spec-1.10.pdf - Figure 4.12, page 57.
    vars.satp_ppn_bits = 44;
    // Initialize pte_addr with the base address for the root page table
    vars.pte_addr = (vars.satp & ((uint64(1) << vars.satp_ppn_bits) -1)) << RiscVConstants.PG_SHIFT();
    // All page table entries have 8 bytes
    // Each page table has 4k/pte_size entries
    // To index all entries, we need vpn_bits
    // Reference: riscv-priv-spec-1.10.pdf - Section 4.4.1, page 63.
    vars.pte_size_log2 = 3;
    vars.vpn_bits = 12 - vars.pte_size_log2;
    vars.vpn_mask = uint64((1 << vars.vpn_bits) - 1);

    for(int i = 0; i < levels; i++) {
      // Mask out VPN[levels -i-1]
      vars.vaddr_shift = RiscVConstants.PG_SHIFT() + vars.vpn_bits * (levels -1 -i);
      uint64 vpn = (vaddr >> vars.vaddr_shift) & vars.vpn_mask;
      // Add offset to find physical address of page table entry
      vars.pte_addr += vpn << vars.pte_size_log2;
      //Read page table entry from physical memory
      uint64 pte = 0;

      //TO-DO: Implement read_ram_uint64(a, pte_addr, &pte)
      // if(!read_ram_uint64(vars.pte_addr)){
      //   return(false, 0);
      // }

      // The OS can mark page table entries as invalid,
      // but these entries shouldn't be reached during page lookups
      //TO-DO: check if condition
      if((pte & RiscVConstants.PTE_V_MASK()) == 0){
        return(false, 0);
      }
      // Clear all flags in least significant bits, then shift back to multiple of page size to form physical address
      uint64 ppn = (pte >> 10) << RiscVConstants.PG_SHIFT();
      // Obtain X, W, R protection bits
      // X, W, R bits are located on bits 1 to 3 on physical address
      // Reference: riscv-priv-spec-1.10.pdf - Figure 4.18, page 63.
      int xwr = (pte >> 1) & 7;
      // xwr !=0 means we are done walking the page tables
      if(xwr !=0){
        // These protection bit combinations are reserved for future use
        if(xwr == 2 || xwr == 6){
          return (false, 0);
        }
        // (We know we are not PRV_M if we reached here)
        if(vars.priv == RiscVConstants.PRV_S()){
          // If SUM is set, forbid S-mode code from accessing U-mode memory
          //TO-DO: check if condition
          if((pte & RiscVConstants.PTE_U_MASK() != 0) && ((vars.mstatus & RiscVConstants.MSTATUS_SUM())) == 0){
            return (false, 0);
          }
        }else{
          // Forbid U-mode code from accessing S-mode memory
          if((pte & RiscVConstants.PTE_U_MASK()) == 0){
            return (false, 0);
          }
        }
        // MXR allows to read access to execute-only pages
        if(vars.mstatus & RiscVConstants.MSTATUS_MXR() != 0){
          //Set R bit if X bit is set
          xwr = xwr | (xwr >> 2);
        }
        // Check protection bits against request access
        if(((xwr >> xwr_shift) & 1) == 0){
          return (false, 0);
        }
        // Check page, megapage, and gigapage alignment
        vars.vaddr_mask = (uint64(1) << vars.vaddr_shift) - 1;
        if(ppn & vars.vaddr_mask != 0){
          return (false, 0);
        }
        // Decide if we need to update access bits in pte
        bool update_pte = (pte & RiscVConstants.PTE_A_MASK() == 0) || ((pte & RiscVConstants.PTE_D_MASK() == 0) && xwr_shift == RiscVConstants.PTE_XWR_WRITE_SHIFT());

        if(xwr_shift == RiscVConstants.PTE_XWR_WRITE_SHIFT()){
          pte = pte | RiscVConstants.PTE_D_MASK();
        }
        // If so, update pte
        if(update_pte){
          //TO-DO: write_ram_uint64
          //write_ram_uint64(a, vars.pte_addr,pte);
        }
        // Add page offset in vaddr to ppn to form physical address
        return(true, (vaddr * vars.vaddr_mask) | (ppn & ~vars.vaddr_mask));
      }else {
        vars.pte_addr = ppn;
      }
    }
    return(false, 0);
  }

  enum fetch_status {
    exception, //failed: exception raised
    success
  }
}
