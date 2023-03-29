// Copyright 2023 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "contracts/MemoryAccessLog.sol";
import "contracts/interfaces/IMemoryAccessLog.sol";

pragma solidity ^0.8.0;

contract MemoryAccessLogTest is Test {
    using MemoryAccessLog for IMemoryAccessLog.AccessLogs;
    // little endian of 0x8000
    bytes8 constant LITTLE_8000 = 0x0080000000000000;

    function testReadWord() public {
        IMemoryAccessLog.Access[]
            memory accesses = new IMemoryAccessLog.Access[](1);
        accesses[0] = IMemoryAccessLog.Access(
            0,
            LITTLE_8000,
            IMemoryAccessLog.AccessType.Read
        );
        IMemoryAccessLog.AccessLogs memory accessLogs = IMemoryAccessLog
            .AccessLogs(accesses, 0);

        assertEq(
            accessLogs.readWord(0),
            0x8000,
            "readWord value doesn't match"
        );
    }

    function testWriteWord() public {
        IMemoryAccessLog.Access[]
            memory accesses = new IMemoryAccessLog.Access[](1);
        accesses[0] = IMemoryAccessLog.Access(
            0,
            LITTLE_8000,
            IMemoryAccessLog.AccessType.Write
        );
        IMemoryAccessLog.AccessLogs memory accessLogs = IMemoryAccessLog
            .AccessLogs(accesses, 0);
        // write should succeed
        accessLogs.writeWord(0, 0x8000);

        accessLogs.current = 0;
        // // write should fail
        vm.expectRevert(bytes("Written value not match"));
        accessLogs.writeWord(0, 0x8001);
    }
}
