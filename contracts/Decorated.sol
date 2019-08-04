pragma solidity ^0.5.0;

/// @title Decorated
/// @author Augusto Teixeira
/// @notice Defines modifiers
contract Decorated {
    modifier onlyBy(address user) {
        require(msg.sender == user, "Cannot be called by user");
        _;
    }

    modifier onlyAfter(uint time) {
        require(now > time, "Cannot be called now");
        _;
    }
}
