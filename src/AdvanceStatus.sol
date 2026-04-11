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

/// @title AdvanceStatus
/// @notice Return advance status

pragma solidity ^0.8.30;

import "./EmulatorCompat.sol";
import "./EmulatorConstants.sol";

library AdvanceStatus {
    enum Status {
        NOT_YIELDED,
        ACCEPTED,
        REJECTED,
        EXCEPTION
    }

    /*
    typedef struct cmt_io_yield {
    uint8_t dev;
    uint8_t cmd;
    uint16_t reason;
    uint32_t data;
    } cmt_io_yield_t;
    */

    error InvalidReason(uint16 reason);

    function advanceStatus(AccessLogs.Context memory a)
        internal
        pure
        returns (Status)
    {
        if (!EmulatorCompat.readIflagsY(a)) {
            return Status.NOT_YIELDED;
        }

        // the following two approaches are equivalent:
        // 1. swap the whole struct and then extract the reason
        // 2. extract the reason from the struct and then swap the value
        // EmulatorCompat.readWord already swaps the struct, so we can extract the reason directly

        uint64 tohost =
            EmulatorCompat.readWord(a, EmulatorConstants.HTIF_TOHOST_ADDRESS);
        uint16 reason = uint16(tohost >> 32);

        if (reason == EmulatorConstants.CMIO_YIELD_MANUAL_REASON_RX_ACCEPTED) {
            return Status.ACCEPTED;
        } else if (
            reason == EmulatorConstants.CMIO_YIELD_MANUAL_REASON_RX_REJECTED
        ) {
            return Status.REJECTED;
        } else if (
            reason == EmulatorConstants.CMIO_YIELD_MANUAL_REASON_TX_EXCEPTION
        ) {
            return Status.EXCEPTION;
        } else {
            revert InvalidReason(reason);
        }
    }
}
