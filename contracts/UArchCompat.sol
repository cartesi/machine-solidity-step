// Copyright 2023 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title UArchCompat
/// @author Stephen Chen
/// @notice Compatibility layer functions that guarantee same result as the cpp code
/// @dev All functions in the compatibility layer should never throw exceptions

pragma solidity ^0.8.0;

import "./interfaces/IUArchState.sol";

library UArchCompat {
    function readWord(
        IUArchState.State memory state,
        uint64 paddr
    ) internal returns (uint64) {
        IUArchState s = IUArchState(state.stateInterface);
        return s.readWord(state.accessLogs, paddr);
    }

    function readPc(IUArchState.State memory state) internal returns (uint64) {
        IUArchState s = IUArchState(state.stateInterface);
        return s.readPc(state.accessLogs);
    }

    function readHaltFlag(
        IUArchState.State memory state
    ) internal returns (bool) {
        IUArchState s = IUArchState(state.stateInterface);
        return s.readHaltFlag(state.accessLogs);
    }

    function readCycle(
        IUArchState.State memory state
    ) internal returns (uint64) {
        IUArchState s = IUArchState(state.stateInterface);
        return s.readCycle(state.accessLogs);
    }

    function writeCycle(IUArchState.State memory state, uint64 val) internal {
        IUArchState s = IUArchState(state.stateInterface);
        s.writeCycle(state.accessLogs, val);
    }

    function readX(
        IUArchState.State memory state,
        uint64 index
    ) internal returns (uint64) {
        IUArchState s = IUArchState(state.stateInterface);
        return s.readX(state.accessLogs, index);
    }

    function writeWord(
        IUArchState.State memory state,
        uint64 paddr,
        uint64 val
    ) internal {
        IUArchState s = IUArchState(state.stateInterface);
        s.writeWord(state.accessLogs, paddr, val);
    }

    function writeX(
        IUArchState.State memory state,
        uint64 index,
        uint64 val
    ) internal {
        IUArchState s = IUArchState(state.stateInterface);
        s.writeX(state.accessLogs, index, val);
    }

    function writePc(IUArchState.State memory state, uint64 val) internal {
        IUArchState s = IUArchState(state.stateInterface);
        s.writePc(state.accessLogs, val);
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

    function int64ShiftLeft(
        int64 v,
        uint32 count
    ) internal pure returns (int64) {
        return v << (count & 0x3f);
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

    function int32ShiftLeft(
        int32 v,
        uint32 count
    ) internal pure returns (int32) {
        return v << (count & 0x1f);
    }
}
