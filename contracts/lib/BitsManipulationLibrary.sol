/// @title Bits Manipulation Library
pragma solidity ^0.5.0;

//change to lib after testing
library BitsManipulationLibrary {

  /// @notice Arithmetic right shift for int32
  //  @param number to be shifted
  //  @param number of shifts
  function int32_arith_shift_right(int32 number, uint shiftAmount)
  public pure returns(int32)
  {
    uint32 u_number = uint32(number);
    uint lastPos = 31;
    uint sign_bit = u_number >> lastPos;

    int32 output = int32((u_number >> shiftAmount) |
          (((0 - sign_bit) << 1) << (lastPos - shiftAmount)));

    return output;
  }

  /// @notice Arithmetic right shift for int64
  //  @param number to be shifted
  //  @param number of shifts
  function int64_arith_shift_right(int64 number, uint shiftAmount)
  public pure returns(int64)
  {
    uint64 u_number = uint64(number);
    uint lastPos = 63;
    uint sign_bit = u_number >> lastPos;

    int64 output = int64((u_number >> shiftAmount) |
          (((0 - sign_bit) << 1) << (lastPos - shiftAmount)));

    return output;
  }

  /// @notice Swap byte order of unsigned ints with 64 bytes
  //  @param  number to have bytes swapped
  function uint64_swapEndian(uint64 num) public pure returns(uint64){
    uint64 output =
      ((num &  0x00000000000000ff) << 56)|
      ((num &  0x000000000000ff00) << 40)|
      ((num &  0x0000000000ff0000) << 24)|
      ((num &  0x00000000ff000000) << 8) |
      ((num &  0x000000ff00000000) >> 8) |
      ((num &  0x0000ff0000000000) >> 24)|
      ((num &  0x00ff000000000000) >> 40)|
      ((num &  0xff00000000000000) >> 56);

    return output;
  }

  /// @notice Swap byte order of unsigned ints with 32 bytes
  //  @param  number to have bytes swapped
  function uint32_swapEndian(uint32 num) public pure returns(uint32) {
    uint32 output =
      ((num >> 24) & 0xff) |
      ((num << 8)  & 0xff0000) |
      ((num >> 8)  & 0xff00) |
      ((num << 24) & 0xff000000);
    return output;
  }
}

