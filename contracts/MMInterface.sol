/// @title Interface for memory manager instantiator
pragma solidity 0.5;

import "./Instantiator.sol";

contract MMInterface is Instantiator
{
  enum state { WaitingProofs, WaitingReplay, FinishedReplay }
  function getCurrentState(uint256 _index) public view
    returns (bytes32);

  function instantiate(address _provider, address _client,
                       bytes32 _initialHash) public returns (uint256);
  function read(uint256 _index, uint64 _position) public returns (bytes8);
  function write(uint256 _index, uint64 _position, bytes8 _value) public;
  function newHash(uint256 _index) public view returns (bytes32);
  function finishProofPhase(uint256 _index) public;
  function finishReplayPhase(uint256 _index) public;
  function stateIsWaitingProofs(uint256 _index) public view returns(bool);
  function stateIsWaitingReplay(uint256 _index) public view returns(bool);
  function stateIsFinishedReplay(uint256 _index) public view returns(bool);
}
