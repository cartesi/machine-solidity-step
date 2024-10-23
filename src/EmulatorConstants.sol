// Copyright Cartesi and individual authors (see AUTHORS)
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/// @title EmulatorConstants
/// @notice Contains constants for machine emulator
//:#include macro.pp
/// DEV_COMMENT(templates/EmulatorConstants.sol.template)

pragma solidity ^0.8.0;

library EmulatorConstants {
    // START OF AUTO-GENERATED CODE

    uint64 constant UARCH_CYCLE_ADDRESS = 0x400008;
    uint64 constant UARCH_HALT_FLAG_ADDRESS = 0x400000;
    uint64 constant UARCH_PC_ADDRESS = 0x400010;
    uint64 constant UARCH_X0_ADDRESS = 0x400018;
    uint64 constant UARCH_SHADOW_START_ADDRESS = 0x400000;
    uint64 constant UARCH_SHADOW_LENGTH = 0x1000;
    uint64 constant UARCH_RAM_START_ADDRESS = 0x600000;
    uint64 constant UARCH_RAM_LENGTH = 0x200000;
    uint64 constant UARCH_STATE_START_ADDRESS = 0x400000;
    uint8 constant UARCH_STATE_LOG2_SIZE = 22;
    bytes32 constant UARCH_PRISTINE_STATE_HASH =
        0x4de6115bdadc23724cf20c5580d718525ce81b294c8c149d3658020c380df109;
    uint64 constant UARCH_ECALL_FN_HALT = 1;
    uint64 constant UARCH_ECALL_FN_PUTCHAR = 2;
    uint64 constant IFLAGS_ADDRESS = 0x2e8;
    uint64 constant HTIF_FROMHOST_ADDRESS = 0x318;
    uint32 constant TREE_LOG2_WORD_SIZE = 0x5;
    uint32 constant TREE_WORD_SIZE = uint32(1) << TREE_LOG2_WORD_SIZE;
    uint64 constant PMA_CMIO_RX_BUFFER_START = 0x60000000;
    uint8 constant PMA_CMIO_RX_BUFFER_LOG2_SIZE = 0x15;
    // END OF AUTO-GENERATED CODE

    uint32 constant IFLAGS_Y_SHIFT = 1;
    uint64 constant LOG2_CYCLES_TO_RESET = 10;
}
