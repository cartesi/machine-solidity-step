/// @title Interface for memory manager instantiator
pragma solidity ^0.5.0;

contract Instantiator
{
  uint256 internal currentIndex = 0;

  modifier onlyInstantiated(uint256 _index)
  { require(currentIndex > _index); _; }
}
