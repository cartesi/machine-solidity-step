// Copyright 2019 Cartesi Pte. Ltd.

// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title Library for Merkle proofs
pragma solidity ^0.5.0;

/// @title Merkle
/// @author Augusto Teixeira
/// @notice Implements the getRoot function for a Merkle tree
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
