/// @title Monolithic RiscV
pragma solidity ^0.5.0;

//Libraries
import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./lib/BitsManipulationLibrary.sol";

contract mmInterface {
  function read(uint256 _index, uint64 _address) external returns (bytes8);
  function write(uint256 _index, uint64 _address, bytes8 _value) external;
  function finishReplayPhase(uint256 _index) external;
}

//TO-DO: use instantiator pattern so we can always use same instance of mm/pc etc
contract MonolithicRiscV {
  event Print(string message, uint value);

  //Real Storage variables
  PMAEntry pma_entry; //cannot return struct without experimental pragma
  mmInterface mm;
  uint256 mmIndex; //this has to be removed
  //Should not be Storage - but stack too deep
  //this will probably be ok when we split it into a bunch of different calls
  uint64 pc = 0;
  uint32 insn = 0;
  int priv;
  uint64 mstatus;
  uint64 satp;
  int mode;
  int levels;
  uint64 vaddr;
  uint64 vaddr_mask;
  uint64 paddr;
  int vaddr_shift;
  uint64 pte_addr;
  int pte_size_log2;
  int vpn_bits;
  //structs

  // PMA stands for Physical Memory Attributes - it is defined as two 64 bit words
  // The first word defines start and flags and the second defines length.
  // Reference: The Core of Cartesi, v1.02 - figure 2.
  struct PMAEntry{
    uint64 start;
    uint64 length;
    bool R;
    bool W;
    bool X;
    bool IR;
    bool IW;
  }

  function step(uint _mmIndex, address _memoryManagerAddress) public returns (interpreter_status){
    mmIndex = _mmIndex; //TO-DO: Remove this - should trickle down
    mm = mmInterface(_memoryManagerAddress);
    // Every read performed by mm.read or mm . write should be followed by an 
    // endianess swap from little endian to big endian. This is the case because
    // EVM is big endian but RiscV is little endian.
    // Reference: riscv-spec-v2.2.pdf - Preface to Version 2.0
    // Reference: Ethereum yellowpaper - Version 69351d5
    //            Appendix H. Virtual Machine Specification

    // Read iflags register and check its H flag, to see if machine is halted.
    // If machine is halted - nothing else to do. H flag is stored on the least
    // signficant bit on iflags register.
    // Reference: The Core of Cartesi, v1.02 - figure 1.
    uint64 iflags = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(mmIndex, ShadowAddresses.get_iflags()))
    );
    //emit Print("iflags", uint(iflags));
    if((iflags & 1) != 0){
      //machine is halted
      return interpreter_status.success;
    }
    //Raise the highest priority interrupt
    raise_interrupt_if_any();

    if(fetch_insn() == fetch_status.success){
      // If fetch was successfull, tries to execute instruction
      //emit Print("fetch.status successfull", 0);
      if(execute_insn() == execute_status.retired){
        // If execute_insn finishes successfully we need to update the number of
        // retired instructions. This number is stored on minstret CSR.
        // Reference: riscv-priv-spec-1.10.pdf - Table 2.5, page 12.
        uint64 minstret = BitsManipulationLibrary.uint64_swapEndian(
          uint64(mm.read(mmIndex, ShadowAddresses.get_minstret()))
        );
        //emit Print("minstret", uint(minstret));
        minstret = BitsManipulationLibrary.uint64_swapEndian(minstret + 1);
        mm.write(mmIndex, ShadowAddresses.get_minstret(), bytes8(minstret ));
      }
    }
    // Last thing that has to be done in a step is to update the cycle counter.
    // The cycle counter is stored on mcycle CSR.
    // Reference: riscv-priv-spec-1.10.pdf - Table 2.5, page 12.
    uint64 mcycle = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(mmIndex, ShadowAddresses.get_mcycle()))
    );
    //emit Print("mcycle", uint(mcycle));
    mcycle = BitsManipulationLibrary.uint64_swapEndian(mcycle + 1);
    mm.write(mmIndex, ShadowAddresses.get_mcycle(), bytes8(mcycle));
    return interpreter_status.success;
  }

  function execute_insn() public returns (execute_status) {
    // OPCODE is located on bit 0 - 6 of the following types of 32bits instructions:
    // R-Type, I-Type, S-Trype and U-Type
    // Reference: riscv-spec-v2.2.pdf - Figure 2.2 - Page 11
    uint32 opcode = RiscVDecoder.inst_opcode(insn);

    // Find instruction associated with that opcode
    // Sometimes the opcode fully defines the associated instructions, but most
    // of the times it only specifies which group it belongs to.
    // For example, an opcode of: 01100111 is always a LUI instruction but an
    // opcode of 1100011 might be BEQ, BNE, BLT etc
    // Reference: riscv-spec-v2.2.pdf - Table 19.2 - Page 104
    bytes32 insn_or_group = RiscVDecoder.opinsn(opcode);

    // TO-DO: We have to find a way to do this - insn_or_group should return a
    // pointer to a function - that can be either a direct instrunction or a branch
    if(insn_or_group == bytes32("AUIPC")){
      //emit Print("opcode AUIPC", opcode);
      return execute_auipc();
    }
  }
    //AUIPC forms a 32-bit offset from the 20-bit U-immediate, filling in the 
    // lowest 12 bits with zeros, adds this offset to pc and store the result on rd.
    // Reference: riscv-spec-v2.2.pdf -  Page 14
  function execute_auipc() public returns (execute_status){
    uint32 rd = RiscVDecoder.insn_rd(insn) * 8; //8 = sizeOf(uint64)
    //emit Print("execute_auipc RD", uint(rd));
    if(rd != 0){
      mm.write(mmIndex, rd, bytes8(BitsManipulationLibrary.uint64_swapEndian(
        pc + uint64(RiscVDecoder.insn_U_imm(insn)))
      ));
     // emit Print("pc", uint(pc));
     // emit Print("ins_u_imm", uint(RiscVDecoder.insn_U_imm(insn)));
    }
    return advance_to_next_insn();
  }

  function advance_to_next_insn() public returns (execute_status){
    pc = BitsManipulationLibrary.uint64_swapEndian(pc + 4);
    mm.write(mmIndex, ShadowAddresses.get_pc(), bytes8(pc));
    //emit Print("advance_to_next", 0);
    return execute_status.retired;
  }
  function fetch_insn() public returns (fetch_status){
    bool translateBool;

    //read_pc
    pc = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(mmIndex, ShadowAddresses.get_pc()))
    );
    (translateBool, paddr) = translate_virtual_address(pc, RiscVConstants.PTE_XWR_CODE_SHIFT());

    //translate_virtual_address failed
    if(!translateBool){
      //raise_exception(CAUSE_FETCH_PAGE_FAULT)
      return fetch_status.exception;
    }

    // Finds the range in memory in which the physical address is located
    // Returns start and length words from pma
    (pma_entry.start, pma_entry.length) = find_pma_entry(paddr);

    //emit Print("pma_entry.start", pma_entry.start);
    //emit Print("pma_entry.length", pma_entry.length);

    // M flag defines if the pma range is in memory 
    // X flag defines if the pma is executable
    // If the pma is not memory or not executable - this is a pma violation
    // Reference: The Core of Cartesi, v1.02 - section 3.2 the board - page 5.

    if(!pma_get_istart_M() || !pma_get_istart_X()){
      //raise_exception(MCAUSE_INSN_ACCESS_FAULT)
      return fetch_status.exception;
    }

    //emit Print("paddr/insn", paddr);
    //will this actually return the instruction? Should it be 32bits?
    insn = uint32(BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(mmIndex, paddr))
    ));
    //emit Print("insn", uint(insn));
    return fetch_status.success;
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

    // Reads privilege level on iflags register. The privilege level is located
    // on bits 2 and 3.
    // Reference: The Core of Cartesi, v1.02 - figure 1.
    priv = (BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(mmIndex, ShadowAddresses.get_iflags())
    )) >> 2) & 3;
    //emit Print("priv", uint(priv));

    //read_mstatus
    mstatus = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(mmIndex, ShadowAddresses.get_mstatus()))
    );

    //emit Print("mstatus", uint(mstatus));
    // When MPRV is set, data loads and stores use privilege in MPP
    // instead of the current privilege level (code access is unaffected)
    //TO-DO: Check this &/&& and shifts
    if((mstatus & RiscVConstants.MSTATUS_MPRV() != 0) && (xwr_shift != RiscVConstants.PTE_XWR_CODE_SHIFT())){
      priv = (mstatus >> RiscVConstants.MSTATUS_MPP_SHIFT()) & 3;
    }
    // Physical memory is mediated by Machine-mode so, if privilege is M-mode it 
    // does not use virtual Memory
    // Reference: riscv-priv-spec-1.7.pdf - Section 3.3, page 32.
    if(priv == RiscVConstants.PRV_M()){
      return(true, vaddr);
    }

    // SATP - Supervisor Address Translation and Protection Register
    // Holds MODE, Physical page number (PPN) and address space identifier (ASID)
    // MODE is located on bits 60 to 63 for RV64.
    // Reference: riscv-priv-spec-1.10.pdf - Section 4.1.12, page 56.
    satp = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(mmIndex, ShadowAddresses.get_satp()))
    );
    //emit Print("satp", satp);
    // In RV64, mode can be
    //   0: Bare: No translation or protection
    //   8: sv39: Page-based 39-bit virtual addressing
    //   9: sv48: Page-based 48-bit virtual addressing
    // Reference: riscv-priv-spec-1.10.pdf - Table 4.3, page 57.
    mode = (satp >> 60) & 0xf;
    //emit Print("mode", uint(mode));

    if(mode == 0){
      return(true, vaddr);
    } else if(mode < 8 || mode > 9){
      return(false, 0);
    }
    // Here we know we are in sv39 or sv48 modes

    // Page table hierarchy of sv39 has 3 levels, and sv48 has 4 levels
    levels = mode - 8 + 3;
    // Page offset are bits located from 0 to 11.
    // Then come levels virtual page numbers (VPN)
    // The rest of vaddr must be filled with copies of the
    // most significant bit in VPN[levels]
    // Hence, the use of arithmetic shifts here
    // Reference: riscv-priv-spec-1.10.pdf - Figure 4.16, page 63.

    //TO-DO: Use bitmanipulation library for arithmetic shift
    vaddr_shift = RiscVConstants.XLEN() - (RiscVConstants.PG_SHIFT() + levels * 9);
    if(((int64(vaddr) << vaddr_shift) >> vaddr_shift) != int64(vaddr)){
      return(false, 0);
    }
    // The least significant 44 bits of satp contain the physical page number
    // for the root page table
    // Reference: riscv-priv-spec-1.10.pdf - Figure 4.12, page 57.
    int satp_ppn_bits = 44;
    // Initialize pte_addr with the base address for the root page table
    pte_addr = (satp & ((uint64(1) << satp_ppn_bits) -1)) << RiscVConstants.PG_SHIFT();
    // All page table entries have 8 bytes
    // Each page table has 4k/pte_size entries
    // To index all entries, we need vpn_bits
    // Reference: riscv-priv-spec-1.10.pdf - Section 4.4.1, page 63.
    pte_size_log2 = 3;
    vpn_bits = 12 - pte_size_log2;
    uint64 vpn_mask = uint64((1 << vpn_bits) - 1);

    for(int i = 0; i < levels; i++) {
      // Mask out VPN[levels -i-1]
      vaddr_shift = RiscVConstants.PG_SHIFT() + vpn_bits * (levels -1 -i);
      uint64 vpn = (vaddr >> vaddr_shift) & vpn_mask;
      // Add offset to find physical address of page table entry
      pte_addr += vpn << pte_size_log2;
      //Read page table entry from physical memory
      uint64 pte = 0;

      //TO-DO: Implement read_ram_uint64(a, pte_addr, &pte)
      // if(!read_ram_uint64(pte_addr)){
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
        if(priv == RiscVConstants.PRV_S()){
          // If SUM is set, forbid S-mode code from accessing U-mode memory
          //TO-DO: check if condition
          if((pte & RiscVConstants.PTE_U_MASK() != 0) && ((mstatus & RiscVConstants.MSTATUS_SUM())) == 0){
            return (false, 0);
          }
        }else{
          // Forbid U-mode code from accessing S-mode memory
          if((pte & RiscVConstants.PTE_U_MASK()) == 0){
            return (false, 0);
          }
        }
        // MXR allows to read access to execute-only pages
        if(mstatus & RiscVConstants.MSTATUS_MXR() != 0){
          //Set R bit if X bit is set
          xwr = xwr | (xwr >> 2);
        }
        // Check protection bits against request access
        if(((xwr >> xwr_shift) & 1) == 0){
          return (false, 0);
        }
        // Check page, megapage, and gigapage alignment
        vaddr_mask = (uint64(1) << vaddr_shift) - 1;
        if(ppn & vaddr_mask != 0){
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
          //write_ram_uint64(a, pte_addr,pte);
        }
        // Add page offset in vaddr to ppn to form physical address
        return(true, (vaddr * vaddr_mask) | (ppn & ~vaddr_mask));
      }else {
        pte_addr = ppn;
      }
    }
    return(false, 0);
  }

  //Populate storage pma_entry
  //TO-DO: there is probably gonna be a pma_entry array on storage, so we will have
  // to adjust this code.

  // @param physical address to look for
  // @return public returns the two words that define a PMA - start and length
  function find_pma_entry(uint64 paddr) public returns (uint64, uint64){

    // Hard coded ram address starts at 0x800
    // In total there are 32 PMAs from processor shadow to Flash disk 7.
    // PMA 0 - describes RAM and is hardcoded to address 0x800
    // PMA 16 - 23 describe flash devices 0-7
    // RAM start field is hardcoded to 0x800
    // Reference: The Core of Cartesi, v1.02 - Table 3.
    uint64 pmaAddress = 0x800;
    bool foundPma;
    //TO-DO: Check lastPma - this is probably wrong.
    uint64 lastPma = 62; // 0 - 31 * 2 words
    //emit Print("paddr", paddr);
    for(uint64 i = 0; i < lastPma; i+=2){
      uint64 start_word = BitsManipulationLibrary.uint64_swapEndian(
        uint64(mm.read(mmIndex, pmaAddress + (i*8)))
      );

      uint64 length_word = BitsManipulationLibrary.uint64_swapEndian(
        uint64(mm.read(mmIndex, pmaAddress + ((i * 8 + 8))))
      );

      // Both pma_start and pma_length have to be aligned to a 4KiB boundary.
      // So this leaves the lowest 12 bits for attributes. To find out the actual
      // start and length of the PMAs it is necessary to clean those attribute bits
      // Reference: The Core of Cartesi, v1.02 - Figure 2 - Page 5.
      uint64 pma_start = start_word & 0xfffffffffffff000;
      uint64 pma_length = length_word & 0xfffffffffffff000;

      if(paddr >= pma_start && paddr < (pma_start + pma_length)){
        return (start_word, length_word);
      }

      if(pma_length == 0){
        break;
      }
    }
  }

  function raise_interrupt_if_any() public {
    uint32 mask = get_pending_irq_mask();
    if(mask != 0) {
      uint64 irq_num = ilog2(mask);
      //TO-DO: Raise_exception
     // raise_exception()
    }
  }

  // Machine Interrupt Registers: mip and mie.
  // mip register contains information on pending interrupts.
  // mie register contains the interrupt enabled bits.
  // Reference: riscv-privileged-v1.10 - section 3.1.14 - page 28.
  function get_pending_irq_mask() public returns (uint32){
    uint64 mip = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(mmIndex, ShadowAddresses.get_mip()))
    );
    //emit Print("mip", uint(mip));

    uint64 mie = BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(mmIndex, ShadowAddresses.get_mie()))
    );
    //emit Print("mie", uint(mie));

    uint32 pending_ints = uint32(mip & mie);
    // if there are no pending interrupts, return 0.
    if(pending_ints == 0){
      return 0;
    }
    mstatus = 0;
    uint32 enabled_ints = 0;
    //TO-DO: check shift + mask
    //TO-DO: Use bitmanipulation library for arithmetic shift

    // Read privilege level on iflags register.
    // The privilege level is represented by bits 2 and 3 on iflags register.
    // Reference: The Core of Cartesi, v1.02 - figure 1.
    priv = (BitsManipulationLibrary.uint64_swapEndian(
      uint64(mm.read(mmIndex, ShadowAddresses.get_iflags())
    )) >> 2) & 3;
    //emit Print("priv", uint(priv));
    
    if(priv == RiscVConstants.PRV_M()) {
      // MSTATUS is the Machine Status Register - it controls the current
      // operating state. The MIE is an interrupt-enable bit for machine mode.
      // MIE for 64bit is stored on location 3 - according to:
      // Reference: riscv-privileged-v1.10 - figure 3.7 - page 20.
      mstatus = BitsManipulationLibrary.uint64_swapEndian(
        uint64(mm.read(mmIndex, ShadowAddresses.get_mstatus()))
      );
      //emit Print("mstatus", uint(mstatus));

      if((mstatus & RiscVConstants.MSTATUS_MIE()) != 0){
        enabled_ints = uint32(~BitsManipulationLibrary.uint64_swapEndian(
          uint64(mm.read(mmIndex, ShadowAddresses.get_mideleg())))
        );
      }
    }else if(priv == RiscVConstants.PRV_S()){
      mstatus = BitsManipulationLibrary.uint64_swapEndian(
        uint64(mm.read(mmIndex, ShadowAddresses.get_mstatus()))
      );
      //emit Print("mstatus", uint(mstatus));
      // MIDELEG: Machine trap delegation register
      // mideleg defines if a interrupt can be proccessed by a lower privilege
      // level. If mideleg bit is set, the trap will delegated to the S-Mode.
      // Reference: riscv-privileged-v1.10 - Section 3.1.13 - page 27.
      uint64 mideleg = BitsManipulationLibrary.uint64_swapEndian(
        uint64(mm.read(mmIndex, ShadowAddresses.get_mideleg()))
      );
      //emit Print("mideleg", uint(mideleg));
      enabled_ints = uint32(~mideleg);


      // SIE: is the register contaning interrupt enabled bits for supervisor mode.
      // It is located on the first bit of mstatus register (RV64).
      // Reference: riscv-privileged-v1.10 - figure 3.7 - page 20.
      if((mstatus & RiscVConstants.MSTATUS_SIE()) != 0){
        //TO-DO: make sure this is the correct cast
        enabled_ints = enabled_ints | uint32(mideleg);
      }
    }else{
      enabled_ints = uint32(-1);
    }
    return pending_ints & enabled_ints;
  }
  //TO-DO: optmize log2 function
  function ilog2(uint32 v) public returns(uint64){
    //cpp emulator code:
    //return 31 - __builtin_clz(v)

    uint leading = 32;
    while(v != 0){
      v = v >> 1;
      leading--;
    }
    return uint64(31 - leading);
  }

  //pma functions

  // M bit defines if the range is memory
  // The flag is pma_entry start's word first bit
  // Reference: The Core of Cartesi, v1.02 - figure 2.
  function pma_get_istart_M() public returns(bool){
    //M is pma_entry fisrt bit
    //emit Print("pma_get_istart_M", pma_entry.start & 1);
    return pma_entry.start & 1 == 1;
  }

  // X bit defines if the range is executable
  // The flag is pma_entry start's word on position 5.
  // Reference: The Core of Cartesi, v1.02 - figure 2.
  function pma_get_istart_X() public returns(bool){
    //X is pma_entry sixth bit (index 5)
    //emit Print("pma_get_istart_X", (pma_entry.start >> 5) & 1);
    return (pma_entry.start >> 5) & 1 == 1;
  }
  //enums
  enum fetch_status {
    exception, //failed: exception raised
    success
  }
  enum interpreter_status {
    brk, // brk is set, tigh loop was broken
    success // mcycle reached target value
  }
  enum execute_status {
    illegal, // Exception was raised
    retired // Instruction retired - having raised or not an exception
  }
}
