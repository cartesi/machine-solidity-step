// Copyright Cartesi and individual authors (see AUTHORS)
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

pragma solidity ^0.8.0;

import "./interfaces/IMemoryAccessLog.sol";
import "./UArchCompat.sol";
import "./Merkle.sol";

/// @title MemoryAccessLog
/// @notice Behaves as physical memory to offer accesses to `step`
/// @dev Every read performed by memoryRead or memoryWrite should contain an
/// @dev endianess swap from little endian to big endian. This is the case because
/// @dev EVM is big endian but RiscV is little endian.
/// @dev Reference: riscv-spec-v2.2.pdf - Preface to Version 2.0
/// @dev Reference: Ethereum yellowpaper - Version 69351d5
/// @dev    Appendix H. Virtual Machine Specification
library MemoryAccessLog {
    using MemoryAccessLog for IMemoryAccessLog.AccessLogs;

    function readWord(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[][] memory proofs,
        uint64 readAddress
    ) external pure returns (uint64) {
        bytes8 bytes8Value = a.accessManager(readAddress);

        require(
            machineHash ==
                Merkle.getRootWithValue(
                    a.logs[a.current].position,
                    bytes8Value,
                    proofs[a.current]
                ),
            "Read machine hash doesn't match"
        );

        return UArchCompat.uint64SwapEndian(uint64(bytes8Value));
    }

    function writeWord(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[] memory oldHashes,
        bytes32[][] memory proofs,
        uint256 writeCurrent,
        uint64 writeAddress,
        uint64 val
    ) external pure returns (bytes32) {
        require(
            machineHash ==
                Merkle.getRootWithHash(
                    a.logs[a.current].position,
                    oldHashes[writeCurrent],
                    proofs[a.current]
                ),
            "Write machine hash doesn't match"
        );

        bytes8 bytes8Value = a.accessManager(writeAddress);

        require(
            val == UArchCompat.uint64SwapEndian(uint64(bytes8Value)),
            "Written value mismatch"
        );

        return
            Merkle.getRootWithValue(
                a.logs[a.current].position,
                bytes8Value,
                proofs[a.current]
            );
    }

    // takes care of read/write access
    function accessManager(
        IMemoryAccessLog.AccessLogs memory a,
        uint64 addr
    ) internal pure returns (bytes8) {
        require(a.current < a.logs.length, "Too many accesses");

        IMemoryAccessLog.Access memory access = a.logs[a.current];

        require(
            access.position == addr,
            "Position and access address mismatch"
        );

        return access.val;
    }
}
