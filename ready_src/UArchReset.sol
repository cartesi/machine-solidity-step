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

/// @title UArchReset
/// @notice Reset microarchitecture to pristine state
/// @dev This file is generated from templates/UArchReset.sol.template, one should not modify the content directly

pragma solidity ^0.8.0;

import "./UArchCompat.sol";

library UArchReset {
    // START OF AUTO-GENERATED CODE

    function reset(AccessLogs.Context memory a) internal pure {
        UArchCompat.resetState(a);
    }

    // END OF AUTO-GENERATED CODE
}
