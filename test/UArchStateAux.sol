// Copyright 2023 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "./MemoryAccessLogAux.sol";
import "contracts/UArchConstants.sol";
import "contracts/interfaces/IMemoryAccessLog.sol";
import "contracts/interfaces/IUArchState.sol";

contract UArchStateAux is IUArchState, UArchConstants {
    using MemoryAccessLogAux for mapping(uint64 => bytes8);

    mapping(uint64 => bytes8) physicalMemory;

    function loadMemory(uint64 paddr, bytes8 value) external {
        physicalMemory[paddr] = value;
    }

    function readWord(
        IMemoryAccessLog.AccessLogs memory,
        uint64 paddr
    ) external view override returns (uint64) {
        return physicalMemory.readWord(paddr);
    }

    function readHaltFlag(
        IMemoryAccessLog.AccessLogs memory
    ) external view override returns (bool) {
        return (physicalMemory.readWord(UHALT) != 0);
    }

    function readPc(
        IMemoryAccessLog.AccessLogs memory
    ) external view override returns (uint64) {
        return physicalMemory.readWord(UPC);
    }

    function readCycle(
        IMemoryAccessLog.AccessLogs memory
    ) external view override returns (uint64) {
        return physicalMemory.readWord(UCYCLE);
    }

    function writeCycle(
        IMemoryAccessLog.AccessLogs memory,
        uint64 val
    ) external override {
        physicalMemory.writeWord(UCYCLE, val);
    }

    function readX(
        IMemoryAccessLog.AccessLogs memory,
        uint64 index
    ) external view override returns (uint64) {
        return physicalMemory.readWord(UX0 + (index << 3));
    }

    function writeWord(
        IMemoryAccessLog.AccessLogs memory,
        uint64 paddr,
        uint64 val
    ) external override {
        physicalMemory.writeWord(paddr, val);
    }

    function writeX(
        IMemoryAccessLog.AccessLogs memory,
        uint64 index,
        uint64 val
    ) external override {
        physicalMemory.writeWord(UX0 + (index << 3), val);
    }

    function writePc(
        IMemoryAccessLog.AccessLogs memory,
        uint64 val
    ) external override {
        physicalMemory.writeWord(UPC, val);
    }
}
