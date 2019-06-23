/// @title BranchInstructions
pragma solidity ^0.5.0;

import "../../contracts/MemoryInteractor.sol";
import "../../contracts/RiscVDecoder.sol";


library BranchInstructions {

    function getRs1Rs2(MemoryInteractor mi, uint256 mmIndex, uint32 insn) internal
    returns(uint64 rs1, uint64 rs2)
    {
        rs1 = mi.readX(mmIndex, RiscVDecoder.insnRs1(insn));
        rs2 = mi.readX(mmIndex, RiscVDecoder.insnRs2(insn));
    }

    function executeBEQ(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, mmIndex, insn);
        return rs1 == rs2;
    }

    function executeBNE(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, mmIndex, insn);
        return rs1 != rs2;
    }

    function executeBLT(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, mmIndex, insn);
        return int64(rs1) < int64(rs2);
    }

    function executeBGE(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, mmIndex, insn);
        return int64(rs1) >= int64(rs2);
    }

    function executeBLTU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, mmIndex, insn);
        return rs1 < rs2;
    }

    function executeBGEU(MemoryInteractor mi, uint256 mmIndex, uint32 insn) public returns (bool) {
        (uint64 rs1, uint64 rs2) = getRs1Rs2(mi, mmIndex, insn);
        return rs1 >= rs2;
    }

    /// @notice Given a branch funct3 group instruction, finds the function
    //  associated with it. Uses binary search for performance.
    //  @param insn for branch funct3 field.
    function branchFunct3(MemoryInteractor mi, uint256 mmIndex, uint32 insn)
    public returns (bool, bool)
    {
        uint32 funct3 = RiscVDecoder.insnFunct3(insn);

        if (funct3 < 0x0005) {
            if (funct3 == 0x0000) {
                /*funct3 == 0x0000*/
                return (executeBEQ(mi, mmIndex, insn), true);
            } else if (funct3 == 0x0004) {
                /*funct3 == 0x0004*/
                return (executeBLT(mi, mmIndex, insn), true);
            } else if (funct3 == 0x0001) {
                /*funct3 == 0x0001*/
                return (executeBNE(mi, mmIndex, insn), true);
            }
        } else if (funct3 > 0x0005) {
            if (funct3 == 0x0007) {
                /*funct3 == 0x0007*/
                return (executeBGEU(mi, mmIndex, insn), true);
            } else if (funct3 == 0x0006) {
                /*funct3 == 0x0006*/
                return (executeBLTU(mi, mmIndex, insn), true);
            }
        } else if (funct3 == 0x0005) {
            /*funct3==0x0005*/
            return (executeBGE(mi, mmIndex, insn), true);
        }
        return (false, false);
    }
}
