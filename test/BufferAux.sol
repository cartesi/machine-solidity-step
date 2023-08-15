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
pragma solidity ^0.8.0;

import "ready_src/Buffer.sol";

library BufferAux {
    using BufferAux for Buffer.Context;

    function writeBytes8(Buffer.Context memory buffer, bytes8 val)
        internal
        pure
    {
        buffer.storeBytes32(bytes32(val));
        buffer.offset += 8;
    }

    function writeBytes32(Buffer.Context memory buffer, bytes32 val)
        internal
        pure
    {
        buffer.storeBytes32(val);
        buffer.offset += 32;
    }

    function storeBytes32(Buffer.Context memory buffer, bytes32 val)
        internal
        pure
    {
        bytes memory data = buffer.data;
        uint256 offset = buffer.offset;

        // The 32 is added to offset because we are accessing a byte array.
        // And an array in solidity always starts with its length which is a 32 byte-long variable.
        assembly {
            mstore(add(data, add(offset, 32)), val)
        }
    }
}
