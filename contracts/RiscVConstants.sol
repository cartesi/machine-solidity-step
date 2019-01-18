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
  //TO-DO: Add all constants (currently adding them as the need appears)
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
  function MSTATUS_SD_SHIFT()   public returns(uint64) {return 31;}
  function MSTATUS_UXL_SHIFT()  public returns(uint64) {return 32;}
  function MSTATUS_SXL_SHIFT()  public returns(uint64) {return 34;}

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
}

//Rest of mstatus
//  uint64 MSTATUS_UIE     = (1 << 0);
//  uint64 MSTATUS_SIE     = (1 << 1);
//  uint64 MSTATUS_HIE     = (1 << 2);
//  uint64 MSTATUS_MIE     = (1 << 3);
//  uint64 MSTATUS_UPIE    = (1 << 4);
//  uint64 MSTATUS_SPIE  =   (1 << MSTATUS_SPIE_SHIFT)
//  uint64 MSTATUS_HPIE    = (1 << 6);
//  uint64 MSTATUS_MPIE  =   (1 << MSTATUS_MPIE_SHIFT)
//  uint64 MSTATUS_SPP   =   (1 << MSTATUS_SPP_SHIFT)
//  uint64 MSTATUS_HPP     = (3 << 9);
//  uint64 MSTATUS_MPP   =   (3 << MSTATUS_MPP_SHIFT)
//  uint64 MSTATUS_FS    =   (3 << MSTATUS_FS_SHIFT)
//  uint64 MSTATUS_XS      = (3 << 15);
//  uint64 MSTATUS_MPRV    = (1 << 17);
//  uint64 MSTATUS_SUM     = (1 << 18);
//  uint64 MSTATUS_MXR     = (1 << 19);
//  uint64 MSTATUS_TVM     = (1 << 20);
//  uint64 MSTATUS_TW      = (1 << 21);
//  uint64 MSTATUS_TSR     = (1 << 22);
//  uint64 MSTATUS_SD          ((uint64_t)1 << MSTATUS_SD_SHIFT)
//  uint64 MSTATUS_UXL         ((uint64_t)3 << MSTATUS_UXL_SHIFT)
//  uint64 MSTATUS_SXL         ((uint64_t)3 << MSTATUS_SXL_SHIFT)

