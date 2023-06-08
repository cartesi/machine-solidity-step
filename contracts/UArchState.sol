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

import "./interfaces/IAccessLogs.sol";
import "./interfaces/IUArchState.sol";
import "./AccessLogs.sol";
import "./UArchConstants.sol";

contract UArchState is IUArchState, UArchConstants {
    using AccessLogs for IAccessLogs.Context;

    function readCycle(
        IAccessLogs.Context memory a
    ) external pure override returns (uint64, IAccessLogs.Context memory) {
        uint64 cycle = a.readWord(UCYCLE);
        return (cycle, a);
    }

    function readHaltFlag(
        IAccessLogs.Context memory a
    ) external pure override returns (bool, IAccessLogs.Context memory) {
        bool halt = (a.readWord(UHALT) != 0);
        return (halt, a);
    }

    function readPc(
        IAccessLogs.Context memory a
    ) external pure override returns (uint64, IAccessLogs.Context memory) {
        uint64 pc = a.readWord(UPC);
        return (pc, a);
    }

    function readWord(
        IAccessLogs.Context memory a,
        uint64 paddr
    ) external pure override returns (uint64, IAccessLogs.Context memory) {
        uint64 word = a.readWord(paddr);
        return (word, a);
    }

    function readX(
        IAccessLogs.Context memory a,
        uint8 index
    ) external pure override returns (uint64, IAccessLogs.Context memory) {
        uint64 paddr;
        unchecked {
            paddr = UX0 + (index << 3);
        }
        uint64 x = a.readWord(paddr);
        return (x, a);
    }

    function writeCycle(
        IAccessLogs.Context memory a,
        uint64 val
    ) external pure override returns (IAccessLogs.Context memory) {
        a.writeWord(UCYCLE, val);
        return a;
    }

    function writePc(
        IAccessLogs.Context memory a,
        uint64 val
    ) external pure override returns (IAccessLogs.Context memory) {
        a.writeWord(UPC, val);
        return a;
    }

    function writeWord(
        IAccessLogs.Context memory a,
        uint64 paddr,
        uint64 val
    ) external pure override returns (IAccessLogs.Context memory) {
        a.writeWord(paddr, val);
        return a;
    }

    function writeX(
        IAccessLogs.Context memory a,
        uint8 index,
        uint64 val
    ) external pure override returns (IAccessLogs.Context memory) {
        uint64 paddr;
        unchecked {
            paddr = UX0 + (index << 3);
        }
        a.writeWord(paddr, val);
        return a;
    }
}
