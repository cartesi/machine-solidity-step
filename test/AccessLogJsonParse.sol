// Copyright Cartesi and individual authors (see AUTHORS)
// SPDX-License-Identifier: Apache-2.0
//
// Loads `accesses` arrays from JSON logs via one typed parse + `abi.decode` per step.
// Requires forge-std >= v1.9.2 (`vm.parseJsonTypeArray`).
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {Buffer} from "src/Buffer.sol";

import {BufferAux} from "./BufferAux.sol";

/// @dev Shared helpers for replay tests that load `accesses` arrays from JSON logs.
abstract contract AccessLogJsonParse is Test {
    using BufferAux for Buffer.Context;

    /// @dev Field order must match RAW_ACCESS_TYPE_DESCRIPTION below, which carries the
    /// JSON key names: address, log2_size, read_hash, read_value, sibling_hashes, type,
    /// written_hash, written_value. The decoding is positional, so the names may differ.
    struct RawAccess {
        uint256 accessAddress;
        uint256 log2Size;
        string readHash;
        string readValue;
        string[] siblingHashes;
        string accessType;
        string writtenHash;
        string writtenValue;
    }

    string internal constant RAW_ACCESS_TYPE_DESCRIPTION =
        "RawAccessJson(uint256 address,uint256 log2_size,string read_hash,string read_value,string[] sibling_hashes,string type,string written_hash,string written_value)";

    function _fillBufferFromRawAccesses(
        RawAccess[] memory rawAccesses,
        Buffer.Context memory buffer
    ) internal pure {
        uint256 n = rawAccesses.length;
        for (uint256 i = 0; i < n; i++) {
            RawAccess memory a = rawAccesses[i];
            if (a.log2Size == 3) {
                buffer.writeBytes32(_parseHex32FromLogString(a.readValue));
            } else if (
                keccak256(bytes(a.accessType)) == keccak256(bytes("read"))
            ) {
                // a leaf read carries the read value followed by the leaf hash
                buffer.writeBytes32(_parseHex32FromLogString(a.readValue));
                buffer.writeBytes32(_parseHex32FromLogString(a.readHash));
            } else {
                buffer.writeBytes32(_parseHex32FromLogString(a.readHash));
            }
            uint256 siblingCount = a.siblingHashes.length;
            for (uint256 j = 0; j < siblingCount; j++) {
                buffer.writeBytes32(
                    _parseHex32FromLogString(a.siblingHashes[j])
                );
            }
        }
    }

    function _parseHex32FromLogString(string memory s)
        internal
        pure
        returns (bytes32)
    {
        bytes memory b = bytes(s);
        if (b.length == 0) {
            return bytes32(0);
        }
        return vm.parseBytes32(s);
    }
}
