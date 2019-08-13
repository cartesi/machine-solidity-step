// Copyright 2019 Cartesi Pte. Ltd.

// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title MemoryInteractor.sol
pragma solidity ^0.5.0;

import "../contracts/ShadowAddresses.sol";
import "../contracts/HTIF.sol";
import "../contracts/CLINT.sol";
import "./RiscVConstants.sol";
import "./lib/BitsManipulationLibrary.sol";


contract mmInterface {
    function read(uint256 _index, uint64 _address) external returns (bytes8);
    function write(uint256 _index, uint64 _address, bytes8 _value) external;
    function finishReplayPhase(uint256 _index) external;
}


/// @title MemoryInteractor
/// @author Felipe Argento
/// @notice Bridge between Memory Manager and Step
/// @dev Every read performed by mi.memoryRead or mi.write should be followed by an
/// @dev endianess swap from little endian to big endian. This is the case because
/// @dev EVM is big endian but RiscV is little endian.
/// @dev Reference: riscv-spec-v2.2.pdf - Preface to Version 2.0
/// @dev Reference: Ethereum yellowpaper - Version 69351d5
/// @dev    Appendix H. Virtual Machine Specification
contract MemoryInteractor {
    mmInterface mm;

    constructor(address mmAddress) public {
        mm = mmInterface(mmAddress);
    }

    // Change phase
    function finishReplayPhase(uint256 mmindex) public {
        mm.finishReplayPhase(mmindex);
    }

    // Reads
    function readX(uint256 mmindex, uint64 registerIndex) public returns (uint64) {
        return memoryRead(mmindex, registerIndex * 8);
    }

    function readClintMtimecmp(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, CLINT.getClintMtimecmp());
    }

    function readHtifFromhost(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, HTIF.getHtifFromHostAddr());
    }

    function readHtifTohost(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, HTIF.getHtifToHostAddr());
    }

    function readMie(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMie());
    }

    function readMcause(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMcause());
    }

    function readMinstret(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMinstret());
    }

    function readMcycle(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMcycle());
    }

    function readMcounteren(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMcounteren());
    }

    function readMepc(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMepc());
    }

    function readMip(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMip());
    }

    function readMtval(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMtval());
    }

    function readMvendorid(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMvendorid());
    }

    function readMarchid(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMarchid());
    }

    function readMimpid(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMimpid());
    }

    function readMscratch(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMscratch());
    }

    function readSatp(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getSatp());
    }

    function readScause(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getScause());
    }

    function readSepc(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getSepc());
    }

    function readScounteren(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getScounteren());
    }

    function readStval(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getStval());
    }

    function readMideleg(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMideleg());
    }

    function readMedeleg(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMedeleg());
    }

    function readMtvec(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMtvec());
    }

    function readIlrsc(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getIlrsc());
    }

    function readPc(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getPc());
    }

    function readSscratch(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getSscratch());
    }

    function readStvec(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getStvec());
    }

    function readMstatus(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMstatus());
    }

    function readMisa(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getMisa());
    }

    function readIflags(uint256 mmindex) public returns (uint64) {
        return memoryRead(mmindex, ShadowAddresses.getIflags());
    }

    function readIflagsPrv(uint256 mmindex) public returns (uint64) {
        return (memoryRead(mmindex, ShadowAddresses.getIflags()) >> 2) & 3;
    }

    function readMemory(uint256 mmindex, uint64 paddr, uint64 wordSize) public returns (uint64) {
        // get relative address from unaligned paddr
        uint64 closestStartAddr = paddr & uint64(~7);
        uint64 relAddr = paddr - closestStartAddr;

        // value just like its on MM, without endianess swap
        uint64 val = pureMemoryRead(mmindex, closestStartAddr);

        // mask to clean a piece of the value that was on memory
        uint64 valueMask = BitsManipulationLibrary.uint64SwapEndian(((uint64(2) ** wordSize) - 1) << relAddr*8);
        val = BitsManipulationLibrary.uint64SwapEndian(val & valueMask) >> relAddr*8;
        return val;
    }

    // Sets
    function setPriv(uint256 mmindex, uint64 newPriv) public {
        writeIflagsPrv(mmindex, newPriv);
        writeIlrsc(mmindex, uint64(-1)); // invalidate reserved address
    }

    function setIflagsI(uint256 mmindex, bool idle) public {
        uint64 iflags = readIflags(mmindex);

        if (idle) {
            iflags = (iflags | RiscVConstants.getIflagsIMask());
        } else {
            iflags = (iflags & ~RiscVConstants.getIflagsIMask());
        }

        memoryWrite(mmindex, ShadowAddresses.getIflags(), iflags);
    }

    function setMip(uint256 mmindex, uint64 mask) public {
        uint64 mip = readMip(mmindex);
        mip |= mask;

        writeMip(mmindex, mip);

        setIflagsI(mmindex, false);
    }

    function resetMip(uint256 mmindex, uint64 mask) public {
        uint64 mip = readMip(mmindex);
        mip &= ~mask;
        writeMip(mmindex, mip);
    }

    // Writes
    function writeMie(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMie(), value);
    }

    function writeStvec(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getStvec(), value);
    }

    function writeSscratch(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getSscratch(), value);
    }

    function writeMip(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMip(), value);
    }

    function writeSatp(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getSatp(), value);
    }

    function writeMedeleg(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMedeleg(), value);
    }

    function writeMideleg(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMideleg(), value);
    }

    function writeMtvec(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMtvec(), value);
    }

    function writeMcounteren(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMcounteren(), value);
    }

    function writeMcycle(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMcycle(), value);
    }

    function writeMinstret(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMinstret(), value);
    }

    function writeMscratch(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMscratch(), value);
    }

    function writeScounteren(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getScounteren(), value);
    }

    function writeScause(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getScause(), value);
    }

    function writeSepc(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getSepc(), value);
    }

    function writeStval(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getStval(), value);
    }

    function writeMstatus(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMstatus(), value);
    }

    function writeMcause(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMcause(), value);
    }

    function writeMepc(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMepc(), value);
    }

    function writeMtval(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getMtval(), value);
    }

    function writePc(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getPc(), value);
    }

    function writeIlrsc(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, ShadowAddresses.getIlrsc(), value);
    }

    function writeClintMtimecmp(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, CLINT.getClintMtimecmp(), value);
    }

    function writeHtifFromhost(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, HTIF.getHtifFromHostAddr(), value);
    }

    function writeHtifTohost(uint256 mmindex, uint64 value) public {
        memoryWrite(mmindex, HTIF.getHtifToHostAddr(), value);
    }

    function setIflagsH(uint256 mmindex, bool halt) public {
        uint64 iflags = readIflags(mmindex);

        if (halt) {
            iflags = (iflags | RiscVConstants.getIflagsHMask());
        } else {
            iflags = (iflags & ~RiscVConstants.getIflagsHMask());
        }

        memoryWrite(mmindex, ShadowAddresses.getIflags(), iflags);
    }

    function writeIflagsPrv(uint256 mmindex, uint64 newPriv) public {
        uint64 iflags = readIflags(mmindex);

        // Clears bits 3 and 2 of iflags and use or to set new value
        iflags = (iflags & (~RiscVConstants.getIflagsPrvMask())) | (newPriv << RiscVConstants.getIflagsPrvShift());

        memoryWrite(mmindex, ShadowAddresses.getIflags(), iflags);
    }

    function writeMemory(
        uint256 mmindex,
        uint64 paddr,
        uint64 value,
        uint64 wordSize
    ) public
    {
        uint64 numberOfBytes = wordSize / 8;

        if (numberOfBytes == 8) {
            memoryWrite(mmindex, paddr, value);
        } else {
            // get relative address from unaligned paddr
            uint64 closestStartAddr = paddr & uint64(~7);
            uint64 relAddr = paddr - closestStartAddr;

            // oldvalue just like its on MM, without endianess swap
            uint64 oldVal = pureMemoryRead(mmindex, closestStartAddr);

            // Mask to clean a piece of the value that was on memory
            uint64 valueMask = BitsManipulationLibrary.uint64SwapEndian(((uint64(2) ** wordSize) - 1) << relAddr*8);

            // value is big endian, need to swap before further operation
            uint64 valueSwap = BitsManipulationLibrary.uint64SwapEndian(value & ((uint64(2) ** wordSize) - 1));

            uint64 newvalue = ((oldVal & ~valueMask) | (valueSwap >> relAddr*8));

            newvalue = BitsManipulationLibrary.uint64SwapEndian(newvalue);
            memoryWrite(mmindex, closestStartAddr, newvalue);
        }
    }

    function writeX(uint256 mmindex, uint64 registerindex, uint64 value) public {
        memoryWrite(mmindex, registerindex * 8, value);
    }

    // Internal functions
    function memoryRead(uint256 index, uint64 readAddress) public returns (uint64) {
        return BitsManipulationLibrary.uint64SwapEndian(
            uint64(mm.read(index, readAddress))
        );
    }

    function memoryWrite(uint256 index, uint64 writeAddress, uint64 value) public {
        bytes8 bytesvalue = bytes8(BitsManipulationLibrary.uint64SwapEndian(value));
        mm.write(index, writeAddress, bytesvalue);
    }

    // Memory Write without endianess swap
    function pureMemoryWrite(uint256 index, uint64 writeAddress, uint64 value) internal {
        mm.write(index, writeAddress, bytes8(value));
    }

    // Memory Read without endianess swap
    function pureMemoryRead(uint256 index, uint64 readAddress) internal returns (uint64) {
        return uint64(mm.read(index, readAddress));
    }

}

