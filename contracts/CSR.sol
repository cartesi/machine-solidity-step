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
import "./RiscVConstants.sol";
import "./CSRReads.sol";

/// @title CSR
/// @author Felipe Argento
/// @notice Implements main CSR read and write logic
library CSR {

    //CSR addresses
    uint32 constant UCYCLE = 0xc00;
    uint32 constant UTIME = 0xc01;
    uint32 constant UINSTRET =  0xc02;

    uint32 constant SSTATUS = 0x100;
    uint32 constant SIE = 0x104;
    uint32 constant STVEC = 0x105;
    uint32 constant SCOUNTEREN = 0x106;

    uint32 constant SSCRATCH = 0x140;
    uint32 constant SEPC = 0x141;
    uint32 constant SCAUSE = 0x142;
    uint32 constant STVAL = 0x143;
    uint32 constant SIP = 0x144;

    uint32 constant SATP = 0x180;

    uint32 constant MVENDORID = 0xf11;
    uint32 constant MARCHID = 0xf12;
    uint32 constant MIMPID = 0xf13;
    uint32 constant MHARTID = 0xf14;

    uint32 constant MSTATUS = 0x300;
    uint32 constant MISA = 0x301;
    uint32 constant MEDELEG = 0x302;
    uint32 constant MIDELEG = 0x303;
    uint32 constant MIE = 0x304;
    uint32 constant MTVEC = 0x305;
    uint32 constant MCOUNTEREN = 0x306;

    uint32 constant MSCRATCH = 0x340;
    uint32 constant MEPC = 0x341;
    uint32 constant MCAUSE = 0x342;
    uint32 constant MTVAL = 0x343;
    uint32 constant MIP = 0x344;

    uint32 constant MCYCLE = 0xb00;
    uint32 constant MINSTRET = 0xb02;

    uint32 constant TSELECT = 0x7a0;
    uint32 constant TDATA1 = 0x7a1;
    uint32 constant TDATA2 = 0x7a2;
    uint32 constant TDATA3 = 0x7a3;

    /// @notice Reads the value of a CSR given its address
    /// @dev If/else should change to binary search to increase performance
    /// @param mi MemoryInteractor with which Step function is interacting.
    /// @param csrAddr Address of CSR in file.
    /// @return Returns the status of the operation (true for success, false otherwise).
    /// @return Register value.
    function readCsr(MemoryInteractor mi, uint32 csrAddr)
    public returns (bool, uint64)
    {
        // Attemps to access a CSR without appropriate privilege level raises a
        // illegal instruction exception.
        // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
        if (csrPriv(csrAddr) > mi.readIflagsPrv()) {
            return(false, 0);
        }
        if (csrAddr == UCYCLE) {
            return CSRReads.readCsrCycle(mi, csrAddr);
        } else if (csrAddr == UINSTRET) {
            return CSRReads.readCsrInstret(mi, csrAddr);
        } else if (csrAddr == UTIME) {
            return CSRReads.readCsrTime(mi, csrAddr);
        } else if (csrAddr == SSTATUS) {
            return CSRReads.readCsrSstatus(mi);
        } else if (csrAddr == SIE) {
            return CSRReads.readCsrSie(mi);
        } else if (csrAddr == STVEC) {
            return CSRReads.readCsrStvec(mi);
        } else if (csrAddr == SCOUNTEREN) {
            return CSRReads.readCsrScounteren(mi);
        } else if (csrAddr == SSCRATCH) {
            return CSRReads.readCsrSscratch(mi);
        } else if (csrAddr == SEPC) {
            return CSRReads.readCsrSepc(mi);
        } else if (csrAddr == SCAUSE) {
            return CSRReads.readCsrScause(mi);
        } else if (csrAddr == STVAL) {
            return CSRReads.readCsrStval(mi);
        } else if (csrAddr == SIP) {
            return CSRReads.readCsrSip(mi);
        } else if (csrAddr == SATP) {
            return CSRReads.readCsrSatp(mi);
        } else if (csrAddr == MSTATUS) {
            return CSRReads.readCsrMstatus(mi);
        } else if (csrAddr == MISA) {
            return CSRReads.readCsrMisa(mi);
        } else if (csrAddr == MEDELEG) {
            return CSRReads.readCsrMedeleg(mi);
        } else if (csrAddr == MIDELEG) {
            return CSRReads.readCsrMideleg(mi);
        } else if (csrAddr == MIE) {
            return CSRReads.readCsrMie(mi);
        } else if (csrAddr == MTVEC) {
            return CSRReads.readCsrMtvec(mi);
        } else if (csrAddr == MCOUNTEREN) {
            return CSRReads.readCsrMcounteren(mi);
        } else if (csrAddr == MSCRATCH) {
            return CSRReads.readCsrMscratch(mi);
        } else if (csrAddr == MEPC) {
            return CSRReads.readCsrMepc(mi);
        } else if (csrAddr == MCAUSE) {
            return CSRReads.readCsrMcause(mi);
        } else if (csrAddr == MTVAL) {
            return CSRReads.readCsrMtval(mi);
        } else if (csrAddr == MIP) {
            return CSRReads.readCsrMip(mi);
        } else if (csrAddr == MCYCLE) {
            return CSRReads.readCsrMcycle(mi);
        } else if (csrAddr == MINSTRET) {
            return CSRReads.readCsrMinstret(mi);
        } else if (csrAddr == MVENDORID) {
            return CSRReads.readCsrMvendorid(mi);
        } else if (csrAddr == MARCHID) {
            return CSRReads.readCsrMarchid(mi);
        } else if (csrAddr == MIMPID) {
            return CSRReads.readCsrMimpid(mi);
        } else if (csrAddr == TSELECT || csrAddr == TDATA1 || csrAddr == TDATA2 || csrAddr == TDATA3 || csrAddr == MHARTID) {
            //All hardwired to zero
            return (true, 0);
        }

        return CSRReads.readCsrFail();
    }

    /// @notice Writes a value to a CSR given its address
    /// @dev If/else should change to binary search to increase performance
    /// @param mi MemoryInteractor with which Step function is interacting.
    /// @param csrAddr Address of CSR in file.
    /// @param val Value to be written;
    /// @return The status of the operation (true for success, false otherwise).
    function writeCsr(
        MemoryInteractor mi,
        uint32 csrAddr,
        uint64 val
    )
    public returns (bool)
    {
        // Attemps to access a CSR without appropriate privilege level raises a
        // illegal instruction exception.
        // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
        if (csrPriv(csrAddr) > mi.readIflagsPrv()) {
            return false;
        }

        if (csrIsReadOnly(csrAddr)) {
            return false;
        }

        if (csrAddr == SSTATUS) {
            uint64 cMstatus = mi.readMstatus();
            return writeCsrMstatus(mi, (cMstatus & ~RiscVConstants.getSstatusWMask()) | (val & RiscVConstants.getSstatusWMask()));

        } else if (csrAddr == SIE) {
            uint64 mask = mi.readMideleg();
            uint64 cMie = mi.readMie();

            mi.writeMie((cMie & ~mask) | (val & mask));
            return true;
        } else if (csrAddr == STVEC) {
            mi.writeStvec(val & uint64(~3));
            return true;
        } else if (csrAddr == SCOUNTEREN) {
            mi.writeScounteren(val & RiscVConstants.getScounterenRwMask());
            return true;
        } else if (csrAddr == SSCRATCH) {
            mi.writeSscratch(val);
            return true;
        } else if (csrAddr == SEPC) {
            mi.writeSepc(val & uint64(~3));
            return true;
        } else if (csrAddr == SCAUSE) {
            mi.writeScause(val);
            return true;
        } else if (csrAddr == STVAL) {
            mi.writeStval(val);
            return true;
        } else if (csrAddr == SIP) {
            uint64 cMask = mi.readMideleg();
            uint64 cMip = mi.readMip();

            cMip = (cMip & ~cMask) | (val & cMask);
            mi.writeMip(cMip);
            return true;
        } else if (csrAddr == SATP) {
            uint64 cSatp = mi.readSatp();
            int mode = cSatp >> 60;
            int newMode = (val >> 60) & 0xf;

            if (newMode == 0 || (newMode >= 8 && newMode <= 9)) {
                mode = newMode;
            }
            mi.writeSatp((val & ((uint64(1) << 44) - 1) | uint64(mode) << 60));
            return true;

        } else if (csrAddr == MSTATUS) {
            return writeCsrMstatus(mi, val);
        } else if (csrAddr == MEDELEG) {
            uint64 mask = ((uint64(1) << (RiscVConstants.getMcauseStoreAmoPageFault() + 1)) - 1);
            mi.writeMedeleg((mi.readMedeleg() & ~mask) | (val & mask));
            return true;
        } else if (csrAddr == MIDELEG) {
            uint64 mask = RiscVConstants.getMipSsipMask() | RiscVConstants.getMipStipMask() | RiscVConstants.getMipSeipMask();
            mi.writeMideleg(((mi.readMideleg() & ~mask) | (val & mask)));
            return true;
        } else if (csrAddr == MIE) {
            uint64 mask = RiscVConstants.getMipMsipMask() | RiscVConstants.getMipMtipMask() | RiscVConstants.getMipSsipMask() | RiscVConstants.getMipStipMask() | RiscVConstants.getMipSeipMask();

            mi.writeMie(((mi.readMie() & ~mask) | (val & mask)));
            return true;
        } else if (csrAddr == MTVEC) {
            mi.writeMtvec(val & uint64(~3));
            return true;
        } else if (csrAddr == MCOUNTEREN) {
            mi.writeMcounteren(val & RiscVConstants.getMcounterenRwMask());
            return true;
        } else if (csrAddr == MSCRATCH) {
            mi.writeMscratch(val);
            return true;
        } else if (csrAddr == MEPC) {
            mi.writeMepc(val & uint64(~3));
            return true;
        } else if (csrAddr == MCAUSE) {
            mi.writeMcause(val);
            return true;
        } else if (csrAddr == MTVAL) {
            mi.writeMtval(val);
            return true;
        } else if (csrAddr == MIP) {
            uint64 mask = RiscVConstants.getMipSsipMask() | RiscVConstants.getMipStipMask();
            uint64 cMip = mi.readMip();

            cMip = (cMip & ~mask) | (val & mask);

            mi.writeMip(cMip);
            return true;
        } else if (csrAddr == MCYCLE) {
            // We can't allow writes to mcycle because we use it to measure the progress in machine execution.
            // BBL enables all counters in both M- and S-modes
            // We instead raise an exception.
            return false;
        } else if (csrAddr == MINSTRET) {
            // In Spike, QEMU, and riscvemu, mcycle and minstret are the aliases for the same counter
            // QEMU calls exit (!) on writes to mcycle or minstret
            mi.writeMinstret(val-1); // The value will be incremented after the instruction is executed
            return true;
        } else if (csrAddr == TSELECT || csrAddr == TDATA1 || csrAddr == TDATA2 || csrAddr == TDATA3 || csrAddr == MISA) {
            // Ignore writes
            return (true);
        }
        return false;
    }

    // Extract privilege level from CSR
    // Bits csr[9:8] encode the CSR's privilege level (i.e lowest privilege level
    // that can access that CSR.
    // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
    function csrPriv(uint32 csrAddr) internal pure returns(uint32) {
        return (csrAddr >> 8) & 3;
    }

    // The standard RISC-V ISA sets aside a 12-bit encoding space (csr[11:0])
    // The top two bits (csr[11:10]) indicate whether the register is
    // read/write (00, 01, or 10) or read-only (11)
    // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
    function csrIsReadOnly(uint32 csrAddr) internal pure returns(bool) {
        return ((csrAddr & 0xc00) == 0xc00);
    }

    function writeCsrMstatus(MemoryInteractor mi, uint64 val)
    internal returns(bool)
    {
        uint64 cMstatus = mi.readMstatus() & RiscVConstants.getMstatusRMask();
        // Modifiy  only bits that can be written to
        cMstatus = (cMstatus & ~RiscVConstants.getMstatusWMask()) | (val & RiscVConstants.getMstatusWMask());
        //Update the SD bit
        if ((cMstatus & RiscVConstants.getMstatusFsMask()) == RiscVConstants.getMstatusFsMask()) {
            cMstatus |= RiscVConstants.getMstatusSdMask();
        }
        mi.writeMstatus(cMstatus);
        return true;
    }

}

