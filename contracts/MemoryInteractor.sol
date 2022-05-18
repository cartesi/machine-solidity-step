// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title MemoryInteractor.sol
pragma solidity ^0.7.0;

import "./ShadowAddresses.sol";
import "./HTIF.sol";
import "./CLINT.sol";
import "./RiscVConstants.sol";
import "@cartesi/util/contracts/BitsManipulationLibrary.sol";

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

    uint256 rwIndex; // read write index
    uint64[] rwPositions; // read write positions
    bytes8[] rwValues; // read write values
    bool[] isRead; // true if access is read, false if its write

    function initializeMemory(
        uint64[] memory _rwPositions,
        bytes8[] memory _rwValues,
        bool[] memory _isRead
    ) virtual public
    {
        require(_rwPositions.length == _rwValues.length, "Read/write arrays are not the same size");
        require(_rwPositions.length == _isRead.length, "Read/write arrays are not the same size");
        rwIndex = 0;
        rwPositions = _rwPositions;
        rwValues = _rwValues;
        isRead = _isRead;
    }

    function getRWIndex() public view returns (uint256) {
        return rwIndex;
    }
    // Reads
    function readX(uint64 registerIndex) public returns (uint64) {
        return memoryRead(registerIndex * 8);
    }

    function readClintMtimecmp() public returns (uint64) {
        return memoryRead(CLINT.getClintMtimecmp());
    }

    function readHtifFromhost() public returns (uint64) {
        return memoryRead(HTIF.getHtifFromHostAddr());
    }

    function readHtifTohost() public returns (uint64) {
        return memoryRead(HTIF.getHtifToHostAddr());
    }

    function readHtifIHalt() public returns (uint64) {
        return memoryRead(HTIF.getHtifIHaltAddr());
    }

    function readHtifIConsole() public returns (uint64) {
        return memoryRead(HTIF.getHtifIConsoleAddr());
    }    

    function readHtifIYield() public returns (uint64) {
        return memoryRead(HTIF.getHtifIYieldAddr());
    }

    function readMie() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMie());
    }

    function readMcause() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMcause());
    }

    function readMinstret() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMinstret());
    }

    function readMcycle() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMcycle());
    }

    function readMcounteren() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMcounteren());
    }

    function readMepc() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMepc());
    }

    function readMip() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMip());
    }

    function readMtval() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMtval());
    }

    function readMvendorid() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMvendorid());
    }

    function readMarchid() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMarchid());
    }

    function readMimpid() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMimpid());
    }

    function readMscratch() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMscratch());
    }

    function readSatp() public returns (uint64) {
        return memoryRead(ShadowAddresses.getSatp());
    }

    function readScause() public returns (uint64) {
        return memoryRead(ShadowAddresses.getScause());
    }

    function readSepc() public returns (uint64) {
        return memoryRead(ShadowAddresses.getSepc());
    }

    function readScounteren() public returns (uint64) {
        return memoryRead(ShadowAddresses.getScounteren());
    }

    function readStval() public returns (uint64) {
        return memoryRead(ShadowAddresses.getStval());
    }

    function readMideleg() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMideleg());
    }

    function readMedeleg() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMedeleg());
    }

    function readMtvec() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMtvec());
    }

    function readIlrsc() public returns (uint64) {
        return memoryRead(ShadowAddresses.getIlrsc());
    }

    function readPc() public returns (uint64) {
        return memoryRead(ShadowAddresses.getPc());
    }

    function readSscratch() public returns (uint64) {
        return memoryRead(ShadowAddresses.getSscratch());
    }

    function readStvec() public returns (uint64) {
        return memoryRead(ShadowAddresses.getStvec());
    }

    function readMstatus() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMstatus());
    }

    function readMisa() public returns (uint64) {
        return memoryRead(ShadowAddresses.getMisa());
    }

    function readIflags() public returns (uint64) {
        return memoryRead(ShadowAddresses.getIflags());
    }

    function readIflagsPrv() public returns (uint64) {
        return (memoryRead(ShadowAddresses.getIflags()) & RiscVConstants.getIflagsPrvMask()) >> RiscVConstants.getIflagsPrvShift();
    }

    function readIflagsH() public returns (uint64) {
        return (memoryRead(ShadowAddresses.getIflags()) & RiscVConstants.getIflagsHMask()) >> RiscVConstants.getIflagsHShift();
    }

    function readIflagsY() public returns (uint64) {
        return (memoryRead(ShadowAddresses.getIflags()) & RiscVConstants.getIflagsYMask()) >> RiscVConstants.getIflagsYShift();
    }

    function readIflagsX() public returns (uint64) {
        return (memoryRead(ShadowAddresses.getIflags()) & RiscVConstants.getIflagsXMask()) >> RiscVConstants.getIflagsXShift();
    }

    function readMemory(uint64 paddr, uint64 wordSize) public returns (uint64) {
        // get relative address from unaligned paddr
        uint64 closestStartAddr = paddr & uint64(~7);
        uint64 relAddr = paddr - closestStartAddr;

        // value just like its on MM, without endianess swap
        uint64 val = pureMemoryRead(closestStartAddr);

        // mask to clean a piece of the value that was on memory
        uint64 valueMask = BitsManipulationLibrary.uint64SwapEndian(((uint64(2) ** wordSize) - 1) << relAddr*8);
        val = BitsManipulationLibrary.uint64SwapEndian(val & valueMask) >> relAddr*8;
        return val;
    }

    // Sets
    function setPriv(uint64 newPriv) public {
        writeIflagsPrv(newPriv);
        writeIlrsc(uint64(-1)); // invalidate reserved address
    }

    function setMip(uint64 mask) public {
        uint64 mip = readMip();
        mip |= mask;
        writeMip(mip);
    }

    function resetMip(uint64 mask) public {
        uint64 mip = readMip();
        mip &= ~mask;
        writeMip(mip);
    }

    // Writes
    function writeMie(uint64 value) public {
        memoryWrite(ShadowAddresses.getMie(), value);
    }

    function writeStvec(uint64 value) public {
        memoryWrite(ShadowAddresses.getStvec(), value);
    }

    function writeSscratch(uint64 value) public {
        memoryWrite(ShadowAddresses.getSscratch(), value);
    }

    function writeMip(uint64 value) public {
        memoryWrite(ShadowAddresses.getMip(), value);
    }

    function writeSatp(uint64 value) public {
        memoryWrite(ShadowAddresses.getSatp(), value);
    }

    function writeMedeleg(uint64 value) public {
        memoryWrite(ShadowAddresses.getMedeleg(), value);
    }

    function writeMideleg(uint64 value) public {
        memoryWrite(ShadowAddresses.getMideleg(), value);
    }

    function writeMtvec(uint64 value) public {
        memoryWrite(ShadowAddresses.getMtvec(), value);
    }

    function writeMcounteren(uint64 value) public {
        memoryWrite(ShadowAddresses.getMcounteren(), value);
    }

    function writeMcycle(uint64 value) public {
        memoryWrite(ShadowAddresses.getMcycle(), value);
    }

    function writeMinstret(uint64 value) public {
        memoryWrite(ShadowAddresses.getMinstret(), value);
    }

    function writeMscratch(uint64 value) public {
        memoryWrite(ShadowAddresses.getMscratch(), value);
    }

    function writeScounteren(uint64 value) public {
        memoryWrite(ShadowAddresses.getScounteren(), value);
    }

    function writeScause(uint64 value) public {
        memoryWrite(ShadowAddresses.getScause(), value);
    }

    function writeSepc(uint64 value) public {
        memoryWrite(ShadowAddresses.getSepc(), value);
    }

    function writeStval(uint64 value) public {
        memoryWrite(ShadowAddresses.getStval(), value);
    }

    function writeMstatus(uint64 value) public {
        memoryWrite(ShadowAddresses.getMstatus(), value);
    }

    function writeMcause(uint64 value) public {
        memoryWrite(ShadowAddresses.getMcause(), value);
    }

    function writeMepc(uint64 value) public {
        memoryWrite(ShadowAddresses.getMepc(), value);
    }

    function writeMtval(uint64 value) public {
        memoryWrite(ShadowAddresses.getMtval(), value);
    }

    function writePc(uint64 value) public {
        memoryWrite(ShadowAddresses.getPc(), value);
    }

    function writeIlrsc(uint64 value) public {
        memoryWrite(ShadowAddresses.getIlrsc(), value);
    }

    function writeClintMtimecmp(uint64 value) public {
        memoryWrite(CLINT.getClintMtimecmp(), value);
    }

    function writeHtifFromhost(uint64 value) public {
        memoryWrite(HTIF.getHtifFromHostAddr(), value);
    }

    function writeHtifTohost(uint64 value) public {
        memoryWrite(HTIF.getHtifToHostAddr(), value);
    }

    function setIflagsH(bool halt) public {
        uint64 iflags = readIflags();

        if (halt) {
            iflags = (iflags | RiscVConstants.getIflagsHMask());
        } else {
            iflags = (iflags & ~RiscVConstants.getIflagsHMask());
        }

        memoryWrite(ShadowAddresses.getIflags(), iflags);
    }

    function setIflagsY(bool isManualYield) public {
        uint64 iflags = readIflags();

        if (isManualYield) {
            iflags = (iflags | RiscVConstants.getIflagsYMask());
        } else {
            iflags = (iflags & ~RiscVConstants.getIflagsYMask());
        }

        memoryWrite(ShadowAddresses.getIflags(), iflags);
    }

    function setIflagsX(bool isAutomaticYield) public {
        uint64 iflags = readIflags();

        if (isAutomaticYield) {
            iflags = (iflags | RiscVConstants.getIflagsXMask());
        } else {
            iflags = (iflags & ~RiscVConstants.getIflagsXMask());
        }

        memoryWrite(ShadowAddresses.getIflags(), iflags);
    }

    function writeIflagsPrv(uint64 newPriv) public {
        uint64 iflags = readIflags();

        // Clears bits 3 and 2 of iflags and use or to set new value
        iflags = (iflags & (~RiscVConstants.getIflagsPrvMask())) | (newPriv << RiscVConstants.getIflagsPrvShift());

        memoryWrite(ShadowAddresses.getIflags(), iflags);
    }

    function writeMemory(
        uint64 paddr,
        uint64 value,
        uint64 wordSize
    ) public
    {
        uint64 numberOfBytes = wordSize / 8;

        if (numberOfBytes == 8) {
            memoryWrite(paddr, value);
        } else {
            // get relative address from unaligned paddr
            uint64 closestStartAddr = paddr & uint64(~7);
            uint64 relAddr = paddr - closestStartAddr;

            // oldvalue just like its on MM, without endianess swap
            uint64 oldVal = pureMemoryRead(closestStartAddr);

            // Mask to clean a piece of the value that was on memory
            uint64 valueMask = BitsManipulationLibrary.uint64SwapEndian(((uint64(2) ** wordSize) - 1) << relAddr*8);

            // value is big endian, need to swap before further operation
            uint64 valueSwap = BitsManipulationLibrary.uint64SwapEndian(value & ((uint64(2) ** wordSize) - 1));

            uint64 newvalue = ((oldVal & ~valueMask) | (valueSwap >> relAddr*8));

            newvalue = BitsManipulationLibrary.uint64SwapEndian(newvalue);
            memoryWrite(closestStartAddr, newvalue);
        }
    }

    function writeX(uint64 registerindex, uint64 value) public {
        memoryWrite(registerindex * 8, value);
    }

    // Internal functions
    function memoryRead(uint64 _readAddress) public returns (uint64) {
        return BitsManipulationLibrary.uint64SwapEndian(
            uint64(memoryAccessManager(_readAddress, true))
        );
    }

    function memoryWrite(uint64 _writeAddress, uint64 _value) virtual public {
        bytes8 bytesvalue = bytes8(BitsManipulationLibrary.uint64SwapEndian(_value));
        require(memoryAccessManager(_writeAddress, false) == bytesvalue, "Written value does not match");
    }

    // Memory Write without endianess swap
    function pureMemoryWrite(uint64 _writeAddress, uint64 _value) virtual internal {
        require(
            memoryAccessManager(_writeAddress, false) == bytes8(_value),
            "Written value does not match"
        );
    }

    // Memory Read without endianess swap
    function pureMemoryRead(uint64 _readAddress) internal returns (uint64) {
        return uint64(memoryAccessManager(_readAddress, true));
    }

   // Private functions

    // takes care of read/write access
    function memoryAccessManager(uint64 _address, bool _accessIsRead) internal virtual returns (bytes8) {
        require(isRead[rwIndex] == _accessIsRead, "Access was not the correct type");

        uint64 position = rwPositions[rwIndex];
        bytes8 value = rwValues[rwIndex];
        rwIndex++;

        require((position & 7) == 0, "Position is not aligned");
        require(position == _address, "Position and read address do not match");

        return value;
    }
}

