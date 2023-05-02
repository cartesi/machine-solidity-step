// Copyright 2023 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title IUArchState

pragma solidity >=0.8.0;

import "./IMemoryAccessLog.sol";

interface IUArchState {
    struct State {
        IUArchState stateInterface;
        IMemoryAccessLog.AccessLogs accessLogs;
    }

    function readCycle(
        IMemoryAccessLog.AccessLogs memory a
    ) external returns (uint64);

    function readHaltFlag(
        IMemoryAccessLog.AccessLogs memory a
    ) external returns (bool);

    function readPc(
        IMemoryAccessLog.AccessLogs memory a
    ) external returns (uint64);

    function readWord(
        IMemoryAccessLog.AccessLogs memory a,
        uint64 paddr
    ) external returns (uint64);

    function readX(
        IMemoryAccessLog.AccessLogs memory a,
        uint8 index
    ) external returns (uint64);

    function writeCycle(
        IMemoryAccessLog.AccessLogs memory a,
        uint64 val
    ) external;

    function writePc(IMemoryAccessLog.AccessLogs memory a, uint64 val) external;

    function writeWord(
        IMemoryAccessLog.AccessLogs memory a,
        uint64 paddr,
        uint64 val
    ) external;

    function writeX(
        IMemoryAccessLog.AccessLogs memory a,
        uint8 index,
        uint64 val
    ) external;
}
