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

pragma solidity ^0.8.30;

library EmulatorConstants {
    // START OF AUTO-GENERATED CODE

    bytes32 constant UARCH_PRISTINE_STATE_HASH =
        0x3cf87e9cab4091ffefa4ff42b149e765fbc3fd6c21fcaf32b49e7f068047ad7e;
    uint64 constant UARCH_CYCLE_ADDRESS = 0x400008;
    uint64 constant UARCH_CYCLE_MAX = 0x100000;
    uint64 constant UARCH_HALT_FLAG_ADDRESS = 0x400000;
    uint64 constant UARCH_PC_ADDRESS = 0x400010;
    uint64 constant UARCH_X0_ADDRESS = 0x400018;
    uint64 constant UARCH_SHADOW_START_ADDRESS = 0x400000;
    uint64 constant UARCH_SHADOW_LENGTH = 0x1000;
    uint64 constant AR_SHADOW_TLB_START = 0x1000;
    uint64 constant AR_SHADOW_TLB_LENGTH = 0x6000;
    uint64 constant UARCH_RAM_START_ADDRESS = 0x600000;
    uint64 constant UARCH_RAM_LENGTH = 0x200000;
    uint64 constant UARCH_STATE_START_ADDRESS = 0x400000;
    uint64 constant UARCH_ECALL_FN_HALT = 1;
    uint64 constant UARCH_ECALL_FN_PUTCHAR = 2;
    uint64 constant UARCH_ECALL_FN_MARK_DIRTY_PAGE = 3;
    uint64 constant UARCH_ECALL_FN_WRITE_TLB = 4;
    uint64 constant HTIF_YIELD = 0x348;
    uint64 constant IFLAGS_Y_ADDRESS = 0x300;
    uint64 constant HTIF_FROMHOST_ADDRESS = 0x330;
    uint64 constant HTIF_TOHOST_ADDRESS = 0x328;
    uint8 constant CMIO_YIELD_REASON_ADVANCE_STATE = 0x0;
    uint32 constant HASH_TREE_LOG2_WORD_SIZE = 0x5;
    uint32 constant HASH_TREE_WORD_SIZE = uint32(1) << HASH_TREE_LOG2_WORD_SIZE;
    uint16 constant CMIO_YIELD_MANUAL_REASON_RX_ACCEPTED = 0x1;
    uint16 constant CMIO_YIELD_MANUAL_REASON_RX_REJECTED = 0x2;
    uint16 constant CMIO_YIELD_MANUAL_REASON_TX_EXCEPTION = 0x4;
    uint8 constant UARCH_STATE_LOG2_SIZE = 22;
    uint64 constant AR_CMIO_RX_BUFFER_START = 0x60000000;
    uint8 constant AR_CMIO_RX_BUFFER_LOG2_SIZE = 0x15;
    uint64 constant AR_CMIO_TX_BUFFER_START = 0x60800000;
    uint8 constant AR_CMIO_TX_BUFFER_LOG2_SIZE = 0x15;
    uint64 constant REVERT_ROOT_HASH_ADDRESS = 0xfe0;
    // END OF AUTO-GENERATED CODE

    uint64 constant LOG2_CYCLES_TO_RESET = 10;

    uint64 constant TLB_SLOT_LENGTH = 32;
    uint64 constant TLB_SET_SIZE = 256;
    uint64 constant TLB_SET_LENGTH = TLB_SET_SIZE * TLB_SLOT_LENGTH;
}
