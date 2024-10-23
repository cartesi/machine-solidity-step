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

import "./EmulatorConstants.sol";
import "./AccessLogs.sol";

library EmulatorCompat {
    using AccessLogs for AccessLogs.Context;
    using Memory for uint64;

    function readCycle(AccessLogs.Context memory a)
        internal
        pure
        returns (uint64)
    {
        return a.readWord(
            EmulatorConstants.UARCH_CYCLE_ADDRESS.toPhysicalAddress()
        );
    }

    function readHaltFlag(AccessLogs.Context memory a)
        internal
        pure
        returns (bool)
    {
        return (
            a.readWord(
                EmulatorConstants.UARCH_HALT_FLAG_ADDRESS.toPhysicalAddress()
            ) != 0
        );
    }

    function readPc(AccessLogs.Context memory a)
        internal
        pure
        returns (uint64)
    {
        return
            a.readWord(EmulatorConstants.UARCH_PC_ADDRESS.toPhysicalAddress());
    }

    function readWord(AccessLogs.Context memory a, uint64 paddr)
        internal
        pure
        returns (uint64)
    {
        return a.readWord(paddr.toPhysicalAddress());
    }

    function readX(AccessLogs.Context memory a, uint8 index)
        internal
        pure
        returns (uint64)
    {
        uint64 paddr;
        unchecked {
            paddr = EmulatorConstants.UARCH_X0_ADDRESS + (index << 3);
        }
        return a.readWord(paddr.toPhysicalAddress());
    }

    function writeCycle(AccessLogs.Context memory a, uint64 val)
        internal
        pure
    {
        a.writeWord(
            EmulatorConstants.UARCH_CYCLE_ADDRESS.toPhysicalAddress(), val
        );
    }

    function setHaltFlag(AccessLogs.Context memory a) internal pure {
        a.writeWord(
            EmulatorConstants.UARCH_HALT_FLAG_ADDRESS.toPhysicalAddress(), 1
        );
    }

    function writePc(AccessLogs.Context memory a, uint64 val) internal pure {
        a.writeWord(EmulatorConstants.UARCH_PC_ADDRESS.toPhysicalAddress(), val);
    }

    function writeWord(AccessLogs.Context memory a, uint64 paddr, uint64 val)
        internal
        pure
    {
        a.writeWord(paddr.toPhysicalAddress(), val);
    }

    function writeX(AccessLogs.Context memory a, uint8 index, uint64 val)
        internal
        pure
    {
        uint64 paddr;
        unchecked {
            paddr = EmulatorConstants.UARCH_X0_ADDRESS + (index << 3);
        }
        a.writeWord(paddr.toPhysicalAddress(), val);
    }

    function resetState(AccessLogs.Context memory a) internal pure {
        a.writeRegion(
            Memory.regionFromPhysicalAddress(
                EmulatorConstants.UARCH_STATE_START_ADDRESS.toPhysicalAddress(),
                Memory.alignedSizeFromLog2(
                    EmulatorConstants.UARCH_STATE_LOG2_SIZE - Memory.LOG2_LEAF
                )
            ),
            EmulatorConstants.UARCH_PRISTINE_STATE_HASH
        );
    }

    function readIflagsY(AccessLogs.Context memory a)
        internal
        pure
        returns (bool)
    {
        uint64 iflags =
            a.readWord(EmulatorConstants.IFLAGS_ADDRESS.toPhysicalAddress());
        if (uint64ShiftRight(iflags, EmulatorConstants.IFLAGS_Y_SHIFT) & 1 == 0)
        {
            return false;
        }
        return true;
    }

    function resetIflagsY(AccessLogs.Context memory a) internal pure {
        uint64 iflags =
            a.readWord(EmulatorConstants.IFLAGS_ADDRESS.toPhysicalAddress());
        iflags = iflags & ~uint64ShiftLeft(1, EmulatorConstants.IFLAGS_Y_SHIFT);
        a.writeWord(
            EmulatorConstants.IFLAGS_ADDRESS.toPhysicalAddress(), iflags
        );
    }

    function writeHtifFromhost(AccessLogs.Context memory a, uint64 val)
        internal
        pure
    {
        a.writeWord(
            EmulatorConstants.HTIF_FROMHOST_ADDRESS.toPhysicalAddress(), val
        );
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

    function uint64SubUint64(uint64 a, uint64 b)
        internal
        pure
        returns (uint64)
    {
        uint64 res;
        unchecked {
            res = a - b;
        }
        return res;
    }

    function uint64AddUint64(uint64 a, uint64 b)
        internal
        pure
        returns (uint64)
    {
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

    function uint64ShiftRight(uint64 v, uint32 count)
        internal
        pure
        returns (uint64)
    {
        return v >> (count & 0x3f);
    }

    function uint64ShiftLeft(uint64 v, uint32 count)
        internal
        pure
        returns (uint64)
    {
        return v << (count & 0x3f);
    }

    function int64ShiftRight(int64 v, uint32 count)
        internal
        pure
        returns (int64)
    {
        return v >> (count & 0x3f);
    }

    function uint32ShiftRight(uint32 v, uint32 count)
        internal
        pure
        returns (uint32)
    {
        return v >> (count & 0x1f);
    }

    function uint32ShiftLeft(uint32 v, uint32 count)
        internal
        pure
        returns (uint32)
    {
        return v << (count & 0x1f);
    }

    function int32ShiftRight(int32 v, uint32 count)
        internal
        pure
        returns (int32)
    {
        return v >> (count & 0x1f);
    }

    function throwRuntimeError(
        AccessLogs.Context memory, /* a */
        string memory text
    ) internal pure {
        revert(text);
    }

    function putChar(AccessLogs.Context memory a, uint8 c) internal pure {}

    function uint32Log2(uint32 value) external pure returns (uint32) {
        require(value > 0, "EmulatorCompat: log2(0) is undefined");
        uint32 result = 0;
        while (value > 1) {
            value >>= 1;
            result++;
        }
        return result;
    }
}
