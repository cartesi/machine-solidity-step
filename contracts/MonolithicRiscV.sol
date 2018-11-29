/// @title Monolithic RiscV
pragma solidity 0.4.24;

//Libraries
import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";

contract mmInterface {
  function read(uint256 _index, uint64 _address) public view returns (bytes8);
  function write(uint256 _index, uint64 _address, bytes8 _value) public;
  function finishReplayPhase(uint256 _index) public;
}

//TO-DO: use instantiator pattern so we can always use same instance of mm/pc etc
contract MonolithicRiscV {
  event Print(string message);

  mmInterface mm;
  uint256 mmIndex;

  function step(address _memoryManagerAddress) returns (interpreter_status){
    uint64 pc = 0;
    uint32 insn = 0;

    //TO-DO: set mmInterface to correct address
    mm = mmInterface(_memoryManagerAddress);
    //TO-DO: Check byte order -> riscv is little endian/ solidity is big endian

    //H -> least significant bit of iflags
    if( (uint64(mm.read(mmIndex, ShadowAddresses.get_iflags())) & 1) != 0){
      //machine is halted
      return interpreter_status.success;
    }
    //Raise the highest priority interrupt
    raise_interrupt_if_any();

    if(fetch_insn() == fetch_status.success){
      if(true/*execute_insn == execute_status.retired*/){
        //decodes instruction until it finds the definitive one
        //begin auipc
          //write_register(rd, pc + insn_U_get_imm
          //advance_to_next_insn
            //write_pc = pc + 4
          //end auipc
      }
    }
    //read_minstret
    //write_minsret + 1

    //read_mcycle
    //write_mcycle + 1
//  //end step
  }
  function fetch_insn() returns (fetch_status){
    emit Print("fetch");
    //read_pc
    uint64 vaddr = uint64(mm.read(mmIndex, ShadowAddresses.get_pc()));
    if(vaddr == 0){ revert();}

    uint64 paddr;
    translate_virtual_address();

    //how to find paddr?? Some cases paddr == pc?
    //find_pma_entry
    //if pma is memory:
      //read_memory
    //end fetch

  }

  //TO-DO: Understand this code properly
  function translate_virtual_address(uint64 vaddr, int xwr_shift) returns(bool, uint64){
    //TO-DO: check shift + mask
    //TO-DO: use bitmanipulation right shift
    int priv = (uint64(mm.read(mmIndex, ShadowAddresses.get_iflags())) >> 2) & 3;
    //read_mstatus
    uint64 mstatus = uint64(mm.read(mmIndex, ShadowAddresses.get_mstatus()));

    // When MPRV is set, data loads and stores use privilege in MPP
    // instead of the current privilege level (code access is unaffected)
    //TO-DO: Check this &/&& and shifts
    if((mstatus & RiscVConstants.MSTATUS_MPRV() != 0) && (xwr_shift != RiscVConstants.PTE_XWR_CODE_SHIFT())){
      priv = (mstatus >> RiscVConstants.MSTATUS_MPP_SHIFT()) & 3;
    }
    if(priv == RiscVConstants.PRV_M()){
      return(true, vaddr);
    }

    uint64 satp = uint64(mm.read(mmIndex, ShadowAddresses.get_satp()));
    // In RV64, mode can be
    //   0: Bare: No translation or protection
    //   8: sv39: Page-based 39-bit virtual addressing
    //   9: sv48: Page-based 48-bit virtual addressing
    int mode = (satp >> 60) & 0xf;
    if(mode == 0){
      return(true, vaddr);
    } else if(mode < 8 || mode > 9){
      return(false, 0);
    }
    // Here we know we are in sv39 or sv48 modes

    // Page table hierarchy of sv39 has 3 levels, and sv48 has 4 levels
    int levels = mode - 8 + 3;
    // The least significant 12 bits of vaddr are the page offset
    // Then come levels virtual page numbers (VPN)
    // The rest of vaddr must be filled with copies of the
    // most significant bit in VPN[levels]
    // Hence, the use of arithmetic shifts here

    //TO-DO: Use bitmanipulation library for arithmetic shift
    int vaddr_shift = RiscVConstants.XLEN() - (RiscVConstants.PG_SHIFT() + levels * 9);
    if(((int64(vaddr) << vaddr_shift) >> vaddr_shift) != int64(vaddr)){
      return(false, 0);
    }
    // The least significant 44 bits of satp contain the physical page number for the root page table
    int constant satp_ppn_bits = 44;
    // Initialize pte_addr with the base address for the root page table
    uint64 pte_addr = (satp & ((uint64(1) << satp_ppn_bits) -1)) << RiscVConstants.PG_SHIFT();
    // All page table entries have 8 bytes
    int constant pte_size_log2 = 3;
    // Each page table has 4k/pte_size entries
    // To index all entries, we need vpn_bits
    int constant vpn_bits = 12 - pte_size_log2;
    uint64 vpn_mask = (1 << vpn_bits) - 1;

    for(uint i = 0; i < levels; i++) {
      // Mask out VPN[levels -i-1]
      vaddr_shift = RiscVConstants.PG_SHIFT() + vpn_bits * (levels -1 -i);
      uint64 vpn = (vaddr >> vaddr_shift) & vpn_mask;
      // Add offset to find physical address of page table entry
      pte_addr += vpn << pte_size_log2;
      //Read page table entry from physical memory
      uint64 pte = 0;
      //TO-DO: Implement read_ram_uint64(a, pte_addr, &pte)
      if(!read_ram_uint64(pte_addr)){
        return(false, 0);
      }
      // The OS can mark page table entries as invalid,
      // but these entries shouldn't be reached during page lookups
      //TO-DO: check if condition
      if((pte & RiscVConstants.PTE_V_MASK()) == 0){
        return(false, 0);
      }
      // Clear all flags in least significant bits, then shift back to multiple of page size to form physical address
      uint64 ppn = (pte >> 10) << RiscVConstants.PG_SHIFT();
      // Obtain X, W, R protection bits
      int xwr = (pte >> 1) & 7;
      // xwr !=0 means we are done walking the page tables
      if(xwr !=0){
        // These protection bit combinations are reserved for future use
        if(xwr == 2 || xwr == 6){
          return (false, 0);
        }
        // (We know we are not PRV_M if we reached here)
        if(priv == RiscVConstants.PRV_S(){
          // If SUM is set, forbid S-mode code from accessing U-mode memory
          //TO-DO: check if condition
          if((pte & RiscVConstants.PTE_U_MASK()) && ((mstatus & RiscVConstants.MSTATUS_SUM)) == 0){
            return (false, 0);
          }else{
            // Forbid U-mode code from accessing S-mode memory
            //TO-DO: continue here --- ~~~ 
          }
        
        }
      }

    }
  }

  //TO-DO: Implement find_pma
  function find_pma(uint64 paddr){
  }

  function raise_interrupt_if_any(){
    uint32 mask = get_pending_irq_mask();
    if(mask != 0) {
      uint64 irq_num = ilog2(mask);
      //TO-DO: Raise_exception
     // raise_exception()
    }
  }

  function get_pending_irq_mask() returns (uint32){
    uint64 mip = uint64(mm.read(mmIndex, ShadowAddresses.get_mip()));
    uint64 mie = uint64(mm.read(mmIndex, ShadowAddresses.get_mie()));

    uint32 pending_ints = uint32(mip & mie);
    if(pending_ints == 0){
      return 0;
    }
    uint64 mstatus = 0;
    uint32 enabled_ints = 0;
    //TO-DO: check shift + mask
    //TO-DO: Use bitmanipulation library for arithmetic shift
    int priv = (uint64(mm.read(mmIndex, ShadowAddresses.get_iflags())) >> 2) & 3;
    if(priv == RiscVConstants.PRV_M()) {
      mstatus = uint64(mm.read(mmIndex, ShadowAddresses.get_mstatus()));
      if((mstatus & RiscVConstants.MSTATUS_MIE()) != 0){
        enabled_ints = uint32(~uint64(mm.read(mmIndex, ShadowAddresses.get_mideleg())));
      }
    }else if(priv == RiscVConstants.PRV_S()){
      mstatus = uint64(mm.read(mmIndex, ShadowAddresses.get_mstatus()));
      uint64 mideleg = uint64(mm.read(mmIndex, ShadowAddresses.get_mideleg()));
      enabled_ints = uint32(~mideleg);
      if((mstatus & RiscVConstants.MSTATUS_SIE()) != 0){
        //TO-DO: make sure this is the correct cast
        enabled_ints = enabled_ints | uint32(mideleg);
      }
    }else{
      //TO-DO: Should I require iflags_PRV == PRV_U?
      //require(priv == PRVLevelsConstants.get_PRV_U());
      enabled_ints = uint32(-1);
    }
    return pending_ints & enabled_ints;
  }

  function ilog2(uint32 v) returns(uint64){
    //cpp emulator code:
    //return 31 - __builtin_clz(v)

    //TO-DO: What to do if v == 0?
    uint leading = 32;
    while(v != 0){
      v = v >> 1;
      leading--;
    }
    return uint64(31 - leading);
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
}
