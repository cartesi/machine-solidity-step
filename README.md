# Cartesi RISC-V Solidity Emulator

On-chain Solidity implementation of the [Cartesi Machine](https://github.com/cartesi/machine-emulator) state transition function. The core libraries (`UArchStep`, `UArchReset`, `SendCmioResponse`) are transpiled directly from the emulator's C++ sources to guarantee bit-exact equivalence.

> Use `make` for all build and test operations -- code generation must run before compilation.

## Quick start

Set up your environment, then build and test:

    export EMULATOR_DIR=../machine-emulator  # path to machine-emulator checkout
    export SED=gsed                          # macOS only (brew install gnu-sed)

    make submodules
    make build
    make test-all

## Prerequisites

    make env-check  # verify everything is installed

- [Foundry](https://book.getfoundry.sh/) 1.4.3
- GNU Make >= 3.81
- Lua 5.4, LuaRocks, LPEG
- GNU sed (gsed on macOS)
- GPP >= 2.27

<details>
<summary>macOS (Homebrew)</summary>

    brew install lua luarocks gpp gnu-sed
    luarocks install lpeg
    curl -L https://foundry.paradigm.xyz | bash
    foundryup -i v1.4.3

Add to your shell profile:

    eval "$(luarocks path)"

</details>

<details>
<summary>macOS (MacPorts)</summary>

    sudo port install lua54 luarocks gpp gsed
    luarocks install lpeg
    curl -L https://foundry.paradigm.xyz | bash
    foundryup -i v1.4.3

Add to your shell profile:

    eval "$(luarocks path)"
    export SED=gsed

</details>

<details>
<summary>Linux (Ubuntu/Debian)</summary>

    sudo apt install lua5.4 liblua5.4-dev luarocks gpp
    sudo luarocks install lpeg
    curl -L https://foundry.paradigm.xyz | bash
    foundryup -i v1.4.3

Add to your shell profile:

    eval "$(luarocks path)"

</details>

## Testing

    make test-transpiler   # transpiler unit tests (fast)
    make test-mock         # rv64i instruction tests against mock AccessLogs
    make test-prod         # production AccessLogs integration tests
    make test-replay       # replay 56 emulator step logs with full Merkle verification (~1 min)
    make test-all          # all of the above

### Using local emulator test data

By default, test data (binaries and JSON step logs) is downloaded from a
GitHub release. When developing against a local emulator build, generate and
use local test data instead:

    # one-time: generate step logs in the emulator repo
    make -C $EMULATOR_DIR/tests test-generate-uarch-logs

    # use them here
    make local-dep
    make test-all

This ensures the constants and test data come from the same emulator build.

### Coverage

    make coverage-mock
    make coverage-prod
    make coverage-report   # html report in coverage/

## Code generation

The build step runs these automatically; you only need them when
iterating on a specific piece:

    make generate-step               # uarch-step.cpp       -> UArchStep.sol
    make generate-reset              # uarch-reset-state.cpp -> UArchReset.sol
    make generate-send-cmio-response # send-cmio-response.cpp -> SendCmioResponse.sol
    make generate-constants          # EmulatorConstants.sol (from emulator Lua bindings)
    make generate-mock               # mock AccessLogs library
    make generate-prod               # production AccessLogs library

## Architecture

This implementation must produce the exact same state transition as the
off-chain emulator: given initial state s[i], both must reach s[i+1] bit for
bit. Machine states live on-chain as Merkle tree root hashes; their contents
are only known off-chain. Merkle proofs let the blockchain verify individual
transitions without storing the full state.

### Components

**MetaStep** -- Entry point. Runs one micro-step via `UArchStep.step` and
periodically resets the micro-architecture via `UArchReset.reset`.

**UArchStep** -- One micro-architecture instruction step (transpiled from
`uarch-step.cpp`). Decodes and executes RISC-V opcodes.

**UArchReset** -- Resets micro-architecture state (transpiled from
`uarch-reset-state.cpp`).

**SendCmioResponse** -- Handles CMIO yield responses (transpiled from
`send-cmio-response.cpp`).

**AccessLogs** -- Provides Merkle-verified read/write access to machine state.
During a dispute, the claimant supplies an access log with sibling hashes;
every read and write is checked against the Merkle root. Inconsistencies mean
the claimant loses.

**EmulatorCompat** -- Bridges C++/Solidity differences (endianness, type
widths, calling conventions).

**EmulatorConstants** -- Addresses, sizes, and hashes auto-generated from the
emulator's Lua bindings.

## Contributing

See [Contributing Guidelines](CONTRIBUTING.md) and our
[Code of Conduct](CODE_OF_CONDUCT.md).

## License

[Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0). See [LICENSE](LICENSE).
