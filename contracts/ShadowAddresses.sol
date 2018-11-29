/// @title ShadowAddresses
pragma solidity 0.4.24;

library ShadowAddresses {
  // The processor state. Memory-mapped to the lowest 512 bytes in pm
  // Defined on Cartesi techpaper version 1.02 - Section 3 - table 2
  //source: https://cartesi.io/cartesi_whitepaper.pdf 
  uint64 constant pc         = 0x100;
  uint64 constant mvendorid  = 0x108;
  uint64 constant marchid    = 0x110;
  uint64 constant mimpid     = 0x118;
  uint64 constant mcycle     = 0x120;
  uint64 constant minstret   = 0x128;
  uint64 constant mstatus    = 0x130;
  uint64 constant mtvec      = 0x138;
  uint64 constant mscratch   = 0x140;
  uint64 constant mepc       = 0x148;
  uint64 constant mcause     = 0x150;
  uint64 constant mtval      = 0x158;
  uint64 constant misa       = 0x160;
  uint64 constant mie        = 0x168;
  uint64 constant mip        = 0x170;
  uint64 constant medeleg    = 0x178;
  uint64 constant mideleg    = 0x180;
  uint64 constant mcounteren = 0x188;
  uint64 constant stvec      = 0x190;
  uint64 constant sscratch   = 0x198;
  uint64 constant sepc       = 0x1a0;
  uint64 constant scause     = 0x1a8;
  uint64 constant stval      = 0x1b0;
  uint64 constant satp       = 0x1b8;
  uint64 constant scounteren = 0x1c0;
  uint64 constant ilrsc      = 0x1c8;
  uint64 constant iflags     = 0x1d0;

  //getters - contracts cant access constants directly
  //TO-DO: fix identation (this way was easier for my vim macros
  function get_pc()         public returns(uint64) {return pc;}
  function get_mvendorid()  public returns(uint64) {return mvendorid;}
  function get_marchid()    public returns(uint64) {return marchid;}
  function get_mimpid()     public returns(uint64) {return mimpid;}
  function get_mcycle()     public returns(uint64) {return mcycle;}
  function get_minstret()   public returns(uint64) {return minstret;}
  function get_mstatus()    public returns(uint64) {return mstatus;}
  function get_mtvec()      public returns(uint64) {return mtvec;}
  function get_mscratch()   public returns(uint64) {return mscratch;}
  function get_mepc()       public returns(uint64) {return mepc;}
  function get_mcause()     public returns(uint64) {return mcause;}
  function get_mtval()      public returns(uint64) {return mtval;}
  function get_misa()       public returns(uint64) {return misa;}
  function get_mie()        public returns(uint64) {return mie;}
  function get_mip()        public returns(uint64) {return mip;}
  function get_medeleg()    public returns(uint64) {return medeleg;}
  function get_mideleg()    public returns(uint64) {return mideleg;}
  function get_mcounteren() public returns(uint64) {return mcounteren;}
  function get_stvec()      public returns(uint64) {return stvec;}
  function get_sscratch()   public returns(uint64) {return sscratch;}
  function get_sepc()       public returns(uint64) {return sepc;}
  function get_scause()     public returns(uint64) {return scause;}
  function get_stval()      public returns(uint64) {return stval;}
  function get_satp()       public returns(uint64) {return satp;}
  function get_scounteren() public returns(uint64) {return scounteren;}
  function get_ilrsc()      public returns(uint64) {return ilrsc;}
  function get_iflags()     public returns(uint64) {return iflags;}
}
