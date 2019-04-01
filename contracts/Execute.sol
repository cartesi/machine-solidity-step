/// @title Execute
pragma solidity ^0.5.0;

import "./ShadowAddresses.sol";
import "./RiscVConstants.sol";
import "./RiscVDecoder.sol";
import "./VirtualMemory.sol";
import "../contracts/MemoryInteractor.sol";
import "../contracts/CSR.sol";
import "./RiscVInstructions/BranchInstructions.sol";
import "./RiscVInstructions/ArithmeticInstructions.sol";
import "./RiscVInstructions/ArithmeticImmediateInstructions.sol";
import "./RiscVInstructions/S_Instructions.sol";
import "./RiscVInstructions/AtomicInstructions.sol";
import "./RiscVInstructions/EnvTrapIntInstructions.sol";
import {Exceptions} from "../contracts/Exceptions.sol";

library Execute {
  event  Print(string a, uint b);

  uint256 constant CSRRW_code = 0;
  uint256 constant CSRRWI_code = 1;

  uint256 constant CSRRS_code = 0;
  uint256 constant CSRRC_code = 1;

  uint256 constant CSRRSI_code = 0;
  uint256 constant CSRRCI_code = 1;

  uint256 constant arith_imm_group = 0;
  uint256 constant arith_imm_group_32 = 1;

  uint256 constant arith_group = 0;
  uint256 constant arith_group_32 = 1;

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
        (arith_imm_result, insn_valid) = arithmetic_immediate_funct3(mi, mmIndex, insn);
      } else {
        //imm_group == arith_imm_group_32
        (arith_imm_result, insn_valid) = arithmetic_immediate_32_funct3(mi, mmIndex, insn);
      }

      if(!insn_valid){
        return raise_illegal_insn_exception(pc, insn);
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
        (arith_result, insn_valid) = arithmetic_funct3_funct7(mi, mmIndex, insn);
      } else {
        // groupCode == arith_32_group
        (arith_result, insn_valid) = arithmetic_32_funct3_funct7(mi, mmIndex, insn);
      }

      if(!insn_valid){
        return raise_illegal_insn_exception(pc, insn);
      }
      mi.write_x(mmIndex, rd, arith_result);
    }
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  function execute_branch(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc) 
  public returns (execute_status){

    (bool branch_valuated, bool insn_valid) = branch_funct3(mi, mmIndex, insn);

    if(!insn_valid){
      return raise_illegal_insn_exception(pc, insn);
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

  function execute_load(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc, uint256 wordSize, bool isSigned)
  public returns (execute_status) {
    uint64 vaddr = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
    int32 imm = RiscVDecoder.insn_I_imm(insn);
    (bool succ, uint64 val) = VirtualMemory.read_virtual_memory(mi, mmIndex, wordSize, vaddr + uint64(imm));

    if (succ) {
      if (isSigned) {
        // TO-DO: make sure this is ok
        mi.write_x(mmIndex, RiscVDecoder.insn_rd(insn), uint64(int64(val)));
      } else {
        mi.write_x(mmIndex, RiscVDecoder.insn_rd(insn), val);
      }
      return advance_to_next_insn(mi, mmIndex, pc);
    } else {
      //return advance_to_raised_exception()
      return execute_status.retired;
    }
  }

  function execute_csr_SC(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc, uint256 insncode)
  public returns (execute_status) {
    uint32 csr_address = RiscVDecoder.insn_I_uimm(insn);

    bool status = false;
    uint64 csrval = 0;

    (status, csrval) = CSR.read_csr(mi, mmIndex, csr_address);

    if (!status) {
      return raise_illegal_insn_exception(pc, insn);
    }
    uint32 rs1 = RiscVDecoder.insn_rs1(insn);
    uint64 rs1val = mi.read_x(mmIndex, rs1);
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if (rd != 0) {
      mi.write_x(mmIndex, rd, csrval);
    }

    uint64 exec_value = 0;
    if (insncode == CSRRS_code) {
      exec_value = CSR.execute_CSRRS(mi, mmIndex, insn, csrval, rs1val);
    } else {
      // insncode == CSRRC_code
      exec_value = CSR.execute_CSRRC(mi, mmIndex, insn, csrval, rs1val);
    }
    if (rs1 != 0) {
      if (!CSR.write_csr(mi, mmIndex, csr_address, exec_value)){
        return raise_illegal_insn_exception(pc, insn);
      }
    }
    return advance_to_next_insn(mi, mmIndex, pc);
  }

   function execute_csr_SCI(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc, uint256 insncode)
  public returns (execute_status){
    uint32 csr_address = RiscVDecoder.insn_I_uimm(insn);

    bool status = false;
    uint64 csrval = 0;

    (status, csrval) = CSR.read_csr(mi, mmIndex, csr_address);

    if (!status) {
      return raise_illegal_insn_exception(pc, insn);
    }
    uint32 rs1 = RiscVDecoder.insn_rs1(insn);
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if (rd != 0) {
      mi.write_x(mmIndex, rd, csrval);
    }

    uint64 exec_value = 0;
    if (insncode == CSRRSI_code) {
      exec_value = CSR.execute_CSRRS(mi, mmIndex, insn, csrval, rs1);
    } else {
      // insncode == CSRRCI_code
      exec_value = CSR.execute_CSRRCI(mi, mmIndex, insn, csrval, rs1);
    }

    if (rs1 != 0) {
      if (!CSR.write_csr(mi, mmIndex, csr_address, exec_value)){
        return raise_illegal_insn_exception(pc, insn);
      }
    }
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  function execute_csr_RW(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc, uint256 insncode)
  public returns (execute_status) {
    uint32 csr_address = RiscVDecoder.insn_I_uimm(insn);

    bool status = true;
    uint64 csrval = 0;
    uint64 rs1val = 0;

    if (insncode == CSRRW_code) {
      rs1val = CSR.execute_CSRRW(mi, mmIndex, insn);
    } else {
      // insncode == CSRRWI_code
      rs1val = CSR.execute_CSRRWI(mi, mmIndex, insn);
    }

    uint32 rd = RiscVDecoder.insn_rd(insn);

    if (rd != 0){
      (status, csrval) = CSR.read_csr(mi, mmIndex, csr_address);
    }
    if (!status) {
      return raise_illegal_insn_exception(pc, insn);
    }

    if (!CSR.write_csr(mi, mmIndex, csr_address, rs1val)){
      return raise_illegal_insn_exception(pc, insn);
    }
    if (rd != 0){
      mi.write_x(mmIndex, rd, csrval);
    }
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  // JAL (i.e Jump and Link). J_immediate encondes a signed offset in multiples
  // of 2 bytes. The offset is added to pc and JAL stores the address of the jump
  // (pc + 4) to the rd register.
  // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 16
  function execute_jal(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns (execute_status){
    uint64 new_pc = pc + uint64(RiscVDecoder.insn_J_imm(insn));

    if((new_pc & 3) != 0){
      return raise_misaligned_fetch_exception(mi, mmIndex, new_pc);
    }
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if(rd != 0){
      mi.write_x(mmIndex, rd, pc + 4);
    }
    return execute_jump(mi, mmIndex, new_pc);
  }

  // JALR (i.e Jump and Link Register). uses the I-type encoding. The target
  // address is obtained by adding the 12-bit signed I-immediate to the register 
  // rs1, then setting the least-significant bit of the result to zero. 
  // The address of the instruction following the jump (pc+4) is written to register rd
  // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 16
  function execute_jalr(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns (execute_status){
    uint64 new_pc = uint64(int64(mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn)))) & ~uint64(1);

    if((new_pc & 3) != 0){
      return raise_misaligned_fetch_exception(mi, mmIndex, new_pc);
    }
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if(rd != 0){
      mi.write_x(mmIndex, rd, pc + 4);
    }
    return execute_jump(mi, mmIndex, new_pc);
  }

  //AUIPC forms a 32-bit offset from the 20-bit U-immediate, filling in the 
  // lowest 12 bits with zeros, adds this offset to pc and store the result on rd.
  // Reference: riscv-spec-v2.2.pdf -  Page 14
  function execute_auipc(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns (execute_status){
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if(rd != 0){
      mi.write_x(mmIndex, rd, pc + uint64(RiscVDecoder.insn_U_imm(insn)));
    }
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  // LUI (i.e load upper immediate). Is used to build 32-bit constants and uses 
  // the U-type format. LUI places the U-immediate value in the top 20 bits of
  // the destination register rd, filling in the lowest 12 bits with zeros
  // Reference: riscv-spec-v2.2.pdf -  Section 2.5 - page 13
  function execute_lui(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
  public returns (execute_status){
    uint32 rd = RiscVDecoder.insn_rd(insn);

    if(rd != 0){
      mi.write_x(mmIndex, rd, uint64(RiscVDecoder.insn_U_imm(insn)));
    }
    return advance_to_next_insn(mi, mmIndex, pc);
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
  function raise_illegal_insn_exception(uint64 pc, uint32 insn) public returns (execute_status){
    // TO-DO: Raise exception - illegal insn
    return execute_status.retired;
  }

  function advance_to_next_insn(MemoryInteractor mi, uint256 mmIndex, uint64 pc)
  public returns (execute_status){
    mi.memoryWrite(mmIndex, ShadowAddresses.get_pc(), pc + 4);
    //emit Print("advance_to_next", 0);
    return execute_status.retired;
  }

  /// @notice Given a arithmetic funct3 funct7 insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for arithmetic 32 funct3 funct7 field.
  function arithmetic_funct3_funct7(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64, bool) {
    uint32 funct3_funct7 = RiscVDecoder.insn_funct3_funct7(insn);
    if(funct3_funct7 < 0x0181){
      if(funct3_funct7 < 0x0081){
        if(funct3_funct7 < 0x0020){
          if(funct3_funct7 == 0x0000){
            /*funct3_funct7 == 0x0000*/
            // return "ADD";
            return (ArithmeticInstructions.execute_ADD(mi, mmIndex, insn), true);
          }else if(funct3_funct7 == 0x0001){
            /*funct3_funct7 == 0x0001*/
            //return "MUL";
            return (ArithmeticInstructions.execute_MUL(mi, mmIndex, insn), true);
          }
        }else if(funct3_funct7 == 0x0080){
          /*funct3_funct7 == 0x0080*/
          //return "SLL";
          return (ArithmeticInstructions.execute_SLL(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x0020){
          /*funct3_funct7 == 0x0020*/
          //return "SUB";
          return (ArithmeticInstructions.execute_SUB(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 > 0x0081){
        if(funct3_funct7 == 0x0100){
          /*funct3_funct7 == 0x0100*/
          //return "SLT";
          return (ArithmeticInstructions.execute_SLT(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x0180){
          /*funct3_funct7 == 0x0180*/
          //return "SLTU";
          return (ArithmeticInstructions.execute_SLTU(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x0101){
          /*funct3_funct7 == 0x0101*/
          //return "MULHSU";
          return (ArithmeticInstructions.execute_MULHSU(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 == 0x0081){
        /* funct3_funct7 == 0x0081*/
        //return "MULH";
        return (ArithmeticInstructions.execute_MULH(mi, mmIndex, insn), true);
      }
    }else if(funct3_funct7 > 0x0181){
      if(funct3_funct7 < 0x02a0){
        if(funct3_funct7 == 0x0200){
          /*funct3_funct7 == 0x0200*/
          //return "XOR";
          return (ArithmeticInstructions.execute_XOR(mi, mmIndex, insn), true);
        }else if(funct3_funct7 > 0x0201){
          if(funct3_funct7 ==  0x0280){
            /*funct3_funct7 == 0x0280*/
            //return "SRL";
            return (ArithmeticInstructions.execute_SRL(mi, mmIndex, insn), true);
          }else if(funct3_funct7 == 0x0281){
            /*funct3_funct7 == 0x0281*/
            //return "DIVU";
            return (ArithmeticInstructions.execute_DIVU(mi, mmIndex, insn), true);
          }
        }else if(funct3_funct7 == 0x0201){
          /*funct3_funct7 == 0x0201*/
          //return "DIV";
          return (ArithmeticInstructions.execute_DIV(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 > 0x02a0){
        if(funct3_funct7 < 0x0380){
          if(funct3_funct7 == 0x0300){
            /*funct3_funct7 == 0x0300*/
            //return "OR";
            return (ArithmeticInstructions.execute_OR(mi, mmIndex, insn), true);
          }else if(funct3_funct7 == 0x0301){
            /*funct3_funct7 == 0x0301*/
            //return "REM";
            return (ArithmeticInstructions.execute_REM(mi, mmIndex, insn), true);
          }
        }else if(funct3_funct7 == 0x0381){
          /*funct3_funct7 == 0x0381*/
          //return "REMU";
          return (ArithmeticInstructions.execute_REMU(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x380){
          /*funct3_funct7 == 0x0380*/
          //return "AND";
          return (ArithmeticInstructions.execute_AND(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 == 0x02a0){
        /*funct3_funct7 == 0x02a0*/
        //return "SRA";
        return (ArithmeticInstructions.execute_SRA(mi, mmIndex, insn), true);
      }
    }else if(funct3_funct7 == 0x0181){
      /*funct3_funct7 == 0x0181*/
      //return "MULHU";
      return (ArithmeticInstructions.execute_MULHU(mi, mmIndex, insn), true);
    }
    return (0, false);
  }

  /// @notice Given a arithmetic immediate32 funct3 insn, finds the associated func.
  //  Uses binary search for performance.
  //  @param insn for arithmetic immediate32 funct3 field.
  function arithmetic_immediate_32_funct3(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
  public returns (uint64, bool) {
    uint32 funct3 = RiscVDecoder.insn_funct3(insn);
    if(funct3 == 0x0000){
      /*funct3 == 0x0000*/
      //return "ADDIW";
      return (ArithmeticImmediateInstructions.execute_ADDIW(mi, mmIndex, insn), true);
    }else if(funct3 ==  0x0005){
      /*funct3 == 0x0005*/
      return shift_right_immediate_32_group(mi, mmIndex, insn);
    }else if(funct3 == 0x0001){
      /*funct3 == 0x0001*/
      //return "SLLIW";
      return (ArithmeticImmediateInstructions.execute_SLLIW(mi, mmIndex, insn), true);
    }
    return (0, false);
  }

  /// @notice Given a arithmetic immediate funct3 insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for arithmetic immediate funct3 field.
  function arithmetic_immediate_funct3(MemoryInteractor mi, uint256 mmIndex, uint32 insn) 
  public returns (uint64, bool) {
    uint32 funct3 = RiscVDecoder.insn_funct3(insn);
    if(funct3 < 0x0003){
      if(funct3 == 0x0000){
        /*funct3 == 0x0000*/
//        return "ADDI";
        return (ArithmeticImmediateInstructions.execute_ADDI(mi, mmIndex, insn), true);

      }else if(funct3 == 0x0002){
        /*funct3 == 0x0002*/
//        return "SLTI";
        return (ArithmeticImmediateInstructions.execute_SLTI(mi, mmIndex, insn), true);
      }else if(funct3 == 0x0001){
        // Imm[11:6] must be zero for it to be SLLI.
        // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
        // TO-DO: change 0x3F to XLEN - 1
        if(( insn & (0x3F << 26)) != 0){
          return (0, false);
        }
        return (ArithmeticImmediateInstructions.execute_SLLI(mi, mmIndex, insn), true);
      }
    }else if(funct3 > 0x0003){
      if(funct3 < 0x0006){
        if(funct3 == 0x0004){
          /*funct3 == 0x0004*/
//          return "XORI";
          return (ArithmeticImmediateInstructions.execute_XORI(mi, mmIndex, insn), true);
        }else if(funct3 == 0x0005){
          /*funct3 == 0x0005*/
//          return "shift_right_immediate_group";
          return shift_right_immediate_funct6(mi, mmIndex, insn);
        }
      }else if(funct3 == 0x0007){
        /*funct3 == 0x0007*/
//        return "ANDI";
        return (ArithmeticImmediateInstructions.execute_ANDI(mi, mmIndex, insn), true);
      }else if(funct3 == 0x0006){
        /*funct3 == 0x0006*/
//        return "ORI";
        return (ArithmeticImmediateInstructions.execute_ORI(mi, mmIndex, insn), true);
      }
    }else if(funct3 == 0x0003){
      /*funct3 == 0x0003*/
//      return "SLTIU";
        return (ArithmeticImmediateInstructions.execute_SLTIU(mi, mmIndex, insn), true);
    }
    return (0, false);
  }

  /// @notice Given a right immediate funct6 insn, finds the func associated.
  //  Uses binary search for performance.
  //  @param insn for right immediate funct6 field.
  function shift_right_immediate_funct6(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
  public returns (uint64, bool) {
    uint32 funct6 = RiscVDecoder.insn_funct6(insn);
    if(funct6 == 0x0000){
      /*funct6 == 0x0000*/
      //return "SRLI";
      return (ArithmeticImmediateInstructions.execute_SRLI(mi, mmIndex, insn), true);
    }else if(funct6 == 0x0010){
      /*funct6 == 0x0010*/
      //return "SRAI";
      return (ArithmeticImmediateInstructions.execute_SRAI(mi, mmIndex, insn), true);
    }
    //return "illegal insn";
    return (0, false);
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
      return raise_illegal_insn_exception(pc, insn);
    }
    //return "FENCE_I";
    //really do nothing
    return advance_to_next_insn(mi, mmIndex, pc);
  }

  /// @notice Given a branch funct3 group instruction, finds the function
  //  associated with it. Uses binary search for performance.
  //  @param insn for branch funct3 field.
  function branch_funct3(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
  public returns (bool, bool){
    uint32 funct3 = RiscVDecoder.insn_funct3(insn);

    if(funct3 < 0x0005){
      if(funct3 == 0x0000){
        /*funct3 == 0x0000*/
        //return "BEQ";
        return (BranchInstructions.execute_BEQ(mi, mmIndex, insn), true);
      }else if(funct3 == 0x0004){
        /*funct3 == 0x0004*/
        //return "BLT";
        return (BranchInstructions.execute_BLT(mi, mmIndex, insn), true);
      }else if(funct3 == 0x0001){
        /*funct3 == 0x0001*/
        //return "BNE";
        return (BranchInstructions.execute_BNE(mi, mmIndex, insn), true);
      }
    }else if(funct3 > 0x0005){
      if(funct3 == 0x0007){
        /*funct3 == 0x0007*/
        //return "BGEU";
        return (BranchInstructions.execute_BGEU(mi, mmIndex, insn), true);
      }else if(funct3 == 0x0006){
        /*funct3 == 0x0006*/
        //return "BLTU";
        return (BranchInstructions.execute_BLTU(mi, mmIndex, insn), true);
      }
    }else if(funct3 == 0x0005){
      /*funct3==0x0005*/
      //return "BGE";
      return (BranchInstructions.execute_BGE(mi, mmIndex, insn), true);
    }
    return (false, false);
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
        return execute_csr_SC(mi, mmIndex, insn, pc, CSRRS_code);
      }else if(funct3 == 0x0001){
        /*funct3 == 0x0001*/
        //return "CSRRW";
        return execute_csr_RW(mi, mmIndex, insn, pc, CSRRW_code);
      }
    }else if(funct3 > 0x0003){
      if(funct3 == 0x0005){
        /*funct3 == 0x0005*/
        //return "CSRRWI";
        return execute_csr_RW(mi, mmIndex, insn, pc, CSRRWI_code);
      }else if(funct3 == 0x0007){
        /*funct3 == 0x0007*/
        //return "CSRRCI";
        return execute_csr_SCI(mi, mmIndex, insn, pc, CSRRCI_code);
      }else if(funct3 == 0x0006){
        /*funct3 == 0x0006*/
        //return "CSRRSI";
        return execute_csr_SCI(mi, mmIndex, insn, pc, CSRRSI_code);
      }
    }else if(funct3 == 0x0003){
      /*funct3 == 0x0003*/
      //return "CSRRC";
      return execute_csr_SC(mi, mmIndex, insn, pc, CSRRC_code);
    }
    return raise_illegal_insn_exception(pc, insn);
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
    return raise_illegal_insn_exception(pc, insn);
  }

  /// @notice Given a shift right immediate32 funct3 insn, finds the associated func.
  //  Uses binary search for performance.
  //  @param insn for shift right immediate32 funct3 field.
  function shift_right_immediate_32_group(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
  public returns (uint64, bool) {
    uint32 funct7 = RiscVDecoder.insn_funct7(insn);

    if (funct7 == 0x0000){
      /*funct7 == 0x0000*/
      //return "SRLIW";
      return (ArithmeticImmediateInstructions.execute_SRLIW(mi, mmIndex, insn), true);
    } else if (funct7 == 0x0020){
      /*funct7 == 0x0020*/
      //return "SRAIW";
      return (ArithmeticImmediateInstructions.execute_SRAIW(mi, mmIndex, insn), true);
    }
    return (0, false);
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
        raise_illegal_insn_exception(pc, insn);
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
          return raise_illegal_insn_exception(pc, insn);
        }
        return advance_to_next_insn(mi, mmIndex, pc);
      }else if(insn == 0x30200073){
        /*insn == 0x30200073*/
        //return "MRET";
        if (!EnvTrapIntInstructions.execute_MRET(mi, mmIndex, insn, pc)){
        return raise_illegal_insn_exception(pc, insn);
      }
        return execute_status.retired;
      }
    }else if(insn == 0x10200073){
      /*insn = 0x10200073*/
      //return "SRET";
      if (!EnvTrapIntInstructions.execute_SRET(mi, mmIndex, insn, pc)){
        return raise_illegal_insn_exception(pc, insn);
      }
      return execute_status.retired;
   }
    return raise_illegal_insn_exception(pc, insn);
  }

  /// @notice Given an arithmetic32 funct3 funct7 insn, finds the associated func.
  //  Uses binary search for performance.
  //  @param insn for arithmetic32 funct3 funct7 field.
  function arithmetic_32_funct3_funct7(MemoryInteractor mi, uint256 mmIndex, uint32 insn) 
  public returns (uint64, bool) {

    uint32 funct3_funct7 = RiscVDecoder.insn_funct3_funct7(insn);

    if(funct3_funct7 < 0x0280){
      if(funct3_funct7 < 0x0020){
        if(funct3_funct7 == 0x0000){
          /*funct3_funct7 == 0x0000*/
          //return "ADDW";
          return (ArithmeticInstructions.execute_ADDW(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x0001){
          /*funct3_funct7 == 0x0001*/
          //return "MULW";
          return (ArithmeticInstructions.execute_MULW(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 > 0x0020){
        if(funct3_funct7 == 0x0080){
          /*funct3_funct7 == 0x0080*/
          //return "SLLW";
          return (ArithmeticInstructions.execute_SLLW(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x0201){
          /*funct3_funct7 == 0x0201*/
          //return "DIVUW";
          return (ArithmeticInstructions.execute_DIVUW(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 == 0x0020){
        /*funct3_funct7 == 0x0020*/
        //return "SUBW";
        return (ArithmeticInstructions.execute_SUBW(mi, mmIndex, insn), true);
      }
    }else if(funct3_funct7 > 0x0280){
      if(funct3_funct7 < 0x0301){
        if(funct3_funct7 == 0x0281){
          /*funct3_funct7 == 0x0281*/
          //return "DIVUW";
          return (ArithmeticInstructions.execute_DIVUW(mi, mmIndex, insn), true);
        }else if(funct3_funct7 == 0x02a0){
          /*funct3_funct7 == 0x02a0*/
          //return "SRAW";
          return (ArithmeticInstructions.execute_SRAW(mi, mmIndex, insn), true);
        }
      }else if(funct3_funct7 == 0x0381){
        /*funct3_funct7 == 0x0381*/
        //return "REMUW";
        return (ArithmeticInstructions.execute_REMUW(mi, mmIndex, insn), true);
      }else if(funct3_funct7 == 0x0301){
        /*funct3_funct7 == 0x0301*/
        //return "REMW";
        return (ArithmeticInstructions.execute_REMW(mi, mmIndex, insn), true);
      }
    }else if(funct3_funct7 == 0x0280) {
      /*funct3_funct7 == 0x0280*/
      //return "SRLW";
      return (ArithmeticInstructions.execute_SRLW(mi, mmIndex, insn), true);
    }
    //return "illegal insn";
    return (0, false);
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
    return raise_illegal_insn_exception(pc, insn);
  }

//  @param insn for atomic funct3_funct5 field
  function atomic_funct3_funct5(MemoryInteractor mi, uint256 mmIndex, uint32 insn, uint64 pc)
 public returns (execute_status){
    uint32 funct3_funct5 = RiscVDecoder.insn_funct3_funct5(insn);

    // TO-DO: transform in binary search for performance
    if (funct3_funct5 == 0x42) {
//      return execute_LR_W;
    } else if (funct3_funct5 == 0x43) {
//      return execute_SC_W;
    } else if (funct3_funct5 == 0x41) {
        if (AtomicInstructions.execute_AMOSWAP_W(mi, mmIndex, pc, insn)){
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return execute_status.retired;
        }

    } else if (funct3_funct5 == 0x40) {
        if (AtomicInstructions.execute_AMOADD_W(mi, mmIndex, pc, insn)) {
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return execute_status.retired;
        }

//      return execute_AMOADD_W;
    } else if (funct3_funct5 == 0x44) {
        if (AtomicInstructions.execute_AMOXOR_W(mi, mmIndex, pc, insn) ){
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return execute_status.retired;
        }

//      return execute_AMOXOR_W;
    } else if (funct3_funct5 == 0x4c) {
        if (AtomicInstructions.execute_AMOAND_W(mi, mmIndex, pc, insn) ){
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return execute_status.retired;
        }

//      return execute_AMOAND_W;
    } else if (funct3_funct5 == 0x48) {
        if (AtomicInstructions.execute_AMOOR_W(mi, mmIndex, pc, insn) ){
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return execute_status.retired;
        }

//      return execute_AMOOR_W;
    } else if (funct3_funct5 == 0x50) {
        if (AtomicInstructions.execute_AMOMIN_W(mi, mmIndex, pc, insn)){
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return execute_status.retired;
        }

//      return execute_AMOMIN_W;
    } else if (funct3_funct5 == 0x54) {
        if (AtomicInstructions.execute_AMOMAX_W(mi, mmIndex, pc, insn) ){
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return execute_status.retired;
        }

//      return execute_AMOMAX_W;
    } else if (funct3_funct5 == 0x58) {
        if (AtomicInstructions.execute_AMOMINU_W(mi, mmIndex, pc, insn)) {
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return execute_status.retired;
        }

//      return execute_AMOMINU_W;
    } else if (funct3_funct5 == 0x5c) {
        if (AtomicInstructions.execute_AMOMAXU_W(mi, mmIndex, pc, insn)) {
          return advance_to_next_insn(mi, mmIndex, pc);
        } else {
          return execute_status.retired;
        }
//      return execute_AMOMAXU_W;
    } else if (funct3_funct5 == 0x62) {
//      return execute_LR_D;
    } else if (funct3_funct5 == 0x63) {
//      return execute_SC_D;
    } else if (funct3_funct5 == 0x61) {
//      return execute_AMOSWAP_D;;
    } else if (funct3_funct5 == 0x60) {
//      return execute_AMOADD_D;
    } else if (funct3_funct5 == 0x64) {
//      return execute_AMOXOR_D;
    } else if (funct3_funct5 == 0x6c) {
//      return execute_AMOAND_D;
    } else if (funct3_funct5 == 0x68) {
//      return execute_AMOOR_D;
    } else if (funct3_funct5 == 0x70) {
//      return execute_AMOMIN_D;
    } else if (funct3_funct5 == 0x74) {
//      return execute_AMOMAX_D;
    } else if (funct3_funct5 == 0x78) {
//      return execute_AMOMINU_D;
    } else if (funct3_funct5 == 0x7c) {
//      return execute_AMOMAXU_D;
    }
    return raise_illegal_insn_exception(pc, insn);
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
        return execute_auipc(mi, mmIndex, insn, pc);
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
          return execute_lui(mi, mmIndex, insn, pc);
        }
      }else if (opcode > 0x0063){
        if(opcode == 0x0067){
          /*opcode == 0x0067*/
          //return "JALR";
          return execute_jalr(mi, mmIndex, insn, pc);
        }else if(opcode == 0x0073){
          /*opcode == 0x0073*/
          return csr_env_trap_int_mm_funct3(mi, mmIndex, insn, pc);
        }else if(opcode == 0x006f){
          /*opcode == 0x006f*/
          //return "JAL";
          return execute_jal(mi, mmIndex, insn, pc);
        }
      }else if (opcode == 0x0063){
        /*opcode == 0x0063*/
        //return "branch_group";
        return execute_branch(mi, mmIndex, insn, pc);
      }
    }else if(opcode == 0x002f){
      /*opcode == 0x002f*/
      //return "atomic_group";
      return execute_status.retired;
    }
    return raise_illegal_insn_exception(pc, insn);
  }

  enum execute_status {
    illegal, // Exception was raised
    retired // Instruction retired - having raised or not an exception
  }
}
