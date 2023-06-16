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

import "./AccessLogs.sol";
import "./Memory.sol";
import "./UArchConstants.sol";

library UArchState {
    using AccessLogs for AccessLogs.Context;
    using Memory for uint64;

    function readCycle(
        AccessLogs.Context memory a
    ) internal pure returns (uint64) {
        return a.readWord(UArchConstants.UCYCLE.toPhysicalAddress());
    }

    function readHaltFlag(
        AccessLogs.Context memory a
    ) internal pure returns (bool) {
        return (a.readWord(UArchConstants.UHALT.toPhysicalAddress()) != 0);
    }

    function readPc(
        AccessLogs.Context memory a
    ) internal pure returns (uint64) {
        return a.readWord(UArchConstants.UPC.toPhysicalAddress());
    }

    function readWord(
        AccessLogs.Context memory a,
        uint64 paddr
    ) internal pure returns (uint64) {
        return a.readWord(paddr.toPhysicalAddress());
    }

    function readX(
        AccessLogs.Context memory a,
        uint8 index
    ) internal pure returns (uint64) {
        uint64 paddr;
        unchecked {
            paddr = UArchConstants.UX0 + (index << 3);
        }
        return a.readWord(paddr.toPhysicalAddress());
    }

    function writeCycle(AccessLogs.Context memory a, uint64 val) internal pure {
        a.writeWord(UArchConstants.UCYCLE.toPhysicalAddress(), val);
    }

    function writePc(AccessLogs.Context memory a, uint64 val) internal pure {
        a.writeWord(UArchConstants.UPC.toPhysicalAddress(), val);
    }

    function writeWord(
        AccessLogs.Context memory a,
        uint64 paddr,
        uint64 val
    ) internal pure {
        a.writeWord(paddr.toPhysicalAddress(), val);
    }

    function writeX(
        AccessLogs.Context memory a,
        uint8 index,
        uint64 val
    ) internal pure {
        uint64 paddr;
        unchecked {
            paddr = UArchConstants.UX0 + (index << 3);
        }
        a.writeWord(paddr.toPhysicalAddress(), val);
    }
}
