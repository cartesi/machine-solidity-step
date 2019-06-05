/// @title ArithmeticImmediateInstructions
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";
import "../../contracts/RiscVConstants.sol";

library ArithmeticImmediateInstructions {

  function get_rs1_imm(MemoryInteractor mi, uint256 mmIndex, uint32 insn) internal 
  returns(uint64 rs1, int32 imm) {
    rs1 = mi.read_x(mmIndex, RiscVDecoder.insn_rs1(insn));
    imm = RiscVDecoder.insn_I_imm(insn);
  }

  // ADDI adds the sign extended 12 bits immediate to rs1. Overflow is ignored.
  // Reference: riscv-spec-v2.2.pdf -  Page 13
  function execute_ADDI(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    int64 val = int64(rs1) + int64(imm);
    return uint64(val);
  }

  // ADDIW adds the sign extended 12 bits immediate to rs1 and produces to correct
  // sign extension for 32 bits at rd. Overflow is ignored and the result is the
  // low 32 bits of the result sign extended to 64 bits.
  // Reference: riscv-spec-v2.2.pdf -  Page 30
  function execute_ADDIW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    return uint64(int32(rs1) + imm);
  }

  // SLLIW is analogous to SLLI but operate on 32 bit values.
  // The amount of shifts are enconded on the lower 5 bits of I-imm.
  // Reference: riscv-spec-v2.2.pdf - Section 4.2 -  Page 30
  function execute_SLLIW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    int32 rs1w = int32(rs1) << (imm & 0x1F);
    return uint64(rs1w);
  }

  // ORI performs logical Or bitwise operation on register rs1 and the sign-extended
  // 12 bit immediate. It places the result in rd.
  // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
  function execute_ORI(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    return rs1 | uint64(imm);
  }

  // SLLI performs the logical left shift. The operand to be shifted is in rs1
  // and the amount of shifts are encoded on the lower 6 bits of I-imm.(RV64)
  // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
  function execute_SLLI(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns(uint64){
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    return rs1 << (imm & 0x3F);
  }

  // SLRI instructions is a logical shift right instruction. The variable to be 
  // shift is in rs1 and the amount of shift operations is encoded in the lower
  // 6 bits of the I-immediate field.
  function execute_SRLI(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns(uint64){
    // Get imm's lower 6 bits
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    int32 shiftAmount = imm & int32(RiscVConstants.XLEN() - 1);

    return rs1 >> shiftAmount;
  }

  // SRLIW instructions operates on a 32bit value and produce a signed results.
  // The variable to be shift is in rs1 and the amount of shift operations is 
  // encoded in the lower 6 bits of the I-immediate field.
  function execute_SRLIW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns(uint64){
    // Get imm's lower 6 bits
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    int32 rs1w = int32(uint32(rs1) >> (imm & 0x1F));
    return uint64(rs1w);
  }

  // SLTI - Set less than immediate. Places value 1 in rd if rs1 is less than
  // the signed extended imm when both are signed. Else 0 is written.
  // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 13.
  function execute_SLTI(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    return (int64(rs1) < int64(imm))? 1 : 0;
  }

  // SLTIU is analogous to SLLTI but treats imm as unsigned.
  // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
  function execute_SLTIU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (uint64){
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    return (rs1 < uint64(imm))? 1 : 0;
  }
  // SRAIW instructions operates on a 32bit value and produce a signed results.
  // The variable to be shift is in rs1 and the amount of shift operations is 
  // encoded in the lower 6 bits of the I-immediate field.
  function execute_SRAIW(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns(uint64){
    // Get imm's lower 6 bits
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    int32 rs1w = int32(rs1) >> (imm & 0x1F);
    return uint64(rs1w);
  }

  // TO-DO: make sure that >> is now arithmetic shift and not logical shift
  // SRAI instruction is analogous to SRAIW but for RV64I
  function execute_SRAI(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns(uint64){
    // Get imm's lower 6 bits
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    return uint64(int64(rs1) >> (int64(imm) & int64((RiscVConstants.XLEN() - 1))));
  }

  // XORI instructions performs XOR operation on register rs1 and hhe sign extended
  // 12 bit immediate, placing result in rd.
  function execute_XORI(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns(uint64){
    // Get imm's lower 6 bits
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    return rs1 ^ uint64(imm);
  }

  // ANDI instructions performs AND operation on register rs1 and hhe sign extended
  // 12 bit immediate, placing result in rd.
  function execute_ANDI(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns(uint64){
    // Get imm's lower 6 bits
    (uint64 rs1, int32 imm) = get_rs1_imm(mi, mmIndex, insn);
    //return (rs1 & uint64(imm) != 0)? 1 : 0;
    return rs1 & uint64(imm);
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
      return (execute_ADDIW(mi, mmIndex, insn), true);
    }else if(funct3 ==  0x0005){
      /*funct3 == 0x0005*/
      return shift_right_immediate_32_group(mi, mmIndex, insn);
    }else if(funct3 == 0x0001){
      /*funct3 == 0x0001*/
      //return "SLLIW";
      return (execute_SLLIW(mi, mmIndex, insn), true);
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
        return (execute_ADDI(mi, mmIndex, insn), true);

      }else if(funct3 == 0x0002){
        /*funct3 == 0x0002*/
//        return "SLTI";
        return (execute_SLTI(mi, mmIndex, insn), true);
      }else if(funct3 == 0x0001){
        // Imm[11:6] must be zero for it to be SLLI.
        // Reference: riscv-spec-v2.2.pdf - Section 2.4 -  Page 14
        // TO-DO: change 0x3F to XLEN - 1
        if(( insn & (0x3F << 26)) != 0){
          return (0, false);
        }
        return (execute_SLLI(mi, mmIndex, insn), true);
      }
    }else if(funct3 > 0x0003){
      if(funct3 < 0x0006){
        if(funct3 == 0x0004){
          /*funct3 == 0x0004*/
//          return "XORI";
          return (execute_XORI(mi, mmIndex, insn), true);
        }else if(funct3 == 0x0005){
          /*funct3 == 0x0005*/
//          return "shift_right_immediate_group";
          return shift_right_immediate_funct6(mi, mmIndex, insn);
        }
      }else if(funct3 == 0x0007){
        /*funct3 == 0x0007*/
//        return "ANDI";
        return (execute_ANDI(mi, mmIndex, insn), true);
      }else if(funct3 == 0x0006){
        /*funct3 == 0x0006*/
//        return "ORI";
        return (execute_ORI(mi, mmIndex, insn), true);
      }
    }else if(funct3 == 0x0003){
      /*funct3 == 0x0003*/
//      return "SLTIU";
        return (execute_SLTIU(mi, mmIndex, insn), true);
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
      return (execute_SRLI(mi, mmIndex, insn), true);
    }else if(funct6 == 0x0010){
      /*funct6 == 0x0010*/
      //return "SRAI";
      return (execute_SRAI(mi, mmIndex, insn), true);
    }
    //return "illegal insn";
    return (0, false);
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
      return (execute_SRLIW(mi, mmIndex, insn), true);
    } else if (funct7 == 0x0020){
      /*funct7 == 0x0020*/
      //return "SRAIW";
      return (execute_SRAIW(mi, mmIndex, insn), true);
    }
    return (0, false);
  }


}
