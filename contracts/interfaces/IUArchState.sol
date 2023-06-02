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

pragma solidity >=0.8.0;

import "./IMemoryAccessLog.sol";

interface IUArchState {
    struct State {
        IUArchState stateInterface;
        IMemoryAccessLog.AccessLogs accessLogs;
        bytes32 machineHash;
        bytes32[] oldHashes;
        bytes32[][] proofs;
        uint256 writeCurrent;
    }

    function readCycle(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[][] memory proofs
    ) external returns (uint64);

    function readHaltFlag(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[][] memory proofs
    ) external returns (bool);

    function readPc(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[][] memory proofs
    ) external returns (uint64);

    function readWord(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[][] memory proofs,
        uint64 paddr
    ) external returns (uint64);

    function readX(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[][] memory proofs,
        uint8 index
    ) external returns (uint64);

    function writeCycle(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[] memory oldHashes,
        bytes32[][] memory proofs,
        uint256 writeCurrent,
        uint64 val
    ) external returns (bytes32);

    function writePc(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[] memory oldHashes,
        bytes32[][] memory proofs,
        uint256 writeCurrent,
        uint64 val
    ) external returns (bytes32);

    function writeWord(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[] memory oldHashes,
        bytes32[][] memory proofs,
        uint256 writeCurrent,
        uint64 paddr,
        uint64 val
    ) external returns (bytes32);

    function writeX(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[] memory oldHashes,
        bytes32[][] memory proofs,
        uint256 writeCurrent,
        uint8 index,
        uint64 val
    ) external returns (bytes32);
}
