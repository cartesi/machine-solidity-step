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

import "./interfaces/IMemoryAccessLog.sol";
import "./interfaces/IUArchState.sol";
import "./MemoryAccessLog.sol";
import "./UArchConstants.sol";

contract UArchState is IUArchState, UArchConstants {
    using MemoryAccessLog for IMemoryAccessLog.AccessLogs;

    function readWord(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[][] memory proofs,
        uint64 paddr
    ) external pure override returns (uint64) {
        return a.readWord(machineHash, proofs, paddr);
    }

    function readHaltFlag(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[][] memory proofs
    ) external pure override returns (bool) {
        return (a.readWord(machineHash, proofs, UHALT) != 0);
    }

    function readPc(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[][] memory proofs
    ) external pure override returns (uint64) {
        return a.readWord(machineHash, proofs, UPC);
    }

    function readCycle(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[][] memory proofs
    ) external pure override returns (uint64) {
        return a.readWord(machineHash, proofs, UCYCLE);
    }

    function writeCycle(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[] memory oldHashes,
        bytes32[][] memory proofs,
        uint256 writeCurrent,
        uint64 val
    ) external pure override returns (bytes32) {
        return
            a.writeWord(
                machineHash,
                oldHashes,
                proofs,
                writeCurrent,
                UCYCLE,
                val
            );
    }

    function readX(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[][] memory proofs,
        uint8 index
    ) external pure override returns (uint64) {
        uint64 paddr;
        unchecked {
            paddr = UX0 + (index << 3);
        }
        return a.readWord(machineHash, proofs, paddr);
    }

    function writeWord(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[] memory oldHashes,
        bytes32[][] memory proofs,
        uint256 writeCurrent,
        uint64 paddr,
        uint64 val
    ) external pure override returns (bytes32) {
        return
            a.writeWord(
                machineHash,
                oldHashes,
                proofs,
                writeCurrent,
                paddr,
                val
            );
    }

    function writeX(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[] memory oldHashes,
        bytes32[][] memory proofs,
        uint256 writeCurrent,
        uint8 index,
        uint64 val
    ) external pure override returns (bytes32) {
        uint64 paddr;
        unchecked {
            paddr = UX0 + (index << 3);
        }
        return
            a.writeWord(
                machineHash,
                oldHashes,
                proofs,
                writeCurrent,
                paddr,
                val
            );
    }

    function writePc(
        IMemoryAccessLog.AccessLogs memory a,
        bytes32 machineHash,
        bytes32[] memory oldHashes,
        bytes32[][] memory proofs,
        uint256 writeCurrent,
        uint64 val
    ) external pure override returns (bytes32) {
        return
            a.writeWord(machineHash, oldHashes, proofs, writeCurrent, UPC, val);
    }
}
