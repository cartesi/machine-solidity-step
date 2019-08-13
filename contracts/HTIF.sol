// Copyright 2019 Cartesi Pte. Ltd.

// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



// @title HTIF
pragma solidity ^0.5.0;

import "../contracts/MemoryInteractor.sol";


/// @title HTIF
/// @author Felipe Argento
/// @notice Host-Target-Interface (HTIF) mediates communcation with external world.
/// @dev Its active addresses are 0x40000000(tohost) and 0x40000008(from host)
/// Reference: The Core of Cartesi, v1.02 - Section 3.2 - The Board
library HTIF {

    uint64 constant HTIF_TOHOST_ADDR_CONST = 0x40008000;
    uint64 constant HTIF_FROMHOST_ADDR_CONST = 0x40008008;

    /// @notice reads htif
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param mmIndex Index corresponding to the instance of Memory Manager
    /// @param addr address to read from
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @return bool if read was successfull
    /// @return uint64 pval
    function htifRead(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 addr,
        uint64 wordSize
    )
    public returns (bool, uint64)
    {
        // HTIF reads must be aligned and 8 bytes
        if (wordSize != 64 || (addr & 7) != 0) {
            return (false, 0);
        }

        if (addr == HTIF_TOHOST_ADDR_CONST) {
            return (true, mi.readHtifTohost(mmIndex));
        } else if (addr == HTIF_FROMHOST_ADDR_CONST) {
            return (true, mi.readHtifFromhost(mmIndex));
        } else {
            return (false, 0);
        }
    }

    /// @notice write htif
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param mmIndex Index corresponding to the instance of Memory Manager that
    /// @param addr address to read from
    /// @param val value to be written
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @return bool if write was successfull
    function htifWrite(
        MemoryInteractor mi,
        uint256 mmIndex,
        uint64 addr,
        uint64 val,
        uint64 wordSize
    )
    public returns (bool)
    {
        // HTIF writes must be aligned and 8 bytes
        if (wordSize != 64 || (addr & 7) != 0) {
            return false;
        }
        if (addr == HTIF_TOHOST_ADDR_CONST) {
            return htifWriteTohost(mi, mmIndex, val);
        } else if (addr == HTIF_FROMHOST_ADDR_CONST) {
            return htifWriteFromhost(mi, mmIndex, val);
        } else {
            return false;
        }
    }

    // Internal functions
    function htifWriteFromhost(MemoryInteractor mi, uint256 mmIndex, uint64 val)
    internal returns (bool)
    {
        mi.writeHtifFromhost(mmIndex, val);
        // TO-DO: check if h is interactive? reset from host? pollConsole?
        return true;
    }

    function htifWriteTohost(MemoryInteractor mi, uint256 mmIndex, uint64 tohost)
    internal returns (bool)
    {
        uint32 device = uint32(tohost >> 56);
        uint32 cmd = uint32((tohost >> 48) & 0xff);
        uint64 payload = uint32((tohost & (~(uint256(1) >> 16))));

        mi.writeHtifTohost(mmIndex, tohost);

        if (device == 0 && cmd == 0 && (payload & 1) != 0) {
            return htifWriteHalt(mi, mmIndex);
        } else if (device == 1 && cmd == 1) {
            return htifWritePutchar(mi, mmIndex);
        } else if (device == 1 && cmd == 0) {
            return htifWriteGetchar(mi, mmIndex);
        }
        return true;
    }

    function htifWriteHalt(MemoryInteractor mi, uint256 mmIndex) internal
    returns (bool)
    {
        //set iflags to halted
        mi.setIflagsH(mmIndex, true);
        return true;
    }

    function htifWritePutchar(MemoryInteractor mi, uint256 mmIndex) internal
    returns (bool)
    {
        mi.writeHtifTohost(mmIndex, 0); // Acknowledge command (?)
        // TO-DO: what to do in the blockchain? Generate event?
        mi.writeHtifFromhost(mmIndex, (uint64(1) << 56) | uint64(1) << 48);
        return true;
    }

    function htifWriteGetchar(MemoryInteractor mi, uint256 mmIndex) internal
    returns (bool)
    {
        mi.writeHtifTohost(mmIndex, 0); // Acknowledge command (?)
        return true;
    }

    // getters
    function getHtifToHostAddr() public pure returns (uint64) {
        return HTIF_TOHOST_ADDR_CONST;
    }

    function getHtifFromHostAddr() public pure returns (uint64) {
        return HTIF_FROMHOST_ADDR_CONST;
    }
}
