pragma solidity ^0.5.0;


contract Decorated {
  // This contract defines several modifiers but does not use
  // them - they will be used in derived contracts.
    modifier onlyBy(address user) {
        require(msg.sender == user, "Cannot be called by user");
        _;
    }

    modifier onlyAfter(uint time) {
        require(now > time, "Cannot be called now");
        _;
    }
}
