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

import "./UArchConstants.sol";
import "./AccessLogs.sol";

library UArchCompat {
    using AccessLogs for AccessLogs.Context;
    using Memory for uint64;

    function readCycle(AccessLogs.Context memory a)
        internal
        pure
        returns (uint64)
    {
        return a.readWord(UArchConstants.UCYCLE.toPhysicalAddress());
    }

    function readHaltFlag(AccessLogs.Context memory a)
        internal
        pure
        returns (bool)
    {
        return (a.readWord(UArchConstants.UHALT.toPhysicalAddress()) != 0);
    }

    function readPc(AccessLogs.Context memory a)
        internal
        pure
        returns (uint64)
    {
        return a.readWord(UArchConstants.UPC.toPhysicalAddress());
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
            paddr = UArchConstants.UX0 + (index << 3);
        }
        return a.readWord(paddr.toPhysicalAddress());
    }

    function writeCycle(AccessLogs.Context memory a, uint64 val)
        internal
        pure
    {
        a.writeWord(UArchConstants.UCYCLE.toPhysicalAddress(), val);
    }

    function setHaltFlag(AccessLogs.Context memory a) internal pure {
        a.writeWord(UArchConstants.UHALT.toPhysicalAddress(), 1);
    }

    function writePc(AccessLogs.Context memory a, uint64 val) internal pure {
        a.writeWord(UArchConstants.UPC.toPhysicalAddress(), val);
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
            paddr = UArchConstants.UX0 + (index << 3);
        }
        a.writeWord(paddr.toPhysicalAddress(), val);
    }

    function resetState(AccessLogs.Context memory a) internal pure {
        a.writeRegion(
            Memory.regionFromPhysicalAddress(
                UArchConstants.RESET_POSITION.toPhysicalAddress(),
                Memory.alignedSizeFromLog2(UArchConstants.RESET_ALIGNED_SIZE)
            ),
            UArchConstants.PRESTINE_STATE
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
}
