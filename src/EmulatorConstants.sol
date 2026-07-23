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
        0xfecd1447b18725c91ba909a13b3d059d3628a625f668ce991e6ab7c901a65d2c;
    uint64 constant UARCH_CYCLE_ADDRESS = 0x400008;
    uint64 constant UARCH_CYCLE_MAX = 0xfffff;
    uint64 constant ROLLUP_LOG2_MAX_MCYCLES_PER_ADVANCE_STATE = 48;
    uint64 constant ROLLUP_LOG2_MAX_UARCH_CYCLES_PER_MCYCLE = 20;
    uint64 constant ROLLUP_LOG2_MAX_OUTPUT_COUNT = 63;
    uint64 constant ROLLUP_LOG2_MAX_ADVANCE_STATES_PER_EPOCH = 24;
    uint64 constant UARCH_HALT_ADDRESS = 0x400000;
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
    uint64 constant UARCH_ECALL_FN_WRITE_TLB = 4;
    uint64 constant HTIF_YIELD = 0x350;
    uint64 constant IFLAGS_Y_ADDRESS = 0x308;
    uint64 constant MCYCLE_ADDRESS = 0x100;
    uint64 constant IMCYCLEMAX_ADDRESS = 0x2f8;
    uint64 constant HTIF_FROMHOST_ADDRESS = 0x338;
    uint64 constant HTIF_TOHOST_ADDRESS = 0x330;
    uint8 constant HTIF_YIELD_REASON_ADVANCE_STATE = 0x0;
    uint32 constant HASH_TREE_LOG2_WORD_SIZE = 0x5;
    uint32 constant HASH_TREE_WORD_SIZE = uint32(1) << HASH_TREE_LOG2_WORD_SIZE;
    uint32 constant HTIF_DEV_SHIFT = 0x38;
    uint32 constant HTIF_CMD_SHIFT = 0x30;
    uint32 constant HTIF_REASON_SHIFT = 0x20;
    uint64 constant HTIF_DEV_MASK = 0xff00000000000000;
    uint64 constant HTIF_CMD_MASK = 0xff000000000000;
    uint64 constant HTIF_REASON_MASK = 0xffff00000000;
    uint64 constant HTIF_DEV_YIELD = 0x2;
    uint64 constant HTIF_YIELD_CMD_MANUAL = 0x1;
    uint16 constant HTIF_YIELD_MANUAL_REASON_RX_ACCEPTED = 0x1;
    uint16 constant HTIF_YIELD_MANUAL_REASON_RX_REJECTED = 0x2;
    uint16 constant HTIF_YIELD_MANUAL_REASON_TX_EXCEPTION = 0x4;
    uint8 constant UARCH_STATE_LOG2_SIZE = 22;
    uint64 constant AR_CMIO_RX_BUFFER_START = 0x60000000;
    uint8 constant AR_CMIO_RX_BUFFER_LOG2_SIZE = 0x15;
    uint64 constant AR_CMIO_TX_BUFFER_START = 0x60800000;
    uint8 constant AR_CMIO_TX_BUFFER_LOG2_SIZE = 0x15;
    uint64 constant REVERT_ROOT_HASH_ADDRESS = 0xfe0;
    // END OF AUTO-GENERATED CODE

    uint64 constant TLB_SLOT_LENGTH = 32;
    uint64 constant TLB_SET_SIZE = 256;
    uint64 constant TLB_SET_LENGTH = TLB_SET_SIZE * TLB_SLOT_LENGTH;
}
