/// @title Interface for memory manager instantiator
pragma solidity 0.5;

contract Instantiator
{
  uint256 public currentIndex = 0;

  mapping(uint256 => bool) internal active;
  mapping(uint256 => uint256) internal nonce;

  function isActive(uint256 _index) public view returns(bool)
  {
    return(active[_index]);
  }

  modifier onlyInstantiated(uint256 _index)
  {
    require(currentIndex > _index, "Index not instantiated");
    _;
  }

  modifier onlyActive(uint256 _index)
  {
    require(currentIndex > _index, "Index not instantiated");
    require(isActive(_index), "Index inactive");
    _;
  }

  modifier increasesNonce(uint256 _index)
  {
    nonce[_index]++;
    _;
  }

  function deactivate(uint256 _index) internal
  {
    active[_index] = false;
    nonce[_index] = 0;
  }

  function getNonce(uint256 _index) public view
    onlyActive(_index)
    returns(uint256 currentNonce)
  {
    return nonce[_index];
  }

  function isConcerned(uint256 _index, address _user) public view returns(bool);

  function getSubInstances(uint256 _index)
    public view returns(address[] memory _addresses,
                        uint256[] memory _indices);
}
