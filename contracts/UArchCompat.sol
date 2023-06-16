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

import "./UArchState.sol";

library UArchCompat {
    using UArchState for AccessLogs.Context;

    function readCycle(
        AccessLogs.Context memory accessLogs
    ) internal pure returns (uint64) {
        return accessLogs.readCycle();
    }

    function readHaltFlag(
        AccessLogs.Context memory accessLogs
    ) internal pure returns (bool) {
        return accessLogs.readHaltFlag();
    }

    function readPc(
        AccessLogs.Context memory accessLogs
    ) internal pure returns (uint64) {
        return accessLogs.readPc();
    }

    function readWord(
        AccessLogs.Context memory accessLogs,
        uint64 paddr
    ) internal pure returns (uint64) {
        return accessLogs.readWord(paddr);
    }

    function readX(
        AccessLogs.Context memory accessLogs,
        uint8 index
    ) internal pure returns (uint64) {
        return accessLogs.readX(index);
    }

    function writeCycle(
        AccessLogs.Context memory accessLogs,
        uint64 val
    ) internal pure {
        accessLogs.writeCycle(val);
    }

    function writePc(
        AccessLogs.Context memory accessLogs,
        uint64 val
    ) internal pure {
        accessLogs.writePc(val);
    }

    function writeWord(
        AccessLogs.Context memory accessLogs,
        uint64 paddr,
        uint64 val
    ) internal pure {
        accessLogs.writeWord(paddr, val);
    }

    function writeX(
        AccessLogs.Context memory accessLogs,
        uint8 index,
        uint64 val
    ) internal pure {
        accessLogs.writeX(index, val);
    }

    function int8ToUint64(int8 val) internal pure returns (uint64) {
        return uint64(int64(val));
    }

    function int16ToUint64(int16 val) internal pure returns (uint64) {
        return uint64(int64(val));
    }

    function int32ToUint64(int32 val) internal pure returns (uint64) {
        return uint64(int64(val));
    }

    function uint64ToInt32(uint64 val) internal pure returns (int32) {
        return int32(int64(val));
    }

    function uint64AddInt32(uint64 a, int32 b) internal pure returns (uint64) {
        uint64 res;
        unchecked {
            res = a + int32ToUint64(b);
        }
        return res;
    }

    function uint64SubUint64(
        uint64 a,
        uint64 b
    ) internal pure returns (uint64) {
        uint64 res;
        unchecked {
            res = a - b;
        }
        return res;
    }

    function uint64AddUint64(
        uint64 a,
        uint64 b
    ) internal pure returns (uint64) {
        uint64 res;
        unchecked {
            res = a + b;
        }
        return res;
    }

    function int32AddInt32(int32 a, int32 b) internal pure returns (int32) {
        int32 res;
        unchecked {
            res = a + b;
        }
        return res;
    }

    function int32SubInt32(int32 a, int32 b) internal pure returns (int32) {
        int32 res;
        unchecked {
            res = a - b;
        }
        return res;
    }

    function int64AddInt64(int64 a, int64 b) internal pure returns (int64) {
        int64 res;
        unchecked {
            res = a + b;
        }
        return res;
    }

    function uint64ShiftRight(
        uint64 v,
        uint32 count
    ) internal pure returns (uint64) {
        return v >> (count & 0x3f);
    }

    function uint64ShiftLeft(
        uint64 v,
        uint32 count
    ) internal pure returns (uint64) {
        return v << (count & 0x3f);
    }

    function int64ShiftRight(
        int64 v,
        uint32 count
    ) internal pure returns (int64) {
        return v >> (count & 0x3f);
    }

    function uint32ShiftRight(
        uint32 v,
        uint32 count
    ) internal pure returns (uint32) {
        return v >> (count & 0x1f);
    }

    function uint32ShiftLeft(
        uint32 v,
        uint32 count
    ) internal pure returns (uint32) {
        return v << (count & 0x1f);
    }

    function int32ShiftRight(
        int32 v,
        uint32 count
    ) internal pure returns (int32) {
        return v >> (count & 0x1f);
    }

    /// @notice Swap byte order of unsigned ints with 64 bytes
    /// @param num number to have bytes swapped
    function uint64SwapEndian(uint64 num) internal pure returns (uint64) {
        uint64 output = ((num & 0x00000000000000ff) << 56) |
            ((num & 0x000000000000ff00) << 40) |
            ((num & 0x0000000000ff0000) << 24) |
            ((num & 0x00000000ff000000) << 8) |
            ((num & 0x000000ff00000000) >> 8) |
            ((num & 0x0000ff0000000000) >> 24) |
            ((num & 0x00ff000000000000) >> 40) |
            ((num & 0xff00000000000000) >> 56);

        return output;
    }
}
