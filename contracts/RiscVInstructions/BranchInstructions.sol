// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title BranchInstructions
pragma solidity ^0.7.0;

import "../MemoryInteractor.sol";
import "../RiscVDecoder.sol";


library BranchInstructions {

    function getRs1Rs2(MemoryInteractor mi, uint32 insn) internal
    returns(uint64 rs1, uint64 rs2)
    {
        rs1 = mi.readX(RiscVDecoder.insnRs1(insn));
        rs2 = mi.readX(RiscVDecoder.insnRs2(insn));
    }

    function executeBEQ(MemoryInteractor mi, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        return rs1 == rs2;
    }

    function executeBNE(MemoryInteractor mi, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        return rs1 != rs2;
    }

    function executeBLT(MemoryInteractor mi, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        return int64(rs1) < int64(rs2);
    }

    function executeBGE(MemoryInteractor mi, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        return int64(rs1) >= int64(rs2);
    }

    function executeBLTU(MemoryInteractor mi, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        return rs1 < rs2;
    }

    function executeBGEU(MemoryInteractor mi, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, insn);
        return rs1 >= rs2;
    }

    /// @notice Given a branch funct3 group instruction, finds the function
    //  associated with it. Uses binary search for performance.
    //  @param insn for branch funct3 field.
    function branchFunct3(MemoryInteractor mi, uint32 insn)
    public returns (bool, bool)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);

        if (funct3 < 0x0005) {
            if (funct3 == 0x0000) {
                /*funct3 == 0x0000*/
                return (executeBEQ(mi, insn), true);
            } else if (funct3 == 0x0004) {
                /*funct3 == 0x0004*/
                return (executeBLT(mi, insn), true);
            } else if (funct3 == 0x0001) {
                /*funct3 == 0x0001*/
                return (executeBNE(mi, insn), true);
            }
        } else if (funct3 > 0x0005) {
            if (funct3 == 0x0007) {
                /*funct3 == 0x0007*/
                return (executeBGEU(mi, insn), true);
            } else if (funct3 == 0x0006) {
                /*funct3 == 0x0006*/
                return (executeBLTU(mi, insn), true);
            }
        } else if (funct3 == 0x0005) {
            /*funct3==0x0005*/
            return (executeBGE(mi, insn), true);
        }
        return (false, false);
    }
}
