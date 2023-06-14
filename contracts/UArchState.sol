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
import "./Memory.sol";
import "./UArchConstants.sol";

contract UArchState is IUArchState, UArchConstants {
    using AccessLogs for AccessLogs.Context;
    using Memory for uint64;

    function readCycle(
        AccessLogs.Context memory a
    ) external pure override returns (uint64, AccessLogs.Context memory) {
        uint64 cycle = a.readWord(UCYCLE.toPhysicalAddress());
        return (cycle, a);
    }

    function readHaltFlag(
        AccessLogs.Context memory a
    ) external pure override returns (bool, AccessLogs.Context memory) {
        bool halt = (a.readWord(UHALT.toPhysicalAddress()) != 0);
        return (halt, a);
    }

    function readPc(
        AccessLogs.Context memory a
    ) external pure override returns (uint64, AccessLogs.Context memory) {
        uint64 pc = a.readWord(UPC.toPhysicalAddress());
        return (pc, a);
    }

    function readWord(
        AccessLogs.Context memory a,
        uint64 paddr
    ) external pure override returns (uint64, AccessLogs.Context memory) {
        uint64 word = a.readWord(paddr.toPhysicalAddress());
        return (word, a);
    }

    function readX(
        AccessLogs.Context memory a,
        uint8 index
    ) external pure override returns (uint64, AccessLogs.Context memory) {
        uint64 paddr;
        unchecked {
            paddr = UX0 + (index << 3);
        }
        uint64 x = a.readWord(paddr.toPhysicalAddress());
        return (x, a);
    }

    function writeCycle(
        AccessLogs.Context memory a,
        uint64 val
    ) external pure override returns (AccessLogs.Context memory) {
        a.writeWord(UCYCLE.toPhysicalAddress(), val);
        return a;
    }

    function writePc(
        AccessLogs.Context memory a,
        uint64 val
    ) external pure override returns (AccessLogs.Context memory) {
        a.writeWord(UPC.toPhysicalAddress(), val);
        return a;
    }

    function writeWord(
        AccessLogs.Context memory a,
        uint64 paddr,
        uint64 val
    ) external pure override returns (AccessLogs.Context memory) {
        a.writeWord(paddr.toPhysicalAddress(), val);
        return a;
    }

    function writeX(
        AccessLogs.Context memory a,
        uint8 index,
        uint64 val
    ) external pure override returns (AccessLogs.Context memory) {
        uint64 paddr;
        unchecked {
            paddr = UX0 + (index << 3);
        }
        a.writeWord(paddr.toPhysicalAddress(), val);
        return a;
    }
}
