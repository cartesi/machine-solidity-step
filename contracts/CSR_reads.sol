// @title CSR_reads
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/RiscVConstants.sol";
import "../contracts/RiscVDecoder.sol";
import "../contracts/RealTimeClock.sol";


library CSRReads {
    // csr reads
    function readCsrCycle(MemoryInteractor mi, uint256 mmIndex, uint32 csrAddr)
    internal returns(bool, uint64)
    {
        if (rdcounteren(mi, mmIndex, csrAddr)) {
            return (true, mi.readMcycle(mmIndex));
        } else {
            return (false, 0);
        }
    }

    function readCsrInstret(MemoryInteractor mi, uint256 mmIndex, uint32 csrAddr)
    internal returns(bool, uint64)
    {
        if (rdcounteren(mi, mmIndex, csrAddr)) {
            return (true, mi.readMinstret(mmIndex));
        } else {
            return (false, 0);
        }
    }

    function readCsrTime(MemoryInteractor mi, uint256 mmIndex, uint32 csrAddr)
    internal returns(bool, uint64)
    {
        if (rdcounteren(mi, mmIndex, csrAddr)) {
            uint64 mtime = RealTimeClock.rtcCycleToTime(mi.readMcycle(mmIndex));
            return (true, mtime);
        } else {
            return (false, 0);
        }
    }

    function readCsrSstatus(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMstatus(mmIndex) & RiscVConstants.SSTATUS_R_MASK());
    }

    function readCsrSie(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        uint64 mie = mi.readMie(mmIndex);
        uint64 mideleg = mi.readMideleg(mmIndex);

        return (true, mie & mideleg);
    }

    function readCsrStvec(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readStvec(mmIndex));
    }

    function readCsrScounteren(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readScounteren(mmIndex));
    }

    function readCsrSscratch(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readSscratch(mmIndex));
    }

    function readCsrSepc(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readSepc(mmIndex));
    }

    function readCsrScause(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readScause(mmIndex));
    }

    function readCsrStval(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readStval(mmIndex));
    }

    function readCsrSip(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        uint64 mip = mi.readMip(mmIndex);
        uint64 mideleg = mi.readMideleg(mmIndex);
        return (true, mip & mideleg);
    }

    function readCsrSatp(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        uint64 mstatus = mi.readMstatus(mmIndex);
        uint64 priv = mi.readIflags_PRV(mmIndex);

        if (priv == RiscVConstants.PRV_S() && (mstatus & RiscVConstants.MSTATUS_TVM_MASK() != 0)) {
            return (false, 0);
        } else {
            return (true, mi.readSatp(mmIndex));
        }
    }

    function readCsrMstatus(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMstatus(mmIndex) & RiscVConstants.MSTATUS_R_MASK());
    }

    function readCsrMisa(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMisa(mmIndex));
    }

    function readCsrMedeleg(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMedeleg(mmIndex));
    }

    function readCsrMideleg(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMideleg(mmIndex));
    }

    function readCsrMie(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMie(mmIndex));
    }

    function readCsrMtvec(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMtvec(mmIndex));
    }

    function readCsrMcounteren(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMcounteren(mmIndex));
    }

    function readCsrMscratch(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMscratch(mmIndex));
    }

    function readCsrMepc(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMepc(mmIndex));
    }

    function readCsrMcause(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMcause(mmIndex));
    }

    function readCsrMtval(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMtval(mmIndex));
    }

    function readCsrMip(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMip(mmIndex));
    }

    function readCsrMcycle(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMcycle(mmIndex));
    }

    function readCsrMinstret(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMinstret(mmIndex));
    }

    function readCsrMvendorid(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMvendorid(mmIndex));
    }

    function readCsrMarchid(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMarchid(mmIndex));
    }

    function readCsrMimpid(MemoryInteractor mi, uint256 mmIndex)
    internal returns(bool, uint64)
    {
        return (true, mi.readMimpid(mmIndex));
    }

    // readCsrSuccess/fail make it easier to change behaviour if necessary.
    //  function readCsrSuccess(uint64 val) internal returns(bool, uint64){
    //    return (true, val);
    //  }
    function readCsrFail() internal returns(bool, uint64) {
        return (false, 0);
    }

    // Check if counter is enabled. mcounteren control the availability of the
    // hardware performance monitoring counter to the next-lowest priv level.
    // Reference: riscv-privileged-v1.10 - section 3.1.17 - page 32.
    function rdcounteren(MemoryInteractor mi, uint256 mmIndex, uint32 csrAddr)
    internal returns (bool)
    {
        uint64 counteren = RiscVConstants.MCOUNTEREN_RW_MASK();
        uint64 priv = mi.readIflags_PRV(mmIndex);

        if (priv < RiscVConstants.PRV_M()) {
            counteren &= mi.readMcounteren(mmIndex);
            if (priv < RiscVConstants.PRV_S()) {
                counteren &= mi.readScounteren(mmIndex);
            }
        }
        return (((counteren >> (csrAddr & 0x1f)) & 1) != 0);
    }

}
