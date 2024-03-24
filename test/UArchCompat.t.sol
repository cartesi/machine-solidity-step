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
import "forge-std/console.sol";
import "forge-std/Test.sol";
import "src/UArchCompat.sol";

pragma solidity ^0.8.0;

contract UArchCompatTest is Test {
    int16 constant INT16_MAX = type(int16).max;
    int32 constant INT32_MAX = type(int32).max;
    int64 constant INT64_MAX = type(int64).max;
    int16 constant INT16_MIN = type(int16).min;
    int32 constant INT32_MIN = type(int32).min;
    int64 constant INT64_MIN = type(int64).min;
    uint16 constant UINT16_MAX = type(uint16).max;
    uint32 constant UINT32_MAX = type(uint32).max;
    uint64 constant UINT64_MAX = type(uint64).max;

    function testSanity() public {
        assertEq(UINT16_MAX, 65535);
        assertEq(UINT32_MAX, 4294967295);
        assertEq(UINT64_MAX, 18446744073709551615);
        assertEq(INT16_MAX, 32767);
        assertEq(INT32_MAX, 2147483647);
        assertEq(INT64_MAX, 9223372036854775807);
        assertEq(INT16_MIN, -32768);
        assertEq(INT32_MIN, -INT32_MAX - 1);
        assertEq(INT64_MIN, -INT64_MAX - 1);
    }

    function testCompat() public {
        assertEq(UArchCompat.uint64ToInt32(1), 1);
        assertEq(UArchCompat.uint64ToInt32(0xffffffff), -1);
        assertEq(UArchCompat.uint64ToInt32(0xffffffff << 31), INT32_MIN);
        assertEq(UArchCompat.uint64ToInt32(0xffffffff << 32), 0);

        assertEq(UArchCompat.uint64AddInt32(2, -1), 1);
        assertEq(UArchCompat.uint64AddInt32(0, -1), UINT64_MAX);
        assertEq(UArchCompat.uint64AddInt32(UINT64_MAX, 1), 0);

        assertEq(UArchCompat.uint64SubUint64(1, 1), 0);
        assertEq(UArchCompat.uint64SubUint64(0, 1), UINT64_MAX);

        assertEq(UArchCompat.uint64AddUint64(0, 1), 1);
        assertEq(UArchCompat.uint64AddUint64(UINT64_MAX, 1), 0);

        assertEq(UArchCompat.uint64ShiftRight(0, 0), 0);
        assertEq(UArchCompat.uint64ShiftRight(0, 1), 0);
        assertEq(UArchCompat.uint64ShiftRight(4, 1), 2);
        assertEq(UArchCompat.uint64ShiftRight(4, 2), 1);
        assertEq(UArchCompat.uint64ShiftRight(4, 3), 0);
        assertEq(UArchCompat.uint64ShiftRight(UINT64_MAX, 63), 1);

        assertEq(UArchCompat.uint64ShiftLeft(0, 0), 0);
        assertEq(UArchCompat.uint64ShiftLeft(0, 1), 0);
        assertEq(UArchCompat.uint64ShiftLeft(4, 1), 8);
        assertEq(UArchCompat.uint64ShiftLeft(4, 2), 16);
        assertEq(UArchCompat.uint64ShiftLeft(UINT64_MAX, 63), 1 << 63);

        assertEq(UArchCompat.int64ShiftRight(0, 0), 0);
        assertEq(UArchCompat.int64ShiftRight(0, 1), 0);
        assertEq(UArchCompat.int64ShiftRight(4, 1), 2);
        assertEq(UArchCompat.int64ShiftRight(4, 2), 1);
        assertEq(UArchCompat.int64ShiftRight(4, 3), 0);
        assertEq(UArchCompat.int64ShiftRight(INT64_MAX, 62), 1);
        assertEq(UArchCompat.int64ShiftRight(INT64_MAX, 63), 0);
        assertEq(UArchCompat.int64ShiftRight(-1, 1), -1);
        assertEq(UArchCompat.int64ShiftRight(-4, 1), -2);
        assertEq(UArchCompat.int64ShiftRight(INT64_MIN, 62), -2);
        assertEq(UArchCompat.int64ShiftRight(INT64_MIN, 63), -1);

        assertEq(UArchCompat.int64AddInt64(0, 0), 0);
        assertEq(UArchCompat.int64AddInt64(0, 1), 1);
        assertEq(UArchCompat.int64AddInt64(0, -1), -1);
        assertEq(UArchCompat.int64AddInt64(-1, 0), -1);
        assertEq(UArchCompat.int64AddInt64(INT64_MAX, 1), INT64_MIN);
        assertEq(UArchCompat.int64AddInt64(INT64_MAX, INT64_MAX), -2);

        assertEq(UArchCompat.uint32ShiftRight(0, 0), 0);
        assertEq(UArchCompat.uint32ShiftRight(0, 1), 0);
        assertEq(UArchCompat.uint32ShiftRight(4, 1), 2);
        assertEq(UArchCompat.uint32ShiftRight(4, 2), 1);
        assertEq(UArchCompat.uint32ShiftRight(4, 3), 0);
        assertEq(UArchCompat.uint32ShiftRight(UINT32_MAX, 31), 1);

        assertEq(UArchCompat.uint32ShiftLeft(0, 0), 0);
        assertEq(UArchCompat.uint32ShiftLeft(0, 1), 0);
        assertEq(UArchCompat.uint32ShiftLeft(4, 1), 8);
        assertEq(UArchCompat.uint32ShiftLeft(4, 2), 16);
        assertEq(UArchCompat.uint32ShiftLeft(4, 3), 32);
        assertEq(UArchCompat.uint32ShiftLeft(UINT32_MAX, 31), 0x80000000);

        assertEq(UArchCompat.int32ToUint64(1), 1);
        assertEq(UArchCompat.int32ToUint64(INT32_MAX), 2147483647);
        assertEq(UArchCompat.int32ToUint64(INT32_MIN), 0xffffffff80000000);

        assertEq(UArchCompat.int32ShiftRight(0, 0), 0);
        assertEq(UArchCompat.int32ShiftRight(0, 1), 0);
        assertEq(UArchCompat.int32ShiftRight(4, 1), 2);
        assertEq(UArchCompat.int32ShiftRight(4, 2), 1);
        assertEq(UArchCompat.int32ShiftRight(4, 3), 0);
        assertEq(UArchCompat.int32ShiftRight(INT32_MAX, 30), 1);
        assertEq(UArchCompat.int32ShiftRight(INT32_MAX, 31), 0);
        assertEq(UArchCompat.int32ShiftRight(-1, 1), -1);
        assertEq(UArchCompat.int32ShiftRight(-4, 1), -2);
        assertEq(UArchCompat.int32ShiftRight(INT32_MIN, 30), -2);
        assertEq(UArchCompat.int32ShiftRight(INT32_MIN, 31), -1);

        assertEq(UArchCompat.int32AddInt32(0, 0), 0);
        assertEq(UArchCompat.int32AddInt32(0, 1), 1);
        assertEq(UArchCompat.int32AddInt32(0, -1), -1);
        assertEq(UArchCompat.int32AddInt32(-1, 0), -1);
        assertEq(UArchCompat.int32AddInt32(INT32_MAX, 1), INT32_MIN);
        assertEq(UArchCompat.int32AddInt32(INT32_MAX, INT32_MAX), -2);

        assertEq(UArchCompat.int32SubInt32(1, 1), 0);
        assertEq(UArchCompat.int32SubInt32(1, 0), 1);
        assertEq(UArchCompat.int32SubInt32(0, 1), -1);
        assertEq(UArchCompat.int32SubInt32(-1, -1), 0);
        assertEq(UArchCompat.int32SubInt32(INT32_MIN, INT32_MAX), 1);
        assertEq(UArchCompat.int32SubInt32(INT32_MAX, INT32_MIN), -1);

        assertEq(UArchCompat.int16ToUint64(1), 1);
        assertEq(UArchCompat.int16ToUint64(INT16_MAX), 32767);
        assertEq(UArchCompat.int16ToUint64(INT16_MIN), 0xffffffffffff8000);

        assertEq(UArchCompat.int8ToUint64(int8(1)), 1);
        assertEq(UArchCompat.int8ToUint64(int8(127)), 127);
        assertEq(UArchCompat.int8ToUint64(int8(-128)), 0xffffffffffffff80);
    }
}
