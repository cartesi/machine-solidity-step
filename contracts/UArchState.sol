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

import "./interfaces/IMemoryAccessLog.sol";
import "./interfaces/IUArchState.sol";
import "./MemoryAccessLog.sol";
import "./UArchConstants.sol";

contract UArchState is IUArchState, UArchConstants {
    using MemoryAccessLog for IMemoryAccessLog.AccessLogs;

    function readWord(
        IMemoryAccessLog.AccessLogs memory a,
        uint64 paddr
    ) external pure override returns (uint64) {
        return a.readWord(paddr);
    }

    function readHaltFlag(
        IMemoryAccessLog.AccessLogs memory a
    ) external pure override returns (bool) {
        return (a.readWord(UHALT) != 0);
    }

    function readPc(
        IMemoryAccessLog.AccessLogs memory a
    ) external pure override returns (uint64) {
        return a.readWord(UPC);
    }

    function readCycle(
        IMemoryAccessLog.AccessLogs memory a
    ) external pure override returns (uint64) {
        return a.readWord(UCYCLE);
    }

    function writeCycle(
        IMemoryAccessLog.AccessLogs memory a,
        uint64 val
    ) external pure override {
        a.writeWord(UCYCLE, val);
    }

    function readX(
        IMemoryAccessLog.AccessLogs memory a,
        uint8 index
    ) external pure override returns (uint64) {
        return a.readWord(UX0 + (index << 3));
    }

    function writeWord(
        IMemoryAccessLog.AccessLogs memory a,
        uint64 paddr,
        uint64 val
    ) external pure override {
        a.writeWord(paddr, val);
    }

    function writeX(
        IMemoryAccessLog.AccessLogs memory a,
        uint8 index,
        uint64 val
    ) external pure override {
        a.writeWord(UX0 + (index << 3), val);
    }

    function writePc(
        IMemoryAccessLog.AccessLogs memory a,
        uint64 val
    ) external pure override {
        a.writeWord(UPC, val);
    }
}
