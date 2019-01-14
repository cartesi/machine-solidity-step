/// @title AddressTracker
pragma solidity ^0.5.0;

contract AddressTracker {
  address owner;
  address MMAddress;
  address memoryInteractorAddress;
  address fetchAddress;
  address interruptAddress;

  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }

  function getMemoryInteractorAddress() public returns(address){
    return memoryInteractorAddress;
  }

  function getFetchAddress() public returns(address){
    return fetchAddress;
  }

  function getMMAddress() public returns(address){
    return MMAddress;
  }
  
  function getInterruptsAddress() public returns(address){
    return interruptAddress;
  }

  function setMemoryInteractorAddress(address _newAddr) public onlyOwner{
    memoryInteractorAddress = _newAddr;
  }

  function setFetchAddress(address _newAddr) public onlyOwner{
    fetchAddress = _newAddr;
  }

  function setMMAddress(address _newAddr) public onlyOwner{
    MMAddress = _newAddr;
  }

  function setInterruptsAddress(address _newAddr) public onlyOwner{
    interruptAddress = _newAddr;
  }

  function getOwner() public returns(address){
    return owner;
  }

  function setOwner(address _newOwner) public onlyOwner {
    owner = _newOwner;
  }
}
