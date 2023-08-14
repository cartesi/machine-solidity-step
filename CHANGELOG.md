# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.0] - 2023-08-16
### Fixed
- Fix lua-check warnings
- Fix peer dependencies warning
- Replace `@types/commander` with `commaner`
- Remove and update npm packages for security reason

### Added
- Added `dep` and `depclean` target

### Changed
- Updated license/copyright notice in all source code
- Removed npm-scripts-info package
- Rewrited test to get rid of --via-ir option
- Started using node LTS 18.x
- Updated and remove packages
- Replaced `downloads` with `checksum` in Makefile
- Dropped solidity-util dependency
- Updated to machine-emulator 0.15.0
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

[Unreleased]: https://github.com/cartesi/machine-solidity-step/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.9.0
[0.8.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.8.0
[0.7.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.7.0
[0.6.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.6.0
[0.5.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.5.0
[0.4.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.4.0
[0.3.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.3.0
[0.2.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.2.0
[0.1.0]: https://github.com/cartesi/machine-solidity-step/releases/tag/v0.1.0
