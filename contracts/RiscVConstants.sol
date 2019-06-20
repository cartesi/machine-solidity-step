/// @title riscvconstants
pragma solidity ^0.5.0;


library RiscVConstants {
    //general purpose
    function getXlen() public returns(uint64) {return 64;}
    function getMxl()  public returns(uint64) {return 2;}

    //privilege levels
    function getPrvU() public returns(uint64) {return 0;}
    function getPrvS() public returns(uint64) {return 1;}
    function getPrvH() public returns(uint64) {return 2;}
    function getPrvM() public returns(uint64) {return 3;}

    //mstatus shifts
    function getMstatusUieShift()  public returns(uint64) {return 0;}
    function getMstatusSieShift()  public returns(uint64) {return 1;}
    function getMstatusHieShift()  public returns(uint64) {return 2;}
    function getMstatusMieShift()  public returns(uint64) {return 3;}
    function getMstatusUpieShift() public returns(uint64) {return 4;}
    function getMstatusSpieShift() public returns(uint64) {return 5;}
    function getMstatusMpieShift() public returns(uint64) {return 7;}
    function getMstatusSppShift()  public returns(uint64) {return 8;}
    function getMstatusMppShift()  public returns(uint64) {return 11;}
    function getMstatusFsShift()   public returns(uint64) {return 13;}

    function getMstatusXsShift()   public returns(uint64) {return 15;}
    function getMstatusMprvShift() public returns(uint64) {return 17;}
    function getMstatusSumShift()  public returns(uint64) {return 18;}
    function getMstatusMxrShift()  public returns(uint64) {return 19;}
    function getMstatusTvmShift()  public returns(uint64) {return 20;}
    function getMstatusTwShift()   public returns(uint64) {return 21;}
    function getMstatusTsrShift()  public returns(uint64) {return 22;}


    function getMstatusUxlShift()  public returns(uint64) {return 32;}
    function getMstatusSxlShift()  public returns(uint64) {return 34;}

    function getMstatusSdShift()   public returns(uint64) {return getXlen() - 1;}

    //mstatus masks
    function getMstatusUieMask()  public returns(uint64) {return (uint64(1) << getMstatusUieShift());}
    function getMstatusSieMask()  public returns(uint64) {return uint64(1) << getMstatusSieShift();}
    function getMstatusMieMask()  public returns(uint64) {return uint64(1) << getMstatusMieShift();}
    function getMstatusUpieMask() public returns(uint64) {return uint64(1) << getMstatusUpieShift();}
    function getMstatusSpieMask() public returns(uint64) {return uint64(1) << getMstatusSpieShift();}
    function getMstatusMpieMask() public returns(uint64) {return uint64(1) << getMstatusMpieShift();}
    function getMstatusSppMask()  public returns(uint64) {return uint64(1) << getMstatusSppShift();}
    function getMstatusMppMask()  public returns(uint64) {return uint64(3) << getMstatusMppShift();}
    function getMstatusFsMask()   public returns(uint64) {return uint64(3) << getMstatusFsShift();}
    function getMstatusXsMask()   public returns(uint64) {return uint64(3) << getMstatusXsShift();}
    function getMstatusMprvMask() public returns(uint64) {return uint64(1) << getMstatusMprvShift();}
    function getMstatusSumMask()  public returns(uint64) {return uint64(1) << getMstatusSumShift();}
    function getMstatusMxrMask()  public returns(uint64) {return uint64(1) << getMstatusMxrShift();}
    function getMstatusTvmMask()  public returns(uint64) {return uint64(1) << getMstatusTvmShift();}
    function getMstatusTwMask()   public returns(uint64) {return uint64(1) << getMstatusTwShift();}
    function getMstatusTsrMask()  public returns(uint64) {return uint64(1) << getMstatusTsrShift();}

    function getMstatusUxlMask()  public returns(uint64) {return uint64(3) << getMstatusUxlShift();}
    function getMstatusSxlMask()  public returns(uint64) {return uint64(3) << getMstatusSxlShift();}
    function getMstatusSdMask()   public returns(uint64) {return uint64(1) << getMstatusSdShift();}

    // mstatus read/writes
    function getMstatusWMask() public returns(uint64) {
        return (
            getMstatusUieMask()  |
            getMstatusSieMask()  |
            getMstatusMieMask()  |
            getMstatusUpieMask() |
            getMstatusSpieMask() |
            getMstatusMpieMask() |
            getMstatusSppMask()  |
            getMstatusMppMask()  |
            getMstatusFsMask()   |
            getMstatusMprvMask() |
            getMstatusSumMask()  |
            getMstatusMxrMask()  |
            getMstatusTvmMask()  |
            getMstatusTwMask()   |
            getMstatusTsrMask()
        );
    }

    function getMstatusRMask() public returns(uint64) {
        return (
            getMstatusUieMask()  |
            getMstatusSieMask()  |
            getMstatusMieMask()  |
            getMstatusUpieMask() |
            getMstatusSpieMask() |
            getMstatusMpieMask() |
            getMstatusSppMask()  |
            getMstatusMppMask()  |
            getMstatusFsMask()   |
            getMstatusMprvMask() |
            getMstatusSumMask()  |
            getMstatusMxrMask()  |
            getMstatusTvmMask()  |
            getMstatusTwMask()   |
            getMstatusTsrMask()  |
            getMstatusUxlMask()  |
            getMstatusSxlMask()  |
            getMstatusSdMask()
        );
    }

    // sstatus read/writes
    function getSstatusWMask() public returns(uint64) {
        return (
            getMstatusUieMask()  |
            getMstatusSieMask()  |
            getMstatusUpieMask() |
            getMstatusSpieMask() |
            getMstatusSppMask()  |
            getMstatusFsMask()   |
            getMstatusSumMask()  |
            getMstatusMxrMask()
        );
    }

    function getSstatusRMask() public returns(uint64) {
        return (
            getMstatusUieMask()  |
            getMstatusSieMask()  |
            getMstatusUpieMask() |
            getMstatusSpieMask() |
            getMstatusSppMask()  |
            getMstatusFsMask()   |
            getMstatusSumMask()  |
            getMstatusMxrMask()  |
            getMstatusUxlMask()  |
            getMstatusSdMask()
        );
    }

    // mcause for exceptions
    function getMcauseInsnAddressMisaligned() public returns(uint64) {return 0x0;} ///< instruction address misaligned
    function getMcauseInsnAccessFault() public returns(uint64) {return 0x1;} ///< instruction access fault
    function getMcauseIllegalInsn() public returns(uint64) {return 0x2;} ///< illegal instruction
    function getMcauseBreakpoint() public returns(uint64) {return 0x3;} ///< breakpoint
    function getMcauseLoadAddressMisaligned() public returns(uint64) {return 0x4;} ///< load address misaligned
    function getMcauseLoadAccessFault() public returns(uint64) {return 0x5;} ///< load access fault
    function getMcauseStoreAmoAddressMisaligned() public returns(uint64) {return 0x6;} ///< store/amo address misaligned
    function getMcauseStoreAmoAccessFault() public returns(uint64) {return 0x7;} ///< store/amo access fault
    function getMcauseEcallBase() public returns(uint64) {return 0x8;} ///< environment call (+0: from u-mode, +1: from s-mode, +3: from m-mode)
    function getMcauseFetchPageFault() public returns(uint64) {return 0xc;} ///< instruction page fault
    function getMcauseLoadPageFault() public returns(uint64) {return 0xd;} ///< load page fault
    function getMcauseStoreAmoPageFault() public returns(uint64) {return 0xf;} ///< store/amo page fault

    function getMcauseInterruptFlag() public returns(uint64) {return uint64(1) << (getXlen() - 1);} ///< interrupt flag

    // mcounteren constants
    function getMcounterenCyShift() public returns(uint64) {return 0;}
    function getMcounterenTmShift() public returns(uint64) {return 1;}
    function getMcounterenIrShift() public returns(uint64) {return 2;}

    function getMcounterenCyMask() public returns(uint64) {return uint64(1) << getMcounterenCyShift();}
    function getMcounterenTmMask() public returns(uint64) {return uint64(1) << getMcounterenTmShift();}
    function getMcounterenIrMask() public returns(uint64) {return uint64(1) << getMcounterenIrShift();}

    function getMcounterenRwMask() public returns(uint64) {return getMcounterenCyMask() | getMcounterenTmMask() | getMcounterenIrMask();}
    function getScounterenRwMask() public returns(uint64) {return getMcounterenRwMask();}

    //paging constants
    function getPgShift() public returns(uint64) {return 12;}
    function getPgMask()  public returns(uint64) {((1 << getPgShift()) - 1);}

    function getPteVMask() public returns(uint64) {return (1 << 0);}
    function getPteUMask() public returns(uint64) {return (1 << 4);}
    function getPteAMask() public returns(uint64) {return (1 << 6);}
    function getPteDMask() public returns(uint64) {return (1 << 7);}

    function getPteXwrReadShift() public returns(uint64) {return 0;}
    function getPteXwrWriteShift() public returns(uint64) {return 1;}
    function getPteXwrCodeShift() public returns(uint64) {return 2;}

    // page masks
    function getPageNumberShift() public returns(uint64) {return 12;}

    function getPageOffsetMask() public returns(uint64) {return ((uint64(1) << getPageNumberShift()) - 1);}

    // mip shifts:
    function getMipUsipShift() public returns(uint64) {return 0;}
    function getMipSsipShift() public returns(uint64) {return 1;}
    function getMipMsipShift() public returns(uint64) {return 3;}
    function getMipUtipShift() public returns(uint64) {return 4;}
    function getMipStipShift() public returns(uint64) {return 5;}
    function getMipMtipShift() public returns(uint64) {return 7;}
    function getMipUeipShift() public returns(uint64) {return 8;}
    function getMipSeipShift() public returns(uint64) {return 9;}
    function getMipMeipShift() public returns(uint64) {return 11;}

    function getMipUsipMask() public returns(uint64) {return uint64(1) << getMipUsipShift();}
    function getMipSsipMask() public returns(uint64) {return uint64(1) << getMipSsipShift();}
    function getMipMsipMask() public returns(uint64) {return uint64(1) << getMipMsipShift();}
    function getMipUtipMask() public returns(uint64) {return uint64(1) << getMipUtipShift();}
    function getMipStipMask() public returns(uint64) {return uint64(1) << getMipStipShift();}
    function getMipMtipMask() public returns(uint64) {return uint64(1) << getMipMtipShift();}
    function getMipUeipMask() public returns(uint64) {return uint64(1) << getMipUeipShift();}
    function getMipSeipMask() public returns(uint64) {return uint64(1) << getMipSeipShift();}
    function getMipMeipMask() public returns(uint64) {return uint64(1) << getMipMeipShift();}
}
