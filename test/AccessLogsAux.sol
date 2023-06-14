// Copyright 2023 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

import "contracts/UArchCompat.sol";

pragma solidity ^0.8.0;

library AccessLogsAux {
    function readWord(
        mapping(uint64 => bytes8) storage physicalMemory,
        uint64 readAddress
    ) internal view returns (uint64) {
        return
            UArchCompat.uint64SwapEndian(uint64(physicalMemory[readAddress]));
    }

    function writeWord(
        mapping(uint64 => bytes8) storage physicalMemory,
        uint64 writeAddress,
        uint64 val
    ) internal {
        bytes8 bytesvalue = bytes8(UArchCompat.uint64SwapEndian(val));
        physicalMemory[writeAddress] = bytesvalue;
    }

    function newContext() internal pure returns (AccessLogs.Context memory) {
        return
            AccessLogs.Context(
                bytes32(0),
                new bytes32[](0),
                new uint64[](0),
                0,
                0
            );
    }
}
