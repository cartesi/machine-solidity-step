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

import "./AccessLogsAux.sol";
import "contracts/UArchConstants.sol";
import "contracts/interfaces/IUArchState.sol";

contract UArchStateAux is IUArchState {
    using AccessLogsAux for mapping(uint64 => bytes8);

    mapping(uint64 => bytes8) physicalMemory;

    function loadMemory(uint64 paddr, bytes8 value) external {
        physicalMemory[paddr] = value;
    }

    function readCycle(
        AccessLogs.Context memory a
    ) external view override returns (uint64, AccessLogs.Context memory) {
        return (physicalMemory.readWord(UArchConstants.UCYCLE), a);
    }

    function readHaltFlag(
        AccessLogs.Context memory a
    ) external view override returns (bool, AccessLogs.Context memory) {
        return ((physicalMemory.readWord(UArchConstants.UHALT) != 0), a);
    }

    function readPc(
        AccessLogs.Context memory a
    ) external view override returns (uint64, AccessLogs.Context memory) {
        return (physicalMemory.readWord(UArchConstants.UPC), a);
    }

    function readWord(
        AccessLogs.Context memory a,
        uint64 paddr
    ) external view override returns (uint64, AccessLogs.Context memory) {
        return (physicalMemory.readWord(paddr), a);
    }

    function readX(
        AccessLogs.Context memory a,
        uint8 index
    ) external view override returns (uint64, AccessLogs.Context memory) {
        uint64 paddr;
        unchecked {
            paddr = UArchConstants.UX0 + (index << 3);
        }
        return (physicalMemory.readWord(paddr), a);
    }

    function writeCycle(
        AccessLogs.Context memory a,
        uint64 val
    ) external override returns (AccessLogs.Context memory) {
        physicalMemory.writeWord(UArchConstants.UCYCLE, val);
        return a;
    }

    function writePc(
        AccessLogs.Context memory a,
        uint64 val
    ) external override returns (AccessLogs.Context memory) {
        physicalMemory.writeWord(UArchConstants.UPC, val);
        return a;
    }

    function writeWord(
        AccessLogs.Context memory a,
        uint64 paddr,
        uint64 val
    ) external override returns (AccessLogs.Context memory) {
        physicalMemory.writeWord(paddr, val);
        return a;
    }

    function writeX(
        AccessLogs.Context memory a,
        uint8 index,
        uint64 val
    ) external override returns (AccessLogs.Context memory) {
        uint64 paddr;
        unchecked {
            paddr = UArchConstants.UX0 + (index << 3);
        }
        physicalMemory.writeWord(paddr, val);
        return a;
    }
}
