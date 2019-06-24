/// @title Library for Merkle proofs
pragma solidity ^0.5.0;


library Merkle {
    function getRoot(uint64 _position, bytes8 _value, bytes32[] memory proof) internal pure returns (bytes32) {
        require((_position & 7) == 0, "Position is not aligned");
        require(proof.length == 61, "Proof length does not match");
        bytes32 runningHash = keccak256(abi.encodePacked(_value));
        // iterate the hash with the uncle subtree provided in proof
        uint64 eight = 8;
        for (uint i = 0; i < 61; i++) {
            if ((_position & (eight << i)) == 0) {
                runningHash = keccak256(abi.encodePacked(runningHash, proof[i]));
            } else {
                runningHash = keccak256(abi.encodePacked(proof[i], runningHash));
            }
        }
        return (runningHash);
    }
}
