// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



pragma solidity ^0.7.0;

import "@cartesi/arbitration/contracts/MMInstantiator.sol";

/// @title Test No Merkle MM Instantiator
/// @author Gabriel Barros
/// @notice A mock memory manager for running proof tests without
//           verifying hashes, just access
/// @dev This should *NEVER* be deployed to Main net.
/// @dev This contract is UNSAFE.
contract TestNoMerkleMM is MMInstantiator {

    /// @notice Used instead of the proveRead. It wont verify the hashes/merkle.
    /// @param _position The address of the value to be confirmed
    /// @param _value The value in that address to be confirmed
    function fakeProveRead(
        uint256 _index,
        uint64 _position,
        bytes8 _value) public
        onlyInstantiated(_index)
        onlyBy(instance[_index].provider)
        increasesNonce(_index)
    {
        require(instance[_index].currentState == state.WaitingProofs, "CurrentState is not WaitingProofs, cannot proveRead");
        instance[_index].history.push(ReadWrite(true, _position, _value));
        emit ValueProved(
            _index,
            true,
            _position,
            _value
        );
    }

    /// @notice Used instead of the proveWrite. It wont verify the hashes/merkle.
    /// @param _position to be written
    /// @param _newValue to be written
    function fakeproveWrite(
        uint256 _index,
        uint64 _position,
        bytes8 _newValue) public
        onlyInstantiated(_index)
        onlyBy(instance[_index].provider)
        increasesNonce(_index)
    {
        require(instance[_index].currentState == state.WaitingProofs, "CurrentState is not WaitingProofs, cannot proveWrite");
        instance[_index].history.push(ReadWrite(false, _position, _newValue));
        emit ValueProved(
            _index,
            false,
            _position,
            _newValue
        );
    }
}