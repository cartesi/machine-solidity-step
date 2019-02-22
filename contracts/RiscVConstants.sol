/// @title RiscVConstants
pragma solidity ^0.5.0;

library RiscVConstants {
  //General purpose
  function XLEN() public returns(uint64) {return 64;}
  function MXL()  public returns(uint64) {return 2;}

  //Privilege Levels
  function PRV_U() public returns(uint64) {return 0;}
  function PRV_S() public returns(uint64) {return 1;}
  function PRV_H() public returns(uint64) {return 2;}
  function PRV_M() public returns(uint64) {return 3;}

  //mstatus flags
  //to-do: add all constants (currently adding them as the need appears)
  function MSTATUS_MIE()  public returns(uint64)  {return (1 << 3);}
  function MSTATUS_SIE()  public returns(uint64)  {return (1 << 1);}
  function MSTATUS_MPRV() public returns(uint64)  {return (1 << 17);}
  function MSTATUS_SUM()  public returns(uint64)  {return (1 << 18);}
  function MSTATUS_MXR()  public returns(uint64)  {return (1 << 19);}

  //mstatus shifts
  function MSTATUS_UIE_SHIFT()  public returns(uint64) {return 0 ;}
  function MSTATUS_SIE_SHIFT()  public returns(uint64) {return 1 ;}
  function MSTATUS_HIE_SHIFT()  public returns(uint64) {return 2 ;}
  function MSTATUS_MIE_SHIFT()  public returns(uint64) {return 3 ;}
  function MSTATUS_UPIE_SHIFT() public returns(uint64) {return 4 ;}
  function MSTATUS_SPIE_SHIFT() public returns(uint64) {return 5 ;}
  function MSTATUS_MPIE_SHIFT() public returns(uint64) {return 7 ;}
  function MSTATUS_SPP_SHIFT()  public returns(uint64) {return 8 ;}
  function MSTATUS_MPP_SHIFT()  public returns(uint64) {return 11;}
  function MSTATUS_FS_SHIFT()   public returns(uint64) {return 13;}

  function MSTATUS_XS_SHIFT()   public returns(uint64) {return 15;} 
  function MSTATUS_MPRV_SHIFT() public returns(uint64) {return 17;}
  function MSTATUS_SUM_SHIFT()  public returns(uint64) {return 18;}
  function MSTATUS_MXR_SHIFT()  public returns(uint64) {return 19;}
  function MSTATUS_TVM_SHIFT()  public returns(uint64) {return 20;}
  function MSTATUS_TW_SHIFT()   public returns(uint64) {return 21;}
  function MSTATUS_TSR_SHIFT()  public returns(uint64) {return 22;}  


  function MSTATUS_UXL_SHIFT()  public returns(uint64) {return 32;}
  function MSTATUS_SXL_SHIFT()  public returns(uint64) {return 34;}

  function MSTATUS_SD_SHIFT()   public returns(uint64) {return XLEN() - 1;}

  //mstatus masks
  function MSTATUS_UIE_MASK()  public returns(uint64){return (uint64(1) << MSTATUS_UIE_SHIFT());}
  function MSTATUS_SIE_MASK()  public returns(uint64){return uint64(1) << MSTATUS_SIE_SHIFT();}
  function MSTATUS_MIE_MASK()  public returns(uint64){return uint64(1) << MSTATUS_MIE_SHIFT();}
  function MSTATUS_UPIE_MASK() public returns(uint64){return uint64(1) << MSTATUS_UPIE_SHIFT();}
  function MSTATUS_SPIE_MASK() public returns(uint64){return uint64(1) << MSTATUS_SPIE_SHIFT();}
  function MSTATUS_MPIE_MASK() public returns(uint64){return uint64(1) << MSTATUS_MPIE_SHIFT();}
  function MSTATUS_SPP_MASK()  public returns(uint64){return uint64(1) << MSTATUS_SPP_SHIFT();}
  function MSTATUS_MPP_MASK()  public returns(uint64){return uint64(3) << MSTATUS_MPP_SHIFT();}
  function MSTATUS_FS_MASK()   public returns(uint64){return uint64(3) << MSTATUS_FS_SHIFT();}
  function MSTATUS_XS_MASK()   public returns(uint64){return uint64(3) << MSTATUS_XS_SHIFT();}
  function MSTATUS_MPRV_MASK() public returns(uint64){return uint64(1) << MSTATUS_MPRV_SHIFT();}
  function MSTATUS_SUM_MASK()  public returns(uint64){return uint64(1) << MSTATUS_SUM_SHIFT();}
  function MSTATUS_MXR_MASK()  public returns(uint64){return uint64(1) << MSTATUS_MXR_SHIFT();}
  function MSTATUS_TVM_MASK()  public returns(uint64){return uint64(1) << MSTATUS_TVM_SHIFT();}
  function MSTATUS_TW_MASK()   public returns(uint64){return uint64(1) << MSTATUS_TW_SHIFT();}
  function MSTATUS_TSR_MASK()  public returns(uint64){return uint64(1) << MSTATUS_TSR_SHIFT();}

  function MSTATUS_UXL_MASK()  public returns(uint64){return uint64(3) << MSTATUS_UXL_SHIFT();}
  function MSTATUS_SXL_MASK()  public returns(uint64){return uint64(3) << MSTATUS_SXL_SHIFT();}
  function MSTATUS_SD_MASK()   public returns(uint64){return uint64(1) << MSTATUS_SD_SHIFT();}

  // mstatus read/writes
  function MSTATUS_W_MASK() public returns(uint64){
    return (
      MSTATUS_UIE_MASK()  |
      MSTATUS_SIE_MASK()  |
      MSTATUS_MIE_MASK()  |
      MSTATUS_UPIE_MASK() |
      MSTATUS_SPIE_MASK() |
      MSTATUS_MPIE_MASK() |
      MSTATUS_SPP_MASK()  |
      MSTATUS_MPP_MASK()  |
      MSTATUS_FS_MASK()   |
      MSTATUS_MPRV_MASK() |
      MSTATUS_SUM_MASK()  |
      MSTATUS_MXR_MASK()  |
      MSTATUS_TVM_MASK()  |
      MSTATUS_TW_MASK()   |
      MSTATUS_TSR_MASK()
    );
  }
  function MSTATUS_R_MASK() public returns(uint64){
    return (
      MSTATUS_UIE_MASK()  |
      MSTATUS_SIE_MASK()  |
      MSTATUS_MIE_MASK()  |
      MSTATUS_UPIE_MASK() |
      MSTATUS_SPIE_MASK() |
      MSTATUS_MPIE_MASK() |
      MSTATUS_SPP_MASK()  |
      MSTATUS_MPP_MASK()  |
      MSTATUS_FS_MASK()   |
      MSTATUS_MPRV_MASK() |
      MSTATUS_SUM_MASK()  |
      MSTATUS_MXR_MASK()  |
      MSTATUS_TVM_MASK()  |
      MSTATUS_TW_MASK()   |
      MSTATUS_TSR_MASK()  |
      MSTATUS_UXL_MASK()  |
      MSTATUS_SXL_MASK()  |
      MSTATUS_SD_MASK()
    );
  }
  // sstatus read/writes
  function SSTATUS_W_MASK() public returns(uint64){
    return (
        MSTATUS_UIE_MASK()  |
        MSTATUS_SIE_MASK()  |
        MSTATUS_UPIE_MASK() |
        MSTATUS_SPIE_MASK() |
        MSTATUS_SPP_MASK()  |
        MSTATUS_FS_MASK()   |
        MSTATUS_SUM_MASK()  |
        MSTATUS_MXR_MASK()
    );
  }

  function SSTATUS_R_MASK() public returns(uint64){
    return (
        MSTATUS_UIE_MASK()  |
        MSTATUS_SIE_MASK()  |
        MSTATUS_UPIE_MASK() |
        MSTATUS_SPIE_MASK() |
        MSTATUS_SPP_MASK()  |
        MSTATUS_FS_MASK()   |
        MSTATUS_SUM_MASK()  |
        MSTATUS_MXR_MASK()  |
        MSTATUS_UXL_MASK()  |
        MSTATUS_SD_MASK()
    ); 
  }

  // MCAUSE for exceptions
  function MCAUSE_INSN_ADDRESS_MISALIGNED()     public returns(uint64) {return 0x0;} ///< Instruction address misaligned
  function MCAUSE_INSN_ACCESS_FAULT()           public returns(uint64) {return 0x1;} ///< Instruction access fault
  function MCAUSE_ILLEGAL_INSN()                public returns(uint64) {return 0x2;} ///< Illegal instruction
  function MCAUSE_BREAKPOINT()                  public returns(uint64) {return 0x3;} ///< Breakpoint
  function MCAUSE_LOAD_ADDRESS_MISALIGNED()     public returns(uint64) {return 0x4;} ///< Load address misaligned
  function MCAUSE_LOAD_ACCESS_FAULT()           public returns(uint64) {return 0x5;} ///< Load access fault
  function MCAUSE_STORE_AMO_ADDRESS_MISALIGNED()public returns(uint64) {return 0x6;} ///< Store/AMO address misaligned
  function MCAUSE_STORE_AMO_ACCESS_FAULT()      public returns(uint64) {return 0x7;} ///< Store/AMO access fault
  function MCAUSE_ECALL_BASE()                  public returns(uint64) {return 0x8;} ///< Environment call (+0: from U-mode, +1: from S-mode, +3: from M-mode)
  function MCAUSE_FETCH_PAGE_FAULT()            public returns(uint64) {return 0xc;} ///< Instruction page fault
  function MCAUSE_LOAD_PAGE_FAULT()             public returns(uint64) {return 0xd;} ///< Load page fault
  function MCAUSE_STORE_AMO_PAGE_FAULT()        public returns(uint64) {return 0xf;} ///< Store/AMO page fault

  function MCAUSE_INTERRUPT_FLAG()               public returns(uint64) {return uint64(1) << (XLEN() - 1);} ///< Interrupt flag

  // mcounteren constants
  function MCOUNTEREN_CY_SHIFT() public returns(uint64) {return 0;}
  function MCOUNTEREN_TM_SHIFT() public returns(uint64) {return 1;}
  function MCOUNTEREN_IR_SHIFT() public returns(uint64) {return 2;}

  function MCOUNTEREN_CY_MASK() public returns(uint64) {return uint64(1) << MCOUNTEREN_CY_SHIFT();}
  function MCOUNTEREN_TM_MASK() public returns(uint64) {return uint64(1) << MCOUNTEREN_TM_SHIFT();}
  function MCOUNTEREN_IR_MASK() public returns(uint64) {return uint64(1) << MCOUNTEREN_IR_SHIFT();}

  function MCOUNTEREN_RW_MASK() public returns(uint64) {return MCOUNTEREN_CY_MASK() | MCOUNTEREN_TM_MASK() | MCOUNTEREN_IR_MASK();}
  function SCOUNTEREN_RW_MASK() public returns(uint64) {return MCOUNTEREN_RW_MASK();}  

  //Paging constants
  function PG_SHIFT() public returns(uint64) {return 12;}
  function PG_MASK()  public returns(uint64) {((1 << PG_SHIFT()) - 1);}

  function PTE_V_MASK() public returns(uint64) {return (1 << 0);}
  function PTE_U_MASK() public returns(uint64) {return (1 << 4);}
  function PTE_A_MASK() public returns(uint64) {return (1 << 6);}
  function PTE_D_MASK() public returns(uint64) {return (1 << 7);}

  function PTE_XWR_READ_SHIFT() public returns(uint64)  {return 0;}
  function PTE_XWR_WRITE_SHIFT() public returns(uint64) {return 1;}
  function PTE_XWR_CODE_SHIFT() public returns(uint64)  {return 2;}

  // PAGE masks
  function PAGE_NUMBER_SHIFT() public returns(uint64)  {return 12;}

  function PAGE_OFFSET_MASK() public returns(uint64) {return ((uint64(1) << PAGE_NUMBER_SHIFT()) - 1);}

  // MIP Shifts:
  function MIP_USIP_SHIFT() public returns(uint64) {return 0;}
  function MIP_SSIP_SHIFT() public returns(uint64) {return 1;}
  function MIP_MSIP_SHIFT() public returns(uint64) {return 3;}
  function MIP_UTIP_SHIFT() public returns(uint64) {return 4;}
  function MIP_STIP_SHIFT() public returns(uint64) {return 5;}
  function MIP_MTIP_SHIFT() public returns(uint64) {return 7;}
  function MIP_UEIP_SHIFT() public returns(uint64) {return 8;}
  function MIP_SEIP_SHIFT() public returns(uint64) {return 9;}
  function MIP_MEIP_SHIFT() public returns(uint64) {return 11;}

  function MIP_USIP_MASK() public returns(uint64) {return uint64(1) <<MIP_USIP_SHIFT();}
  function MIP_SSIP_MASK() public returns(uint64) {return uint64(1) <<MIP_SSIP_SHIFT();}
  function MIP_MSIP_MASK() public returns(uint64) {return uint64(1) <<MIP_MSIP_SHIFT();}
  function MIP_UTIP_MASK() public returns(uint64) {return uint64(1) <<MIP_UTIP_SHIFT();}
  function MIP_STIP_MASK() public returns(uint64) {return uint64(1) <<MIP_STIP_SHIFT();}
  function MIP_MTIP_MASK() public returns(uint64) {return uint64(1) <<MIP_MTIP_SHIFT();}
  function MIP_UEIP_MASK() public returns(uint64) {return uint64(1) <<MIP_UEIP_SHIFT();}
  function MIP_SEIP_MASK() public returns(uint64) {return uint64(1) <<MIP_SEIP_SHIFT();}
  function MIP_MEIP_MASK() public returns(uint64) {return uint64(1) <<MIP_MEIP_SHIFT();}
}
