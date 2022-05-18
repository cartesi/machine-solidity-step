// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



// @title HTIF
pragma solidity ^0.7.0;

import "./MemoryInteractor.sol";


/// @title HTIF
/// @author Felipe Argento
/// @notice Host-Target-Interface (HTIF) mediates communcation with external world.
/// @dev Its active addresses are 0x40000000(tohost) and 0x40000008(from host)
/// Reference: The Core of Cartesi, v1.02 - Section 3.2 - The Board
library HTIF {

    uint64 constant HTIF_TOHOST_ADDR_CONST = 0x40008000;
    uint64 constant HTIF_FROMHOST_ADDR_CONST = 0x40008008;
    uint64 constant HTIF_IHALT_ADDR_CONST = 0x40008010;
    uint64 constant HTIF_ICONSOLE_ADDR_CONST = 0x40008018;
    uint64 constant HTIF_IYIELD_ADDR_CONST = 0x40008020;

    // [c++] enum HTIF_devices
    uint64 constant HTIF_DEVICE_HALT = 0;        //< Used to halt machine
    uint64 constant HTIF_DEVICE_CONSOLE = 1;     //< Used for console input and output
    uint64 constant HTIF_DEVICE_YIELD = 2;       //< Used to yield control back to host

    // [c++] enum HTIF_commands
    uint64 constant HTIF_HALT_HALT = 0;
    uint64 constant HTIF_CONSOLE_GETCHAR = 0;
    uint64 constant HTIF_CONSOLE_PUTCHAR = 1;
    uint64 constant HTIF_YIELD_AUTOMATIC = 0;
    uint64 constant HTIF_YIELD_MANUAL = 1;

    /// @notice reads htif
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param addr address to read from
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @return bool if read was successfull
    /// @return uint64 pval
    function htifRead(
        MemoryInteractor mi,
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
            return (true, mi.readHtifTohost());
        } else if (addr == HTIF_FROMHOST_ADDR_CONST) {
            return (true, mi.readHtifFromhost());
        } else {
            return (false, 0);
        }
    }

    /// @notice write htif
    /// @param mi Memory Interactor with which Step function is interacting.
    /// @param addr address to read from
    /// @param val value to be written
    /// @param wordSize can be uint8, uint16, uint32 or uint64
    /// @return bool if write was successfull
    function htifWrite(
        MemoryInteractor mi,
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
            return htifWriteTohost(mi, val);
        } else if (addr == HTIF_FROMHOST_ADDR_CONST) {
            mi.writeHtifFromhost(val);
            return true;
        } else {
            return false;
        }
    }

    // Internal functions
    function htifWriteFromhost(MemoryInteractor mi, uint64 val)
    internal returns (bool)
    {
        mi.writeHtifFromhost(val);
        // TO-DO: check if h is interactive? reset from host? pollConsole?
        return true;
    }

    function htifWriteTohost(MemoryInteractor mi, uint64 tohost)
    internal returns (bool)
    {
        uint32 device = uint32(tohost >> 56);
        uint32 cmd = uint32((tohost >> 48) & 0xff);
        uint64 payload = uint32((tohost & (~(uint256(1) >> 16))));

        mi.writeHtifTohost(tohost);

        if (device == HTIF_DEVICE_HALT) {
            return htifHalt(
                mi,
                cmd,
                payload);
        } else if (device == HTIF_DEVICE_CONSOLE) {
            return htifConsole(
                mi,
                cmd,
                payload);
        } else if (device == HTIF_DEVICE_YIELD) {
            return htifYield(
                mi,
                cmd,
                payload);
        } else {
            return true;
        }
    }

    function htifHalt(
        MemoryInteractor mi,
        uint64 cmd,
        uint64 payload)
    internal returns (bool)
    {
        if (cmd == HTIF_HALT_HALT && ((payload & 1) == 1) ) {
            //set iflags to halted
            mi.setIflagsH(true);
        }
        return true;
    }

    function htifYield(
        MemoryInteractor mi,
        uint64 cmd,
        uint64 payload)
    internal returns (bool)
    {
        // If yield command is enabled, yield
        if ((mi.readHtifIYield() >> cmd) & 1 == 1) {
            if (cmd == HTIF_YIELD_MANUAL) {
                mi.setIflagsY(true);
            } else {
                mi.setIflagsX(true);
            }
            mi.writeHtifFromhost((HTIF_DEVICE_YIELD << 56) | cmd << 48);
        }

        return true;
    }

    function htifConsole(
        MemoryInteractor mi,
        uint64 cmd,
        uint64 payload)
    internal returns (bool)
    {        
        // If console command is enabled, aknowledge it
        if ((mi.readHtifIConsole() >> cmd) & 1 == 1) {
             if (cmd == HTIF_CONSOLE_PUTCHAR) { 
                // TO-DO: what to do in the blockchain? Generate event?
                mi.writeHtifFromhost((HTIF_DEVICE_CONSOLE << 56) | cmd << 48);
            } else if (cmd == HTIF_CONSOLE_GETCHAR) { 
                // In blockchain, this command will never be enabled as there is no way to input the same character
                // to every participant in a dispute: where would character come from? So if the code reached here in the
                // blockchain, there must be some serious bug
                revert("Machine is in interactive mode. This is a fatal bug in the Dapp");
            }
            // Unknown HTIF console commands are silently ignored
        }
        
        return true;
    }

    // getters
    function getHtifToHostAddr() public pure returns (uint64) {
        return HTIF_TOHOST_ADDR_CONST;
    }

    function getHtifFromHostAddr() public pure returns (uint64) {
        return HTIF_FROMHOST_ADDR_CONST;
    }

    function getHtifIHaltAddr() public pure returns (uint64) {
        return HTIF_IHALT_ADDR_CONST;
    }

    function getHtifIConsoleAddr() public pure returns (uint64) {
        return HTIF_ICONSOLE_ADDR_CONST;
    }

    function getHtifIYieldAddr() public pure returns (uint64) {
        return HTIF_IYIELD_ADDR_CONST;
    }

}
