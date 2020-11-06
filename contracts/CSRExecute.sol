// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./MemoryInteractor.sol";
import "./CSR.sol";

/// @title CSRExecute
/// @author Felipe Argento
/// @notice Implements CSR execute logic
library CSRExecute {
    uint256 constant CSRRS_CODE = 0;
    uint256 constant CSRRC_CODE = 1;

    uint256 constant CSRRSI_CODE = 0;
    uint256 constant CSRRCI_CODE = 1;

    /// @notice Implementation of CSRRS and CSRRC instructions
    /// @dev The specific instruction is decided by insncode, which defines the value to be written
    /// @param mi MemoryInteractor with which Step function is interacting
    /// @param insn Instruction
    /// @param insncode Specific instruction code
    /// @return true if instruction was executed successfuly and false if its an illegal insn exception
    function executeCsrSC(
        MemoryInteractor mi,
        uint32 insn,
        uint256 insncode
    )
    public returns (bool)
    {
        uint32 csrAddress = RiscVDecoder.insnIUimm(insn);

        bool status = false;
        uint64 csrval = 0;

        (status, csrval) = CSR.readCsr(mi, csrAddress);

        if (!status) {
            //return raiseIllegalInsnException(mi, insn);
            return false;
        }
        uint32 rs1 = RiscVDecoder.insnRs1(insn);
        uint64 rs1val = mi.readX(rs1);
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(rd, csrval);
        }

        uint64 execValue = 0;
        if (insncode == CSRRS_CODE) {
            execValue = executeCSRRS(csrval, rs1val);
        } else {
            // insncode == CSRRCCode
            execValue = executeCSRRC(csrval, rs1val);
        }
        if (rs1 != 0) {
            if (!CSR.writeCsr(
                mi,
                csrAddress,
                execValue
            )) {
                //return raiseIllegalInsnException(mi, insn);
                return false;
            }
        }
        //return advanceToNextInsn(mi, pc);
        return true;
    }

    /// @notice Implementation of CSRRSI and CSRRCI instructions
    /// @dev The specific instruction is decided by insncode, which defines the value to be written.
    /// @param mi MemoryInteractor with which Step function is interacting
    /// @param insn Instruction
    /// @param insncode Specific instruction code
    /// @return true if instruction was executed successfuly and false if its an illegal insn exception
    function executeCsrSCI(
        MemoryInteractor mi,
        uint32 insn,
        uint256 insncode)
    public returns (bool)
    {
        uint32 csrAddress = RiscVDecoder.insnIUimm(insn);

        bool status = false;
        uint64 csrval = 0;

        (status, csrval) = CSR.readCsr(mi, csrAddress);

        if (!status) {
            //return raiseIllegalInsnException(mi, insn);
            return false;
        }
        uint32 rs1 = RiscVDecoder.insnRs1(insn);
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(rd, csrval);
        }

        uint64 execValue = 0;
        if (insncode == CSRRSI_CODE) {
            execValue = executeCSRRSI(csrval, rs1);
        } else {
            // insncode == CSRRCICode
            execValue = executeCSRRCI(csrval, rs1);
        }

        if (rs1 != 0) {
            if (!CSR.writeCsr(
                mi,
                csrAddress,
                execValue
            )) {
                //return raiseIllegalInsnException(mi, insn);
                return false;
            }
        }
        //return advanceToNextInsn(mi, pc);
        return true;
    }

    /// @notice Implementation of CSRRW and CSRRWI instructions
    /// @dev The specific instruction is decided by insncode, which defines the value to be written.
    /// @param mi MemoryInteractor with which Step function is interacting
    /// @param insn Instruction
    /// @param insncode Specific instruction code
    /// @return true if instruction was executed successfuly and false if its an illegal insn exception
    function executeCsrRW(
        MemoryInteractor mi,
        uint32 insn,
        uint256 insncode
    )
    public returns (bool)
    {
        uint32 csrAddress = RiscVDecoder.insnIUimm(insn);

        bool status = true;
        uint64 csrval = 0;
        uint64 rs1val = 0;

        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            (status, csrval) = CSR.readCsr(mi, csrAddress);
        }

        if (!status) {
            //return raiseIllegalInsnException(mi, insn);
            return false;
        }

        if (insncode == 0) {
            rs1val = executeCSRRW(mi, insn);
        } else {
            // insncode == 1
            rs1val = executeCSRRWI(insn);
        }

        if (!CSR.writeCsr(
                mi,
                csrAddress,
                rs1val
        )) {
            //return raiseIllegalInsnException(mi, insn);
            return false;
        }
        if (rd != 0) {
            mi.writeX(rd, csrval);
        }
        //return advanceToNextInsn(mi, pc);
        return true;
    }

    //internal functions
    function executeCSRRW(MemoryInteractor mi, uint32 insn)
    internal returns(uint64)
    {
        return mi.readX(RiscVDecoder.insnRs1(insn));
    }

    function executeCSRRWI(uint32 insn) internal pure returns(uint64) {
        return uint64(RiscVDecoder.insnRs1(insn));
    }

    function executeCSRRS(uint64 csr, uint64 rs1) internal pure returns(uint64) {
        return csr | rs1;
    }

    function executeCSRRC(uint64 csr, uint64 rs1) internal pure returns(uint64) {
        return csr & ~rs1;
    }

    function executeCSRRSI(uint64 csr, uint32 rs1) internal pure returns(uint64) {
        return csr | rs1;
    }

    function executeCSRRCI(uint64 csr, uint32 rs1) internal pure returns(uint64) {
        return csr & ~rs1;
    }
}

