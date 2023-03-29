// Copyright 2023 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title MemoryAccessLog.sol

pragma solidity ^0.8.0;

import "./interfaces/IMemoryAccessLog.sol";
import "@cartesi/util/contracts/BitsManipulation.sol";

/// @title MemoryAccessLog
/// @author Stephen Chen
/// @notice Behaves as physical memory to offer accesses to interpret
/// @dev Every read performed by memoryRead or memoryWrite should contain an
/// @dev endianess swap from little endian to big endian. This is the case because
/// @dev EVM is big endian but RiscV is little endian.
/// @dev Reference: riscv-spec-v2.2.pdf - Preface to Version 2.0
/// @dev Reference: Ethereum yellowpaper - Version 69351d5
/// @dev    Appendix H. Virtual Machine Specification
library MemoryAccessLog {
    function readWord(
        IMemoryAccessLog.AccessLogs memory a,
        uint64 readAddress
    ) external pure returns (uint64) {
        return
            BitsManipulation.uint64SwapEndian(
                uint64(
                    accessManager(
                        a,
                        readAddress,
                        IMemoryAccessLog.AccessType.Read
                    )
                )
            );
    }

    function writeWord(
        IMemoryAccessLog.AccessLogs memory a,
        uint64 writeAddress,
        uint64 val
    ) external pure {
        bytes8 bytesValue = bytes8(BitsManipulation.uint64SwapEndian(val));
        require(
            accessManager(a, writeAddress, IMemoryAccessLog.AccessType.Write) ==
                bytesValue,
            "Written value not match"
        );
    }

    // takes care of read/write access
    function accessManager(
        IMemoryAccessLog.AccessLogs memory a,
        uint64 addr,
        IMemoryAccessLog.AccessType accessType
    ) private pure returns (bytes8) {
        require(a.current < a.logs.length, "Too many accesses");

        IMemoryAccessLog.Access memory access = a.logs[a.current];

        require(access.accessType == accessType, "Access type not match");

        require(
            access.position == addr,
            "Position and access address not match"
        );

        unchecked {
            ++a.current;
        }

        return access.val;
    }
}
