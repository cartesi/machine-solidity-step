// Copyright 2023 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title IMemoryAccessLog

pragma solidity >=0.8.0;

interface IMemoryAccessLog {
    struct Access {
        uint64 position;
        bytes8 val;
    }

    struct AccessLogs {
        Access[] logs;
        uint256 current;
    }

    function readWord(
        AccessLogs memory a,
        uint64 readAddress
    ) external returns (uint64);

    function writeWord(
        AccessLogs memory a,
        uint64 writeAddress,
        uint64 val
    ) external;
}
