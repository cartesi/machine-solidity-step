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

import "../AccessLogs.sol";

interface IUArchState {
    struct State {
        IUArchState stateInterface;
        AccessLogs.Context accessLogs;
    }

    function readCycle(
        AccessLogs.Context memory a
    ) external returns (uint64, AccessLogs.Context memory);

    function readHaltFlag(
        AccessLogs.Context memory a
    ) external returns (bool, AccessLogs.Context memory);

    function readPc(
        AccessLogs.Context memory a
    ) external returns (uint64, AccessLogs.Context memory);

    function readWord(
        AccessLogs.Context memory a,
        uint64 paddr
    ) external returns (uint64, AccessLogs.Context memory);

    function readX(
        AccessLogs.Context memory a,
        uint8 index
    ) external returns (uint64, AccessLogs.Context memory);

    function writeCycle(
        AccessLogs.Context memory a,
        uint64 val
    ) external returns (AccessLogs.Context memory);

    function writePc(
        AccessLogs.Context memory a,
        uint64 val
    ) external returns (AccessLogs.Context memory);

    function writeWord(
        AccessLogs.Context memory a,
        uint64 paddr,
        uint64 val
    ) external returns (AccessLogs.Context memory);

    function writeX(
        AccessLogs.Context memory a,
        uint8 index,
        uint64 val
    ) external returns (AccessLogs.Context memory);
}
