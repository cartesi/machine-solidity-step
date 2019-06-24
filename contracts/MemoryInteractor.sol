/// @title MemoryInteractor.sol
pragma solidity ^0.5.0;

import "../contracts/ShadowAddresses.sol";
import "../contracts/HTIF.sol";
import "../contracts/CLINT.sol";
import "./lib/BitsManipulationLibrary.sol";


contract mmInterface {
    function read(uint256 _index, uint64 _address) external returns (bytes8);
    function write(uint256 _index, uint64 _address, bytes8 _value) external;
    function finishReplayPhase(uint256 _index) external;
}

// TO-DO: Rewrite this - MemoryRead/MemoryWrite should be private/internal and
// all reads/writes should be specific.


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
        //address = registerindex * sizeof(uint64)
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
        uint64 valueMask = ((2 ** wordSize) - 1) << (64 - (relAddr*8 + wordSize));
        val = (val & valueMask) << relAddr*8;
        return BitsManipulationLibrary.uint64SwapEndian(val);
    }

    // Sets
    function setPriv(uint256 mmindex, uint64 newPriv) public {
        writeIflagsPrv(mmindex, newPriv);
        writeIlrsc(mmindex, uint64(-1)); // invalidate reserved address
    }

    function setIflagsI(uint256 mmindex, bool idle) public {
        uint64 iflags = readIflags(mmindex);

        if (idle) {
            iflags = (iflags | 10);
        } else {
            iflags = (iflags & ~(uint64(1) << 1));
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

    function writeIflagsH(uint256 mmindex, uint64 value) public {
        uint64 iflags = readIflags(mmindex);
        uint64 hMask = 1;
        iflags = (iflags & (~hMask)) | (value);

        memoryWrite(mmindex, ShadowAddresses.getIflags(), iflags);
    }

    function writeIflagsPrv(uint256 mmindex, uint64 newPriv) public {
        uint64 iflags = readIflags(mmindex);
        uint64 privMask = 3 << 2;

        // Clears bits 3 and 2 of iflags and use or to set new value
        iflags = (iflags & (~privMask)) | (newPriv << 2);

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
            uint64 valueMask = ((2 ** wordSize) - 1) << (64 - (relAddr*8 + wordSize));

            // value is big endian, need to swap before further operation
            uint64 valueSwap = BitsManipulationLibrary.uint64SwapEndian(value);

            uint64 newvalue = ((oldVal & ~valueMask) | (valueSwap & valueMask));

            newvalue = BitsManipulationLibrary.uint64SwapEndian(newvalue);
            memoryWrite(mmindex, closestStartAddr, newvalue);
        }
    }

    function writeX(uint256 mmindex, uint64 registerindex, uint64 value) public {
        //address = registerindex * sizeof(uint64)
        //bytes8 bytesvalue = bytes8(BitsManipulationLibrary.uint64SwapEndian(value));
        memoryWrite(mmindex, registerindex * 8, value);
    }

    // Internal functions
    function memoryRead(uint256 index, uint64 readAddress) public returns (uint64) {
        //return uint64(mm.read(index, address));
        return BitsManipulationLibrary.uint64SwapEndian(
            uint64(mm.read(index, readAddress))
        );
    }

    // Memory Read endianess swap
    function pureMemoryRead(uint256 index, uint64 readAddress) public returns (uint64) {
        return uint64(mm.read(index, readAddress));
    }

    function memoryWrite(uint256 index, uint64 writeAddress, uint64 value) public {
        bytes8 bytesvalue = bytes8(BitsManipulationLibrary.uint64SwapEndian(value));
        mm.write(index, writeAddress, bytesvalue);
    }

    // Memory Write without endianess swap
    function pureMemoryWrite(uint256 index, uint64 writeAddress, uint64 value) public {
        mm.write(index, writeAddress, bytes8(value));
    }
}

