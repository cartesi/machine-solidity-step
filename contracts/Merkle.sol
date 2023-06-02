// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Merkle {
    function getRootWithValue(
        uint64 position,
        bytes8 v,
        bytes32[] memory proof
    ) public pure returns (bytes32) {
        bytes32 runningHash = keccak256(abi.encodePacked(v));

        return getRootWithDrive(position, 3, runningHash, proof);
    }

    function getRootWithHash(
        uint64 position,
        bytes32 h,
        bytes32[] memory proof
    ) public pure returns (bytes32) {
        return getRootWithDrive(position, 3, h, proof);
    }

    function getRootWithDrive(
        uint64 position,
        uint8 logOfSize,
        bytes32 drive,
        bytes32[] memory siblings
    ) public pure returns (bytes32) {
        require(logOfSize >= 3, "Must be at least a word");
        require(logOfSize <= 64, "Cannot be bigger than the machine itself");

        uint64 size = uint64(2) ** logOfSize;

        require(((size - 1) & position) == 0, "Position is not aligned");
        require(
            siblings.length == 64 - logOfSize,
            "Proof length does not match"
        );

        for (uint64 i = 0; i < siblings.length; i++) {
            if ((position & (size << i)) == 0) {
                drive = keccak256(abi.encodePacked(drive, siblings[i]));
            } else {
                drive = keccak256(abi.encodePacked(siblings[i], drive));
            }
        }

        return drive;
    }
}
