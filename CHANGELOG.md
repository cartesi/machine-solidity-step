# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.15.0] - 2026-08-04
### Added
- Added `revertRootHash` argument to `sendCmioResponse`
- Added `imcyclemax` deadline set by `sendCmioResponse` on advance-state responses
- Added revert on rejected input to `UArchReset.reset()`
- Added `ROLLUP_LOG2_MAX_*` limits and HTIF device/command/reason constants
- Added `revertState`, `readMcycle`, `writeImcyclemax`, `readHtifTohost` and `isYieldedManualWith` to `EmulatorCompat`
- Added tests for uarch reset, no-op response and step fixed points

### Changed
- Changed `UArchStep.step` to report overflow and halt on the step that reaches them
- Changed `UARCH_CYCLE_MAX` from `0x100000` to `0xfffff`
- Changed `UArchReset.reset` to also read `iflags.Y` and `htif.tohost`
- Changed `sendCmioResponse` failures into no-ops
- Changed `MetaStep` uarch reset period from `2^10` to `2^20` meta-steps
- Renamed `UArchStepStatus.CycleOverflow` to `UArchCycleOverflow`
- Renamed `getRevertRootHash`/`setRevertRootHash` to `readRevertRootHash`/`writeRevertRootHash`
- Renamed `readHaltFlag`/`writeHaltFlag` to `readHalt`/`writeHalt`
- Renamed `CMIO_YIELD_*` constants to `HTIF_YIELD_*`, and `UARCH_HALT_FLAG_ADDRESS` to `UARCH_HALT_ADDRESS`
- Updated `UARCH_PRISTINE_STATE_HASH` and shadow register addresses
- Updated test artifact parsing for `0x`-prefixed hexadecimal values
- Updated machine-emulator version to v0.21.0
- Bumped Foundry to 1.5.1

### Removed
- Removed `AdvanceStatus` library
- Removed `mark_dirty_page` ECALL and `markDirtyPageECALL`
- Removed `LOG2_CYCLES_TO_RESET`

### Fixed
- Fixed various Solidity and forge lint warnings

## [0.14.0] - 2026-04-13
### Added
- Added `advanceStatus` to return advance status (accepted, rejected, exception)
- Added `getRevertRootHash`/`setRevertRootHash` to better support reverts

### Changed
- Updated machine-emulator version to v0.20.0
- Bumped Foundry to 1.4.3
- Bumped Solidity to 0.8.30
- Bumped `forge-std` to 1.9.2

## [0.13.0] - 2025-05-30
### Changed
- Updated machine-emulator version to v0.19.0
- Bumped foundry to 1.0.0

### Added
- Added SendCmioResponse

## [0.12.1] - 2024-08-12
### Changed
- Updated machine-emulator version to v0.18.1

## [0.12.0] - 2024-08-12
### Changed
- Updated machine-emulator version to v0.18.0
- Refactored AccessLogs.writeWord()
- Increased tree leaf log2 size to 5

## [0.11.0] - 2024-04-24
### Added
- Added `uarch-reset` test
- Added support to ECALL and EBREAK

### Changed
- Updated machine-emulator version to v0.17.0
- Restructured code as `templates` and `src`
- Updated reset test and constants
- Updated foundry version and shasum files

### Fixed
- Fixed address and size alignment check

## [0.10.1] - 2024-03-29
### Changed
- Updated machine-emulator version to v0.16.1
- Locked Solc version used with forge

## [0.10.0] - 2024-02-09
### Added
- Support for uarch reset

### Changed
- Updated machine-emulator version to v0.16.0
- Activated immediate error exit in all test scripts
- Updated shasum-mock

### Fixed
- Fixed replay tests with new log format
- Fixed mistakenly commented test code
- Changed directory back before retrieving constants

## [0.9.3] - 2024-01-31
### Changed
- Updated to `machine-emulator 0.15.3`

### Fixed
- Fixed build and test CI workflow

## [0.9.2] - 2023-08-21
### Changed
- Updated to `machine-emulator 0.15.2`

### Fixed
- Fixed `0.9.0` CHANGELOG
- Fixed `package.json` version

## [0.9.1] - 2023-08-17
### Changed
- Updated to `machine-emulator 0.15.1`

## [0.9.0] - 2023-08-16
### Added
- Added `MetaStep` framework, yet without actual implementation

### Changed
- Updated license/copyright notice in all source code
- Rewrote lua script in bash
- Rewrote test to get rid of --via-ir option
- Rewrote log tests with template
- Removed all `npm` dependencies
- Started using node LTS 18.x
- Replaced `downloads` with `checksum` in Makefile
- Dropped `solidity-util` dependency
- Updated to `machine-emulator 0.15.0`
- Updated `step` function to use generic interface and parameters
- Updated all smart contracts to be pure internal libraries
- Configured constants from docker runtime
- Enabled all tests on CI

## [0.8.0] - 2023-05-04
### Changed
- Completely new implementation based on the Cartesi machine emulator microarchitecture.

## [Previous Versions]
- [0.7.0]
- [0.6.0]
- [0.5.0]
- [0.4.0]
- [0.3.0]
- [0.2.0]
- [0.1.0]

[Unreleased]: https://github.com/cartesi/machine-solidity-step/compare/v0.15.0...HEAD
[0.15.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.15.0
[0.14.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.14.0
[0.13.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.13.0
[0.12.1]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.12.1
[0.12.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.12.0
[0.11.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.11.0
[0.10.1]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.10.1
[0.10.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.10.0
[0.9.3]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.9.3
[0.9.2]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.9.2
[0.9.1]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.9.1
[0.9.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.9.0
[0.8.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.8.0
[0.7.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.7.0
[0.6.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.6.0
[0.5.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.5.0
[0.4.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.4.0
[0.3.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.3.0
[0.2.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.2.0
[0.1.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.1.0
