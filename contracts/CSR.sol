// @title CSR
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/RiscVConstants.sol";
import "../contracts/CSRReads.sol";


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

    function readCsr(MemoryInteractor mi, uint256 mmIndex, uint32 csrAddr)
    public returns (bool, uint64)
    {
        // Attemps to access a CSR without appropriate privilege level raises a
        // illegal instruction exception.
        // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
        if (csrPriv(csrAddr) > mi.readIflagsPrv(mmIndex)) {
            return(false, 0);
        }
        // TO-DO: Change this to binary search or mapping to increase performance
        // (in the meantime, pray for solidity devs to add switch statements)
        if (csrAddr == UCYCLE) {
            return CSRReads.readCsrCycle(mi, mmIndex, csrAddr);
        } else if (csrAddr == UINSTRET) {
            return CSRReads.readCsrInstret(mi, mmIndex, csrAddr);
        } else if (csrAddr == UTIME) {
            return CSRReads.readCsrTime(mi, mmIndex, csrAddr);
        } else if (csrAddr == SSTATUS) {
            return CSRReads.readCsrSstatus(mi, mmIndex);
        } else if (csrAddr == SIE) {
            return CSRReads.readCsrSie(mi, mmIndex);
        } else if (csrAddr == STVEC) {
            return CSRReads.readCsrStvec(mi, mmIndex);
        } else if (csrAddr == SCOUNTEREN) {
            return CSRReads.readCsrScounteren(mi, mmIndex);
        } else if (csrAddr == SSCRATCH) {
            return CSRReads.readCsrSscratch(mi, mmIndex);
        } else if (csrAddr == SEPC) {
            return CSRReads.readCsrSepc(mi, mmIndex);
        } else if (csrAddr == SCAUSE) {
            return CSRReads.readCsrScause(mi, mmIndex);
        } else if (csrAddr == STVAL) {
            return CSRReads.readCsrStval(mi, mmIndex);
        } else if (csrAddr == SIP) {
            return CSRReads.readCsrSip(mi, mmIndex);
        } else if (csrAddr == SATP) {
            return CSRReads.readCsrSatp(mi, mmIndex);
        } else if (csrAddr == MSTATUS) {
            return CSRReads.readCsrMstatus(mi, mmIndex);
        } else if (csrAddr == MISA) {
            return CSRReads.readCsrMisa(mi, mmIndex);
        } else if (csrAddr == MEDELEG) {
            return CSRReads.readCsrMedeleg(mi, mmIndex);
        } else if (csrAddr == MIDELEG) {
            return CSRReads.readCsrMideleg(mi, mmIndex);
        } else if (csrAddr == MIE) {
            return CSRReads.readCsrMie(mi, mmIndex);
        } else if (csrAddr == MTVEC) {
            return CSRReads.readCsrMtvec(mi, mmIndex);
        } else if (csrAddr == MCOUNTEREN) {
            return CSRReads.readCsrMcounteren(mi, mmIndex);
        } else if (csrAddr == MSCRATCH) {
            return CSRReads.readCsrMscratch(mi, mmIndex);
        } else if (csrAddr == MEPC) {
            return CSRReads.readCsrMepc(mi, mmIndex);
        } else if (csrAddr == MCAUSE) {
            return CSRReads.readCsrMcause(mi, mmIndex);
        } else if (csrAddr == MTVAL) {
            return CSRReads.readCsrMtval(mi, mmIndex);
        } else if (csrAddr == MIP) {
            return CSRReads.readCsrMip(mi, mmIndex);
        } else if (csrAddr == MCYCLE) {
            return CSRReads.readCsrMcycle(mi, mmIndex);
        } else if (csrAddr == MINSTRET) {
            return CSRReads.readCsrMinstret(mi, mmIndex);
        } else if (csrAddr == MVENDORID) {
            return CSRReads.readCsrMvendorid(mi, mmIndex);
        } else if (csrAddr == MARCHID) {
            return CSRReads.readCsrMarchid(mi, mmIndex);
        } else if (csrAddr == MIMPID) {
            return CSRReads.readCsrMimpid(mi, mmIndex);
        } else if (csrAddr == TSELECT || csrAddr == TDATA1 || csrAddr == TDATA2 || csrAddr == TDATA3 || csrAddr == MHARTID) {
            //All hardwired to zero
            return (true, 0);
        }

        return CSRReads.readCsrFail();
    }

    function writeCsr(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 csrAddr,
        uint64 val
    )
    public returns (bool)
    {
        // Attemps to access a CSR without appropriate privilege level raises a
        // illegal instruction exception.
        // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
        if (csrPriv(csrAddr) > mi.readIflagsPrv(mmIndex)) {
            return false;
        }

        if (csrIsReadOnly(csrAddr)) {
            return false;
        }

        // TO-DO: Change this to binary search or mapping to increase performance
        // (in the meantime, pray for solidity devs to add switch statements)
        if (csrAddr == SSTATUS) {
            //return CSRWrites.writeCsrSstatus(mi, mmIndex, val);
            uint64 cMstatus = mi.readMstatus(mmIndex);
            return writeCsrMstatus(mi, mmIndex, (cMstatus & ~RiscVConstants.getSstatusWMask()) | (val & RiscVConstants.getSstatusWMask()));

        } else if (csrAddr == SIE) {
            //return CSRWrites.writeCsrSie(mi, mmIndex, val);
            uint64 mask = mi.readMideleg(mmIndex);
            uint64 cMie = mi.readMie(mmIndex);

            mi.writeMie(mmIndex, (cMie & ~mask) | (val & mask));
            return true;
        } else if (csrAddr == STVEC) {
            //return CSRWrites.writeCsrStvec(mi, mmIndex, val);
            mi.writeStvec(mmIndex, val & uint64(~3));
            return true;
        } else if (csrAddr == SCOUNTEREN) {
            //return CSRWrites.writeCsrScounteren(mi, mmIndex, val);
            mi.writeScounteren(mmIndex, val & RiscVConstants.getScounterenRwMask());
            return true;
        } else if (csrAddr == SSCRATCH) {
            //return CSRWrites.writeCsrSscratch(mi, mmIndex, val);
            mi.writeSscratch(mmIndex, val);
            return true;
        } else if (csrAddr == SEPC) {
            //return CSRWrites.writeCsrSepc(mi, mmIndex, val);
            mi.writeSepc(mmIndex, val & uint64(~3));
            return true;
        } else if (csrAddr == SCAUSE) {
            //return CSRWrites.writeCsrScause(mi, mmIndex, val);
            mi.writeScause(mmIndex, val);
            return true;
        } else if (csrAddr == STVAL) {
            //return CSRWrites.writeCsrStval(mi, mmIndex, val);
            mi.writeStval(mmIndex, val);
            return true;
        } else if (csrAddr == SIP) {
            //return CSRWrites.writeCsrSip(mi, mmIndex, val);
            uint64 cMask = mi.readMideleg(mmIndex);
            uint64 cMip = mi.readMip(mmIndex);

            cMip = (cMip & ~cMask) | (val & cMask);
            mi.writeMip(mmIndex, cMip);
            return true;
        } else if (csrAddr == SATP) {
            //return CSRWrites.writeCsrSatp(mi, mmIndex, val);
            uint64 cSatp = mi.readSatp(mmIndex);
            int mode = cSatp >> 60;
            int newMode = (val >> 60) & 0xf;

            if (newMode == 0 || (newMode >= 8 && newMode <= 9)) {
                mode = newMode;
            }
            mi.writeSatp(mmIndex, (val & ((uint64(1) << 44) - 1) | uint64(mode) << 60));
            return true;

        } else if (csrAddr == MSTATUS) {
            return writeCsrMstatus(mi, mmIndex, val);
        } else if (csrAddr == MEDELEG) {
            //return CSRWrites.writeCsrMedeleg(mi, mmIndex, val);
            uint64 mask = ((uint64(1) << (RiscVConstants.getMcauseStoreAmoPageFault() + 1)) - 1);
            mi.writeMedeleg(mmIndex, (mi.readMedeleg(mmIndex) & ~mask) | (val & mask));
            return true;
        } else if (csrAddr == MIDELEG) {
            //return CSRWrites.writeCsrMideleg(mi, mmIndex, val);
            uint64 mask = RiscVConstants.getMipSsipMask() | RiscVConstants.getMipStipMask() | RiscVConstants.getMipSeipMask();
            mi.writeMideleg(mmIndex, ((mi.readMideleg(mmIndex) & ~mask) | (val & mask)));
            return true;
        } else if (csrAddr == MIE) {
            //return CSRWrites.writeCsrMie(mi, mmIndex, val);
            uint64 mask = RiscVConstants.getMipMsipMask() | RiscVConstants.getMipMtipMask() | RiscVConstants.getMipSsipMask() | RiscVConstants.getMipStipMask() | RiscVConstants.getMipSeipMask();

            mi.writeMie(mmIndex, ((mi.readMie(mmIndex) & ~mask) | (val & mask)));
            return true;
        } else if (csrAddr == MTVEC) {
            //return CSRWrites.writeCsrMtvec(mi, mmIndex, val);
            mi.writeMtvec(mmIndex, val & uint64(~3));
            return true;
        } else if (csrAddr == MCOUNTEREN) {
            //return CSRWrites.writeCsrMcounteren(mi, mmIndex, val);
            mi.writeMcounteren(mmIndex, val & RiscVConstants.getMcounterenRwMask());
            return true;
        } else if (csrAddr == MSCRATCH) {
            //return CSRWrites.writeCsrMscratch(mi, mmIndex, val);
            mi.writeMscratch(mmIndex, val);
            return true;
        } else if (csrAddr == MEPC) {
            //return CSRWrites.writeCsrMepc(mi, mmIndex, val);
            mi.writeMepc(mmIndex, val & uint64(~3));
            return true;
        } else if (csrAddr == MCAUSE) {
            //return CSRWrites.writeCsrMcause(mi, mmIndex, val);
            mi.writeMcause(mmIndex, val);
            return true;
        } else if (csrAddr == MTVAL) {
            //return CSRWrites.writeCsrMtval(mi, mmIndex, val);
            mi.writeMtval(mmIndex, val);
            return true;
        } else if (csrAddr == MIP) {
            //return CSRWrites.writeCsrMip(mi, mmIndex, val);
            uint64 mask = RiscVConstants.getMipSsipMask() | RiscVConstants.getMipStipMask();
            uint64 cMip = mi.readMip(mmIndex);

            cMip = (cMip & ~mask) | (val & mask);

            mi.writeMip(mmIndex, cMip);
            return true;
        } else if (csrAddr == MCYCLE) {
            // We can't allow writes to mcycle because we use it to measure the progress in machine execution.
            // BBL enables all counters in both M- and S-modes
            // We instead raise an exception.
            return false;
        } else if (csrAddr == MINSTRET) {
            //return CSRWrites.writeCsrMinstret(mi, mmIndex, val);
            // In Spike, QEMU, and riscvemu, mcycle and minstret are the aliases for the same counter
            // QEMU calls exit (!) on writes to mcycle or minstret
            mi.writeMinstret(mmIndex, val-1); // The value will be incremented after the instruction is executed
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

    function csrPriv(uint32 csrAddr) internal returns(uint32) {
        return (csrAddr >> 8) & 3;
    }

    // The standard RISC-V ISA sets aside a 12-bit encoding space (csr[11:0])
    // The top two bits (csr[11:10]) indicate whether the register is
    // read/write (00, 01, or 10) or read-only (11)
    // Reference: riscv-privileged-v1.10 - section 2.1 - page 7.
    function csrIsReadOnly(uint32 csrAddr) internal returns(bool) {
        return ((csrAddr & 0xc00) == 0xc00);
    }

    function writeCsrMstatus(MemoryInteractor mi, uint256 mmIndex, uint64 val)
    internal returns(bool)
    {
        uint64 cMstatus = mi.readMstatus(mmIndex) & RiscVConstants.getMstatusRMask();
        // Modifiy  only bits that can be written to
        cMstatus = (cMstatus & ~RiscVConstants.getMstatusWMask()) | (val & RiscVConstants.getMstatusWMask());
        //Update the SD bit
        if ((cMstatus & RiscVConstants.getMstatusFsMask()) == RiscVConstants.getMstatusFsMask()) {
            cMstatus |= RiscVConstants.getMstatusSdMask();
        }
        mi.writeMstatus(mmIndex, cMstatus);
        return true;
    }

}

