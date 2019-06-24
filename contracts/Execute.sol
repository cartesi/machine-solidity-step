/// @title Execute
pragma solidity ^0.5.0;

import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./VirtualMemory.sol";
import "../contracts/MemoryInteractor.sol";
import "../contracts/CSRExecute.sol";
import "./RiscVInstructions/BranchInstructions.sol";
import "./RiscVInstructions/ArithmeticInstructions.sol";
import "./RiscVInstructions/ArithmeticImmediateInstructions.sol";
import "./RiscVInstructions/S_Instructions.sol";
import "./RiscVInstructions/StandAloneInstructions.sol";
import "./RiscVInstructions/AtomicInstructions.sol";
import "./RiscVInstructions/EnvTrapIntInstructions.sol";
import {Exceptions} from "../contracts/Exceptions.sol";

library Execute {
  // event  Print(string a, uint b);

  uint256 constant arith_imm_group = 0;
  uint256 constant arith_imm_group_32 = 1;

  uint256 constant arith_group = 0;
  uint256 constant arith_group_32 = 1;

  uint256 constant CSRRW_code = 0;
  uint256 constant CSRRWI_code = 1;

  uint256 constant CSRRS_code = 0;
  uint256 constant CSRRC_code = 1;

  uint256 constant CSRRSI_code = 0;
  uint256 constant CSRRCI_code = 1;


  function execute_insn(uint256 _mmIndex, address _miAddress, uint32 insn, uint64 pc)
  public returns (execute_status) {
    MemoryInteractor mi = MemoryInteractor(_miAddress);
    uint256 mmIndex = _mmIndex;

    // Find instruction associated with that opcode
    // Sometimes the opcode fully defines the associated instructions, but most
    // of the times it only specifies which group it belongs to.
    // For example, an opcode of: 01100111 is always a LUI instruction but an
    // opcode of 1100011 might be BEQ, BNE, BLT etc
    // Reference: riscv-spec-v2.2.pdf - Table 19.2 - Page 104
     return opinsn(mi, mmIndex, insn, pc);
  }
  function execute_arithmetic_immediate(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc, uint256 imm_group)
  public returns (execute_status){
    uint32 rd = RiscVDecoder.insn_rd(insn);
    uint64 arith_imm_result;
    bool insn_valid;

    if(rd != 0){
      if (imm_group == arith_imm_group){
        (arith_imm_result, insn_valid) = ArithmeticImmediateInstructions.arithmetic_immediate_funct3(mi, mmIndex, insn);
      } else {
        //imm_group == arith_imm_group_32
        (arith_imm_result, insn_valid) = ArithmeticImmediateInstructions.arithmetic_immediate_32_funct3(mi, mmIndex, insn);
      }

      if(!insn_valid){
        return raise_illegal_insn_exception(mi, mmIndex, insn);
      }

      mi.write_x(mmIndex, rd, arith_imm_result);
    }
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  function execute_arithmetic(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc, uint256 groupCode)
  public returns (execute_status){
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if(rd != 0){
      uint64 arith_result = 0;
      bool insn_valid = false;

      if(groupCode == arith_group){
        (arith_result, insn_valid) = ArithmeticInstructions.arithmetic_funct3_funct7(mi, mmIndex, insn);
      } else {
        // groupCode == arith_32_group
        (arith_result, insn_valid) = ArithmeticInstructions.arithmetic_32_funct3_funct7(mi, mmIndex, insn);
      }

      if(!insn_valid){
        return raise_illegal_insn_exception(mi, mmIndex, insn);
      }
      mi.write_x(mmIndex, rd, arith_result);
    }
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  function execute_branch(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc) 
  public returns (execute_status){

    (bool branch_valuated, bool insn_valid) = BranchInstructions.branch_funct3(mi, mmIndex, insn);

    if(!insn_valid){
      return raise_illegal_insn_exception(mi, mmIndex, insn);
    }

    if(branch_valuated){
      uint64 new_pc = uint64(int64(pc) + int64(RiscVDecoder.insn_B_imm(insn)));
      if((new_pc & 3) != 0) {
        return raise_misaligned_fetch_exception(mi, mmIndex, new_pc);
      }else {
        return execute_jump(mi, mmIndex, new_pc);
      }
    }
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  function execute_load(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc, uint64 wordSize, bool isSigned)
  public returns (execute_status) {
    uint64 vaddr = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
    int32 imm = RiscVDecoder.insn_I_imm(insn);
    (bool succ, uint64 val) = VirtualMemory.read_virtual_memory(mi, mmIndex, wordSize, vaddr + uint64(imm));

    if (succ) {
      if (isSigned) {
        val = BitsManipulationLibrary.uint64_sign_extension(val, wordSize);
      }
      mi.write_x(mmIndex, RiscVDecoder.insn_rd(insn), val);
      return advance_to_next_insn(mi, mmIndex, pc);
    } else {
      //return advance_to_raised_exception()
      return execute_status.retired;
    }
  }
  function execute_SFENCE_VMA(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc) public returns (execute_status) {
    if ((insn & 0xFE007FFF) == 0x12000073) {
      uint64 priv = mi.read_iflags_PRV(mmIndex);
      uint64 mstatus = mi.read_mstatus(mmIndex);

      if (priv == RiscVConstants.PRV_U() || (priv == RiscVConstants.PRV_S() && ((mstatus & RiscVConstants.MSTATUS_TVM_MASK() != 0)))) {
        return raise_illegal_insn_exception(mi, mmIndex, insn);
      }

      return advance_to_next_insn(mi, mmIndex, pc);
    } else {
        return raise_illegal_insn_exception(mi, mmIndex, insn);
    }
  }


  function execute_jump(MemoryInteractor mi, uint256 mmIndex, uint64 new_pc) public returns (execute_status){
    mi.memoryWrite(mmIndex, ShadowAddresses.get_pc(), new_pc);
    return execute_status.retired;
  }

  function raise_misaligned_fetch_exception(MemoryInteractor mi, uint256 mmIndex, uint64 pc)
  public returns (execute_status){
    Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_INSN_ADDRESS_MISALIGNED(), pc);
    return execute_status.retired;
  }

  function raise_illegal_insn_exception(MemoryInteractor mi, uint256 mmIndex, uint32 insn) 
  public returns (execute_status){
    Exceptions.raise_exception(mi, mmIndex, Exceptions.MCAUSE_ILLEGAL_INSN(), insn);
    return execute_status.illegal;
  }

  function advance_to_next_insn(MemoryInteractor mi, uint256 mmIndex, uint64 pc)
  public returns (execute_status){
    mi.memoryWrite(mmIndex, ShadowAddresses.get_pc(), pc + 4);
    //emit Print("advance_to_next", 0);
    return execute_status.retired;
  }

  /// @notice Given a fence funct3 insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for fence funct3 field.
  function fence_group(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns(execute_status){
    if(insn == 0x0000100f){
      /*insn == 0x0000*/
      //return "FENCE";
      //really do nothing
      return advance_to_next_insn(mi, mmIndex, pc);
    }else if(insn & 0xf00fff80 != 0){
      /*insn == 0x0001*/
      return raise_illegal_insn_exception(mi, mmIndex, insn);
    }
    //return "FENCE_I";
    //really do nothing
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  /// @notice Given csr env trap int mm funct3 insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for csr env trap int mm funct3 field.
  function csr_env_trap_int_mm_funct3(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns (execute_status){
    uint32 funct3 = RiscVDecoder.insn_funct3(insn);

    if(funct3 < 0x0003){
      if(funct3 == 0x0000){
        /*funct3 == 0x0000*/
        return env_trap_int_group(mi, mmIndex, insn, pc);
      }else if(funct3 ==  0x0002){
        /*funct3 == 0x0002*/
        //return "CSRRS";
        if (CSRExecute.execute_csr_SC(mi, mmIndex, insn, CSRRS_code)){
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return raise_illegal_insn_exception(mi, mmIndex, insn);
        }
      }else if(funct3 == 0x0001){
        /*funct3 == 0x0001*/
        //return "CSRRW";
        if (CSRExecute.execute_csr_RW(mi, mmIndex, insn, CSRRW_code)){
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return raise_illegal_insn_exception(mi, mmIndex, insn);
        }
      }
    }else if(funct3 > 0x0003){
      if(funct3 == 0x0005){
        /*funct3 == 0x0005*/
        //return "CSRRWI";
        if (CSRExecute.execute_csr_RW(mi, mmIndex, insn, CSRRWI_code)){
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return raise_illegal_insn_exception(mi, mmIndex, insn);
        }
      }else if(funct3 == 0x0007){
        /*funct3 == 0x0007*/
        //return "CSRRCI";
        if (CSRExecute.execute_csr_SCI(mi, mmIndex, insn, CSRRCI_code)){
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return raise_illegal_insn_exception(mi, mmIndex, insn);
        }
      }else if(funct3 == 0x0006){
        /*funct3 == 0x0006*/
        //return "CSRRSI";
        if (CSRExecute.execute_csr_SCI(mi, mmIndex, insn, CSRRSI_code)){
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return raise_illegal_insn_exception(mi, mmIndex, insn);
        }
      }
    }else if(funct3 == 0x0003){
      /*funct3 == 0x0003*/
      //return "CSRRC";
      if (CSRExecute.execute_csr_SC(mi, mmIndex, insn, CSRRC_code)){
        return advance_to_next_insn(mi, mmIndex, pc);
      } else {
        return raise_illegal_insn_exception(mi, mmIndex, insn);
      }
    }
    return raise_illegal_insn_exception(mi, mmIndex, insn);
  }

  /// @notice Given a store funct3 group insn, finds the function  associated.
  //  Uses binary search for performance
  //  @param insn for store funct3 field
  function store_funct3(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns (execute_status){
    uint32 funct3 = RiscVDecoder.insn_funct3(insn);
    bool write_success = false;
    if(funct3 == 0x0000){
      /*funct3 == 0x0000*/
      //return "SB";
      return S_Instructions.SB(mi, mmIndex, pc, insn) ? advance_to_next_insn(mi, mmIndex, pc) : execute_status.retired;
    }else if(funct3 > 0x0001){
      if(funct3 == 0x0002){
        /*funct3 == 0x0002*/
        //return "SW";
        return S_Instructions.SW(mi, mmIndex, pc, insn) ? advance_to_next_insn(mi, mmIndex, pc) : execute_status.retired;
      }else if(funct3 == 0x0003){
        /*funct3 == 0x0003*/
        //return "SD";
        return S_Instructions.SD(mi, mmIndex, pc, insn) ? advance_to_next_insn(mi, mmIndex, pc) : execute_status.retired;
      }
    }else if(funct3 == 0x0001){
      /*funct3 == 0x0001*/
      //return "SH";
      return S_Instructions.SH(mi, mmIndex, pc, insn) ? advance_to_next_insn(mi, mmIndex, pc) : execute_status.retired;
    }
    return raise_illegal_insn_exception(mi, mmIndex, insn);
  }


  /// @notice Given a env trap int group insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for env trap int group field.
  function env_trap_int_group(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns (execute_status){
    if(insn < 0x10200073){
      if(insn == 0x0073){
        /*insn == 0x0073*/
        //return "ECALL";
        EnvTrapIntInstructions.execute_ECALL(mi, mmIndex, insn, pc);
        return execute_status.retired;
      }else if(insn == 0x200073){
        /*insn == 0x200073*/
        //return "URET";
        // No U-Mode traps
        raise_illegal_insn_exception(mi, mmIndex, insn);
      }else if(insn == 0x100073){
        /*insn == 0x100073*/
        //return "EBREAK"; 
        EnvTrapIntInstructions.execute_EBREAK(mi, mmIndex, insn, pc);
        return execute_status.retired;
      }
    }else if(insn > 0x10200073){
      if(insn == 0x10500073){
        /*insn == 0x10500073*/
        //return "WFI";
        if (!EnvTrapIntInstructions.execute_WFI(mi, mmIndex, insn, pc)) {
          return raise_illegal_insn_exception(mi, mmIndex, insn);
        }
        return advance_to_next_insn(mi, mmIndex, pc);
      }else if(insn == 0x30200073){
        /*insn == 0x30200073*/
        //return "MRET";
        if (!EnvTrapIntInstructions.execute_MRET(mi, mmIndex, insn, pc)){
        return raise_illegal_insn_exception(mi, mmIndex, insn);
      }
        return execute_status.retired;
      }
    }else if(insn == 0x10200073){
      /*insn = 0x10200073*/
      //return "SRET";
      if (!EnvTrapIntInstructions.execute_SRET(mi, mmIndex, insn, pc)){
        return raise_illegal_insn_exception(mi, mmIndex, insn);
      }
      return execute_status.retired;
   }
    return execute_SFENCE_VMA(mi, mmIndex, insn, pc);
    //return raise_illegal_insn_exception(mi, mmIndex, insn);
  }

  /// @notice Given a load funct3 group instruction, finds the function
  //  associated with it. Uses binary search for performance
  //  @param insn for load funct3 field
  function load_funct3(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
 public returns (execute_status){
    uint32 funct3 = RiscVDecoder.insn_funct3(insn);

    if(funct3 < 0x0003){
      if(funct3 == 0x0000){
        /*funct3 == 0x0000*/
        //return "LB";
        return execute_load(mi, mmIndex, insn, pc, 8, true);

      }else if(funct3 == 0x0002){
        /*funct3 == 0x0002*/
        //return "LW";
        return execute_load(mi, mmIndex, insn, pc, 32, true);
      }else if(funct3 == 0x0001){
        /*funct3 == 0x0001*/
        //return "LH";
        return execute_load(mi, mmIndex, insn, pc, 16, true);
      }
    }else if(funct3 > 0x0003){
      if(funct3 == 0x0004){
        /*funct3 == 0x0004*/
        //return "LBU";
        return execute_load(mi, mmIndex, insn, pc, 8, false);
      }else if(funct3 == 0x0006){
        /*funct3 == 0x0006*/
        //return "LWU";
        return execute_load(mi, mmIndex, insn, pc, 32, false);
      }else if(funct3 == 0x0005){
        /*funct3 == 0x0005*/
        //return "LHU";
        return execute_load(mi, mmIndex, insn, pc, 16, false);
      }
    }else if(funct3 == 0x0003){
      /*funct3 == 0x0003*/
      //return "LD";
      return execute_load(mi, mmIndex, insn, pc, 64, true);
    }
    return raise_illegal_insn_exception(mi, mmIndex, insn);
  }

//  @param insn for atomic funct3_funct5 field
  function atomic_funct3_funct5(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
 public returns (execute_status){
    uint32 funct3_funct5 = RiscVDecoder.insn_funct3_funct5(insn);
    bool atom_succ;
    // TO-DO: transform in binary search for performance
    if (funct3_funct5 == 0x42) {
      if ((insn & 0x1f00000) == 0 ) {
        atom_succ = AtomicInstructions.execute_LR(mi, mmIndex, pc, insn, 32);
      } else {
        return raise_illegal_insn_exception(mi, mmIndex, insn);
      }
//      return execute_LR_W;
    } else if (funct3_funct5 == 0x43) {
        atom_succ = AtomicInstructions.execute_SC(mi, mmIndex, pc, insn, 32);
//      return execute_SC_W;
    } else if (funct3_funct5 == 0x41) {
        atom_succ = AtomicInstructions.execute_AMOSWAP_W(mi, mmIndex, pc, insn);
    } else if (funct3_funct5 == 0x40) {
        atom_succ = AtomicInstructions.execute_AMOADD_W(mi, mmIndex, pc, insn);
//      return execute_AMOADD_W;
    } else if (funct3_funct5 == 0x44) {
        atom_succ = AtomicInstructions.execute_AMOXOR_W(mi, mmIndex, pc, insn);
//      return execute_AMOXOR_W;
    } else if (funct3_funct5 == 0x4c) {
        atom_succ = AtomicInstructions.execute_AMOAND_W(mi, mmIndex, pc, insn);
//      return execute_AMOAND_W;
    } else if (funct3_funct5 == 0x48) {
        atom_succ = AtomicInstructions.execute_AMOOR_W(mi, mmIndex, pc, insn);
//      return execute_AMOOR_W;
    } else if (funct3_funct5 == 0x50) {
        atom_succ = AtomicInstructions.execute_AMOMIN_W(mi, mmIndex, pc, insn);
//      return execute_AMOMIN_W;
    } else if (funct3_funct5 == 0x54) {
        atom_succ = AtomicInstructions.execute_AMOMAX_W(mi, mmIndex, pc, insn);
//      return execute_AMOMAX_W;
    } else if (funct3_funct5 == 0x58) {
        atom_succ = AtomicInstructions.execute_AMOMINU_W(mi, mmIndex, pc, insn);
//      return execute_AMOMINU_W;
    } else if (funct3_funct5 == 0x5c) {
        atom_succ = AtomicInstructions.execute_AMOMAXU_W(mi, mmIndex, pc, insn);
//      return execute_AMOMAXU_W;
    } else if (funct3_funct5 == 0x62) {
      if ((insn & 0x1f00000) == 0 ) {
        atom_succ = AtomicInstructions.execute_LR(mi, mmIndex, pc, insn, 64);
      }
      //return execute_LR_D;
    } else if (funct3_funct5 == 0x63) {
        atom_succ = AtomicInstructions.execute_SC(mi, mmIndex, pc, insn, 64);
//      return execute_SC_D;
    } else if (funct3_funct5 == 0x61) { 
        atom_succ = AtomicInstructions.execute_AMOSWAP_D(mi, mmIndex, pc, insn);
//    return execute_AMOSWAP_D;;
    } else if (funct3_funct5 == 0x60) {
        atom_succ = AtomicInstructions.execute_AMOADD_D(mi, mmIndex, pc, insn);
//    return execute_AMOADD_D;
    } else if (funct3_funct5 == 0x64) {
        atom_succ = AtomicInstructions.execute_AMOXOR_D(mi, mmIndex, pc, insn);
//    return execute_AMOXOR_D;
    } else if (funct3_funct5 == 0x6c) {
        atom_succ = AtomicInstructions.execute_AMOAND_D(mi, mmIndex, pc, insn);
//    return execute_AMOAND_D;
    } else if (funct3_funct5 == 0x68) {
        atom_succ = AtomicInstructions.execute_AMOOR_D(mi, mmIndex, pc, insn);
//    return execute_AMOOR_D;
    } else if (funct3_funct5 == 0x70) {
        atom_succ = AtomicInstructions.execute_AMOMIN_D(mi, mmIndex, pc, insn);
//    return execute_AMOMIN_D;
    } else if (funct3_funct5 == 0x74) {
        atom_succ = AtomicInstructions.execute_AMOMAX_D(mi, mmIndex, pc, insn);
//    return execute_AMOMAX_D;
    } else if (funct3_funct5 == 0x78) {
        atom_succ = AtomicInstructions.execute_AMOMINU_D(mi, mmIndex, pc, insn);
//      return execute_AMOMINU_D;
    } else if (funct3_funct5 == 0x7c) {
        atom_succ = AtomicInstructions.execute_AMOMAXU_D(mi, mmIndex, pc, insn);
//      return execute_AMOMAXU_D;
    }
    if (atom_succ) {
      return advance_to_next_insn(mi, mmIndex, pc);
    } else {
      return execute_status.retired;
    }
    return raise_illegal_insn_exception(mi, mmIndex, insn);
  }

  /// @notice Given an op code, finds the group of instructions it belongs to
  //  using a binary search for performance.
  //  @param insn for opcode fields.
  function opinsn(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc) 
  public returns (execute_status){
    // OPCODE is located on bit 0 - 6 of the following types of 32bits instructions:
    // R-Type, I-Type, S-Trype and U-Type
    // Reference: riscv-spec-v2.2.pdf - Figure 2.2 - Page 11
    uint32 opcode = RiscVDecoder.insn_opcode(insn);

    if(opcode < 0x002f){
      if(opcode < 0x0017){
        if(opcode == 0x0003){
          /*opcode is 0x0003*/
          // return "load_group";
          return load_funct3(mi, mmIndex, insn, pc);
        }else if(opcode == 0x000f){
          /*insn is 0x000f*/
          //return "fence_group";
          return fence_group(mi, mmIndex, insn, pc);
        }else if(opcode == 0x0013){
          /*opcode is 0x0013*/
          return execute_arithmetic_immediate(mi, mmIndex, insn, pc, arith_imm_group);
        }
      }else if (opcode > 0x0017){
        if (opcode == 0x001b){
          /*opcode is 0x001b*/
          //return "arithmetic_immediate_32_group";
          return execute_arithmetic_immediate(mi, mmIndex, insn, pc, arith_imm_group_32);
        }else if(opcode == 0x0023){
          /*opcode is 0x0023*/
          return store_funct3(mi, mmIndex, insn, pc);
        }
      }else if(opcode == 0x0017){
        /*opcode == 0x0017*/
        StandAloneInstructions.execute_auipc(mi, mmIndex, insn, pc);
        return advance_to_next_insn(mi, mmIndex, pc);
      }
    }else if (opcode > 0x002f){
      if (opcode < 0x0063){
        if (opcode == 0x0033){
          /*opcode is 0x0033*/
          //return "arithmetic_group";
          return execute_arithmetic(mi, mmIndex, insn, pc, arith_group);
        }else if (opcode == 0x003b){
          /*opcode is 0x003b*/
          //return "arithmetic_32_group";
          return execute_arithmetic(mi, mmIndex, insn, pc, arith_group_32);
        }else if(opcode == 0x0037){
          /*opcode == 0x0037*/
          //return "LUI";
          StandAloneInstructions.execute_lui(mi, mmIndex, insn, pc);
          return advance_to_next_insn(mi, mmIndex, pc);
        }
      }else if (opcode > 0x0063){
        if(opcode == 0x0067){
          /*opcode == 0x0067*/
          //return "JALR";
          (bool succ, uint64 new_pc) = StandAloneInstructions.execute_jalr(mi, mmIndex, insn, pc);
          if (succ) {
            return execute_jump(mi, mmIndex, new_pc);
          } else {
            return raise_misaligned_fetch_exception(mi, mmIndex, new_pc);
          }
        }else if(opcode == 0x0073){
          /*opcode == 0x0073*/
          return csr_env_trap_int_mm_funct3(mi, mmIndex, insn, pc);
        }else if(opcode == 0x006f){
          /*opcode == 0x006f*/
          //return "JAL";
          (bool succ, uint64 new_pc) = StandAloneInstructions.execute_jal(mi, mmIndex, insn, pc);
          if (succ) {
            return execute_jump(mi, mmIndex, new_pc);
          } else {
            return raise_misaligned_fetch_exception(mi, mmIndex, new_pc);
          }
        }
      }else if (opcode == 0x0063){
        /*opcode == 0x0063*/
        //return "branch_group";
        return execute_branch(mi, mmIndex, insn, pc);
      }
    }else if(opcode == 0x002f){
      /*opcode == 0x002f*/
      //return "atomic_group";
      return atomic_funct3_funct5(mi, mmIndex, insn, pc);
    }
    return raise_illegal_insn_exception(mi, mmIndex, insn);
  }

  enum execute_status {
    illegal, // Exception was raised
    retired // Instruction retired - having raised or not an exception
  }
}
