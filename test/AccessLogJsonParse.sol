// Copyright Cartesi and individual authors (see AUTHORS)
// SPDX-License-Identifier: Apache-2.0
//
// Loads `accesses` arrays from JSON logs via one typed parse + `abi.decode` per step.
// Requires forge-std >= v1.9.2 (`vm.parseJsonTypeArray`).
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import "src/Buffer.sol";

import "./BufferAux.sol";

/// @dev Shared helpers for replay tests that load `accesses` arrays from JSON logs.
abstract contract AccessLogJsonParse is Test {
    using BufferAux for Buffer.Context;

    /// @dev JSON keys: address, log2_size, read_hash, read_value, sibling_hashes, type,
    /// written_hash, written_value.
    struct RawAccess {
        uint256 accessAddress;
        uint256 log2_size;
        string read_hash;
        string read_value;
        string[] sibling_hashes;
        string accessType;
        string written_hash;
        string written_value;
    }

    string internal constant RAW_ACCESS_TYPE_DESCRIPTION =
        "RawAccess(uint256 address,uint256 log2_size,string read_hash,string read_value,string[] sibling_hashes,string type,string written_hash,string written_value)";

    function _fillBufferFromRawAccesses(
        RawAccess[] memory rawAccesses,
        Buffer.Context memory buffer,
        uint256 fixedSiblingsLength
    ) internal pure {
        uint256 n = rawAccesses.length;
        for (uint256 i = 0; i < n; i++) {
            RawAccess memory a = rawAccesses[i];
            if (a.log2_size == 3) {
                buffer.writeBytes32(_parseHex32FromLogString(a.read_value));
            } else {
                buffer.writeBytes32(_parseHex32FromLogString(a.read_hash));
            }
            for (uint256 j = 0; j < fixedSiblingsLength; j++) {
                buffer.writeBytes32(
                    _parseHex32FromLogString(a.sibling_hashes[j])
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
        if (
            b.length >= 2 && b[0] == bytes1("0")
                && (b[1] == bytes1("x") || b[1] == bytes1("X"))
        ) {
            return vm.parseBytes32(s);
        }
        return vm.parseBytes32(string.concat("0x", s));
    }
}
