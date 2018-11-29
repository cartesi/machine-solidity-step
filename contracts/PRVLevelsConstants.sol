/// @title PRVLevelsConstants
pragma solidity 0.4.24;

library PRVLevelsConstants {
  //Privilege Levels
  uint64 constant PRV_U = 0;  // User privilege
  uint64 constant PRV_S = 1;  // Supervisor privilege
  uint64 constant PRV_H = 2;  // Reserved privilege
  uint64 constant PRV_M = 3;  // Machine privilege

  function get_PRV_U() public returns(uint64) {return PRV_U;}
  function get_PRV_S() public returns(uint64) {return PRV_S;}
  function get_PRV_H() public returns(uint64) {return PRV_H;}
  function get_PRV_M() public returns(uint64) {return PRV_M;}

}
