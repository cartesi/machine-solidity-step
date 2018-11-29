/// @title MstatusConstants
pragma solidity 0.4.24;

//All constants related to mstatus

//TO-DO: Add all constants (currently adding them as the need appears)
library MstatusConstants {
  //name mstatus flags
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

  function get_MSTATUS_MIE() public returns(uint64) {return (1 << 3);}
  function get_MSTATUS_SIE() public returns(uint64) {return (1 << 1);}

}
