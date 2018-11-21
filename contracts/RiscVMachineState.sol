// @title RiscVMachineState
pragma solidity 0.4.24;

//TO-DO: Implement pma 
library RiscVMachineState {
  
  /// @notice Struct that defines the entire state of a Cartesi Machine
  struct Machine_state{
    uint64 pc;        ///< Program counter.
    uint64[32] x;     ///< Register file.

    uint8 iflags_PRV; ///< Privilege level.
    bool iflags_I;      ///< CPU is idle (waiting for interrupts).
    bool iflags_H;      ///< CPU has been permanently halted.

    uint64 minstret;  ///< CSR minstret.
    uint64 mcycle;

    uint64 mvendorid; ///< CSR mvendorid;
    uint64 marchid;   ///< CSR marchid;
    uint64 mimpid;    ///< CSR mimpid;

    uint64 mstatus; ///< CSR mstatus.
    uint64 mtvec; ///< CSR mtvec.
    uint64 mscratch; ///< CSR mscratch.
    uint64 mepc; ///< CSR mepc.
    uint64 mcause; ///< CSR mcause.
    uint64 mtval; ///< CSR mtval.
    uint64 misa; ///< CSR misa.

    uint32 mie; ///< CSR mie.
    uint32 mip; ///< CSR mip.
    uint32 medeleg; ///< CSR medeleg.
    uint32 mideleg; ///< CSR mideleg.
    uint32 mcounteren; ///< CSR mcounteren.

    uint64 stvec; ///< CSR stvec.
    uint64 sscratch; ///< CSR sscratch.
    uint64 sepc; ///< CSR sepc.
    uint64 scause; ///< CSR scause.
    uint64 stval; ///< CSR stval.
    uint64 satp; ///< CSR satp.
    uint32 scounteren; ///< CSR scounteren.

    uint64 ilrsc; ///< For LR/SC instructions

    uint64 mtimecmp; ///< CLINT register mtimecmp.
    uint64 tohost; ///< HTIF register tohost.
    uint64 fromhost; ///< HTIF register fromhost.

//TO-DO: Implement pma 
//    pma_entry physical_memory[PMA_SIZE]; ///< Physical memory map
//    int pma_count;             ///< Number of entries in map
  }
}


