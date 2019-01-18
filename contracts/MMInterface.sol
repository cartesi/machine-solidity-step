/// @title Interface for memory manager instantiator
pragma solidity ^0.5.0;

import "./Instantiator.sol";

contract MMInterface is Instantiator
{
  enum state { WaitingProofs, WaitingReplay, FinishedReplay }

  function newHash(uint256 _index) public view returns (bytes32);
  function instantiate(address _provider, address _client,
                       bytes32 _initialHash) public returns (uint256);
  function stateIsWaitingProofs(uint256 _index) public view returns(bool);
  function stateIsWaitingReplay(uint256 _index) public view returns(bool);
  function stateIsFinishedReplay(uint256 _index) public view returns(bool);
}
