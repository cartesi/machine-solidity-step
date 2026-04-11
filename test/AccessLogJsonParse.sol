// Copyright Cartesi and individual authors (see AUTHORS)
// SPDX-License-Identifier: Apache-2.0
//
// Generic `vm.parseJson` + `abi.decode` infers JSON scalars in a Foundry-version-dependent way
// (e.g. digit-only strings may become uint256 in newer Forge). Typed parseJson* helpers force
// the intended Solidity types — see discussion in machine-solidity-step PRs / Foundry issues.
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import "src/Buffer.sol";

import "./BufferAux.sol";

/// @dev Shared helpers for replay tests that load `accesses` arrays from JSON logs.
abstract contract AccessLogJsonParse is Test {
    using BufferAux for Buffer.Context;

    /// @notice External wrapper so `try/catch` can detect end of JSON array (see `_accessesArrayLength`).
    function __jsonUintProbe(string memory json, string memory key)
        external
        returns (uint256)
    {
        return vm.parseJsonUint(json, key);
    }

    /// @dev Count elements of a JSON array of objects by probing `.address` until the probe reverts.
    ///      Max 64 elements (logs currently need at most ~13).
    function _accessesArrayLength(
        string memory json,
        string memory arrayPrefix
    ) internal returns (uint256) {
        for (uint256 i = 0; i < 64; i++) {
            try this.__jsonUintProbe(
                json,
                string.concat(arrayPrefix, "[", vm.toString(i), "].address")
            ) returns (
                uint256
            ) {
            /* element i exists */
            }
            catch {
                return i;
            }
        }
        revert("accesses array exceeds 64");
    }

    /// @dev Fill buffer from `accesses` using typed JSON reads only (no `abi.decode` on access objects).
    function _fillBufferFromAccesses(
        string memory rawJson,
        string memory arrayPrefix,
        Buffer.Context memory buffer
    ) internal {
        uint256 n = _accessesArrayLength(rawJson, arrayPrefix);
        for (uint256 i = 0; i < n; i++) {
            string memory p =
                string.concat(arrayPrefix, "[", vm.toString(i), "]");
            uint256 log2_size =
                vm.parseJsonUint(rawJson, string.concat(p, ".log2_size"));
            string memory read_value =
                vm.parseJsonString(rawJson, string.concat(p, ".read_value"));
            string memory read_hash =
                vm.parseJsonString(rawJson, string.concat(p, ".read_hash"));
            string[] memory sib = vm.parseJsonStringArray(
                rawJson, string.concat(p, ".sibling_hashes")
            );
            if (log2_size == 3) {
                buffer.writeBytes32(
                    vm.parseBytes32(string.concat("0x", read_value))
                );
            } else {
                buffer.writeBytes32(
                    vm.parseBytes32(string.concat("0x", read_hash))
                );
            }
            for (uint256 j = 0; j < sib.length; j++) {
                buffer.writeBytes32(
                    vm.parseBytes32(string.concat("0x", sib[j]))
                );
            }
        }
    }
}
