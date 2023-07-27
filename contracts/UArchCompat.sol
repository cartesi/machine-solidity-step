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

import "./interfaces/IUArchState.sol";

/// @dev `state.accessLogs.current` is increment here as external calls are incapable of keeping the memory state changes.
/// The `current` value increment is `unchecked` because it's safe and impossible to exceed uint256.max accesses in one step.
/// All `unchecked` blocks in `(u)int` functions are intentional to be consistent with C++ implementation.
library UArchCompat {
    function readWord(
        IUArchState.State memory state,
        uint64 paddr
    ) internal returns (uint64) {
        uint64 res = state.stateInterface.readWord(state.accessLogs, paddr);
        unchecked {
            ++state.accessLogs.current;
        }
        return res;
    }

    function readPc(IUArchState.State memory state) internal returns (uint64) {
        uint64 res = state.stateInterface.readPc(state.accessLogs);
        unchecked {
            ++state.accessLogs.current;
        }
        return res;
    }

    function readHaltFlag(
        IUArchState.State memory state
    ) internal returns (bool) {
        bool res = state.stateInterface.readHaltFlag(state.accessLogs);
        unchecked {
            ++state.accessLogs.current;
        }
        return res;
    }

    function readCycle(
        IUArchState.State memory state
    ) internal returns (uint64) {
        uint64 res = state.stateInterface.readCycle(state.accessLogs);
        unchecked {
            ++state.accessLogs.current;
        }
        return res;
    }

    function writeCycle(IUArchState.State memory state, uint64 val) internal {
        state.stateInterface.writeCycle(state.accessLogs, val);
        unchecked {
            ++state.accessLogs.current;
        }
    }

    function readX(
        IUArchState.State memory state,
        uint8 index
    ) internal returns (uint64) {
        uint64 res = state.stateInterface.readX(state.accessLogs, index);
        unchecked {
            ++state.accessLogs.current;
        }
        return res;
    }

    function writeWord(
        IUArchState.State memory state,
        uint64 paddr,
        uint64 val
    ) internal {
        state.stateInterface.writeWord(state.accessLogs, paddr, val);
        unchecked {
            ++state.accessLogs.current;
        }
    }

    function writeX(
        IUArchState.State memory state,
        uint8 index,
        uint64 val
    ) internal {
        state.stateInterface.writeX(state.accessLogs, index, val);
        unchecked {
            ++state.accessLogs.current;
        }
    }

    function writePc(IUArchState.State memory state, uint64 val) internal {
        state.stateInterface.writePc(state.accessLogs, val);
        unchecked {
            ++state.accessLogs.current;
        }
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
