// @title CSR_2
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";
import "../contracts/CSR.sol";


library CSRExecute {
    uint256 constant CSRRS_CODE = 0;
    uint256 constant CSRRC_CODE = 1;

    uint256 constant CSRRSI_CODE = 0;
    uint256 constant CSRRCI_CODE = 1;

    /// \brief Implementation of CSRRS and CSRRC instructions
    /// \details The specific instruction is decided by insncode, which defines the value to be written.
    function executeCsrSC(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint256 insncode
    )
    public returns (bool)
    {
        uint32 csrAddress = RiscVDecoder.insnIUimm(insn);

        bool status = false;
        uint64 csrval = 0;

        (status, csrval) = CSR.readCsr(mi, mmIndex, csrAddress);

        if (!status) {
            //return raiseIllegalInsnException(mi, mmIndex, insn);
            return false;
        }
        uint32 rs1 = RiscVDecoder.insnRs1(insn);
        uint64 rs1val = mi.readX(mmIndex, rs1);
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(mmIndex, rd, csrval);
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
                mmIndex,
                csrAddress,
                execValue
            )) {
                //return raiseIllegalInsnException(mi, mmIndex, insn);
                return false;
            }
        }
        //return advanceToNextInsn(mi, mmIndex, pc);
        return true;
    }

    /// \brief Implementation of CSRRSI and CSRRCI instructions
    /// \details The specific instruction is decided by insncode, which defines the value to be written.
    function executeCsrSCI(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint32 insn,
        uint256 insncode)
    public returns (bool)
    {
        uint32 csrAddress = RiscVDecoder.insnIUimm(insn);

        bool status = false;
        uint64 csrval = 0;

        (status, csrval) = CSR.readCsr(mi, mmIndex, csrAddress);

        if (!status) {
            //return raiseIllegalInsnException(mi, mmIndex, insn);
            return false;
        }
        uint32 rs1 = RiscVDecoder.insnRs1(insn);
        uint32 rd = RiscVDecoder.insnRd(insn);

        if (rd != 0) {
            mi.writeX(mmIndex, rd, csrval);
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
                mmIndex,
                csrAddress,
                execValue
            )) {
                //return raiseIllegalInsnException(mi, mmIndex, insn);
                return false;
            }
        }
        //return advanceToNextInsn(mi, mmIndex, pc);
        return true;
    }

    /// \brief Implementation of CSRRW and CSRRWI instructions
    /// \details The specific instruction is decided by insncode, which defines the value to be written.
    function executeCsrRW(
        MemoryInteractor mi,
        uint256 mmIndex,
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
            (status, csrval) = CSR.readCsr(mi, mmIndex, csrAddress);
        }

        if (!status) {
            //return raiseIllegalInsnException(mi, mmIndex, insn);
            return false;
        }

        if (insncode == 0) {
            rs1val = executeCSRRW(mi, mmIndex, insn);
        } else {
            // insncode == 1
            rs1val = executeCSRRWI(insn);
        }

        if (!CSR.writeCsr(
                mi,
                mmIndex,
                csrAddress,
                rs1val
        )) {
            //return raiseIllegalInsnException(mi, mmIndex, insn);
            return false;
        }
        if (rd != 0) {
            mi.writeX(mmIndex, rd, csrval);
        }
        //return advanceToNextInsn(mi, mmIndex, pc);
        return true;
    }

    //internal functions
    function executeCSRRW(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
    internal returns(uint64)
    {
        return mi.readX(mmIndex, RiscVDecoder.insnRs1(insn));
    }

    function executeCSRRWI(uint32 insn) internal returns(uint64) {
        return uint64(RiscVDecoder.insnRs1(insn));
    }

    function executeCSRRS(uint64 csr, uint64 rs1) internal returns(uint64) {
        return csr | rs1;
    }

    function executeCSRRC(uint64 csr, uint64 rs1) internal returns(uint64) {
        return csr & ~rs1;
    }

    function executeCSRRSI(uint64 csr, uint32 rs1) internal returns(uint64) {
        return csr | rs1;
    }

    function executeCSRRCI(uint64 csr, uint32 rs1) internal returns(uint64) {
        return csr & ~rs1;
    }
}

