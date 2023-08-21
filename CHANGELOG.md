# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.2] - 2023-08-21
### Changed
- Fixed `0.9.0` CHANGELOG
- Fixed `package.json` version
- Updated to `machine-emulator 0.15.2`

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
- Updated all smart contracts to be pure interal libraries
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

[Unreleased]: https://github.com/cartesi/machine-solidity-step/compare/v0.9.2...HEAD
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
