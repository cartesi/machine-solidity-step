// Copyright 2019 Cartesi Pte. Ltd.

// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "./MemoryInteractor.sol";
import "@cartesi/util/contracts/BitsManipulationLibrary.sol";


/// @title Test Memory Interactor
/// @author Felipe
/// @notice A mock memory interactor for running test_ram.py
/// @dev This should never be deployed to Main net.
/// @dev This contract is unsafe.
contract TestMemoryInteractor is MemoryInteractor {
  // the provider will fill the memory for the client to read and write
  // memory starts with hash and all values that are inserted are first verified
  // then client can read inserted values and write some more
  // finally the provider has to update the hash to account for writes

   // ram map
    mapping(uint64 => bytes8) ram;
    event HTIFExit(uint256 _index, uint64 _exitCode, bool _halt);

    function initializeMemory(
        uint64[] memory _rwPositions,
        bytes8[] memory _rwValues,
        bool[] memory _isRead
    ) override public
    {
    }

    function memoryWrite(uint64 _writeAddress, uint64 _value) override public {
        bytes8 bytesvalue = bytes8(BitsManipulationLibrary.uint64SwapEndian(_value));

        ram[_writeAddress] = bytes8(bytesvalue);
    }

    // Memory Write without endianess swap
    function pureMemoryWrite(uint64 _writeAddress, uint64 _value) override internal {

        ram[_writeAddress] = bytes8(_value);
    }

    // Memory Write without endianess swap
    function externalPureMemoryWrite(uint64 _writeAddress, bytes8 _value) public {

        ram[_writeAddress] = _value;
    }

    // Private functions

    // takes care of read/write access
    function memoryAccessManager(uint64 _address, bool) internal override returns (bytes8) {
        require((_address & 7) == 0, "Position is not aligned");

        return ram[_address];
    }

    /// @notice Perform a read in HTIF to get the arbitrary exit code
    function htifExit() public
        returns (uint64)
    {
        uint64 val = uint64(ram[0x40008000]);
        bool halt = false;

        val = BitsManipulationLibrary.uint64SwapEndian(val);

        uint64 bit0 = val & 1;
        uint64 payload = val << 16 >> 17;

        halt = (bit0 == 1);

        emit HTIFExit(rwIndex, payload, halt);
        return payload;
    }
}
