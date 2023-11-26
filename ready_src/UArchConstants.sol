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

/// @title UArchConstants
/// @notice Contains constants for micro-architecture
/// @dev This file is generated from templates/UArchConstants.sol.template, one should not modify the content directly

pragma solidity ^0.8.0;

library UArchConstants {
    // START OF AUTO-GENERATED CODE

    uint64 constant UCYCLE = 0x400008;
    uint64 constant UHALT = 0x400000;
    uint64 constant UPC = 0x400010;
    uint64 constant UX0 = 0x400018;
    uint64 constant UARCH_SHADOW_START_ADDRESS = 0x400000;
    uint64 constant UARCH_SHADOW_LENGTH = 0x1000;
    uint64 constant UARCH_RAM_START_ADDRESS = 0x600000;
    uint64 constant UARCH_RAM_LENGTH = 0x200000;
    uint64 constant RESET_POSITION = 0x400000;
    uint8 constant RESET_ALIGNED_SIZE = 22;
    bytes32 constant PRESTINE_STATE =
        0x990691da914eed5270e1aee557bd190fb0c79b67f8f6d87ee2c491c525fe2c98;
    // END OF AUTO-GENERATED CODE

    uint64 constant LOG2_CYCLES_TO_RESET = 10;
}
