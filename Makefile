EMULATOR_DIR ?= ../emulator
LUA ?= lua5.4
TEST_DIR := test
DOWNLOADDIR := downloads
SRC_DIR := src

EMULATOR_VERSION ?= v0.20.0
EMULATOR_TAG ?=

SOLIDITY_VERSION ?= 0.8.30

TESTS_DATA_FILE ?= machine-emulator-tests-data.deb
TESTS_DATA_DOWNLOAD_URL := https://github.com/cartesi/machine-emulator/releases/download/$(EMULATOR_VERSION)$(EMULATOR_TAG)/$(TESTS_DATA_FILE)
TESTS_DATA_DOWNLOAD_FILEPATH ?= $(DOWNLOADDIR)/$(TESTS_DATA_FILE)
TESTS_DATA_DIR ?= $(TEST_DIR)/uarch-bin

LOG_TEST_FILE ?= uarch-riscv-tests-json-logs.tar.gz
LOG_DOWNLOAD_URL := https://github.com/cartesi/machine-emulator/releases/download/$(EMULATOR_VERSION)$(EMULATOR_TAG)/$(LOG_TEST_FILE)
LOG_DOWNLOAD_FILEPATH := $(DOWNLOADDIR)/$(LOG_TEST_FILE)
LOG_TEST_DIR := $(TEST_DIR)/uarch-log

DOWNLOADFILES := $(TESTS_DATA_DOWNLOAD_FILEPATH) $(LOG_DOWNLOAD_FILEPATH)
GENERATEDFILES := $(SRC_DIR)/*.sol
DEPDIRS = $(TESTS_DATA_DIR) $(LOG_TEST_DIR)

help:
	@echo 'Cleaning targets:'
	@echo '  clean                       - clean the cache artifacts and generated files'
	@echo 'Generic targets:'
	@echo '* all                         - build solidity code. To build from a clean clone, run: make submodules all'
	@echo '  build                       - build solidity code'
	@echo '  generate-step               - generate solidity-step code from cpp'
	@echo '  generate-reset              - generate solidity-reset code from cpp'
	@echo '  generate-send-cmio-response - generate solidity-send-cmio-response code from cpp'
	@echo '  generate-constants          - generate solidity-constants code by querying the cartesi machine'
	@echo '  generate-mock               - generate mock library code'
	@echo '  generate-prod               - generate production library code'
	@echo '  generate-replay             - generate replay tests'
	@echo '  pretest                     - download necessary files for tests'
	@echo '  local-dep                   - use test data from local emulator build'
	@echo '  submodules                  - initialize and update git submodules'
	@echo '  fmt                         - format solidity sources with forge fmt'
	@echo '  test-all                    - test all'
	@echo '  test-transpiler             - test the C++ to Solidity transpiler'
	@echo '  test-mock                   - test binary files with mock library'
	@echo '  test-prod                   - test production code'
	@echo '  test-replay                 - test log files'
	@echo '  env-check                   - check that all required tools are installed'
	@echo 'Coverage targets:'
	@echo '  coverage-mock               - generate coverage info for mock library tests'
	@echo '  coverage-prod               - generate coverage info for production code tests'
	@echo '  coverage-report             - aggregate coverage info and generate html report'


env-check:
	@echo "Checking development environment..."
	@$(LUA) -v 2>&1 || { echo "MISSING: lua5.4 -- see README.md"; exit 1; }
	@$(LUA) -e 'require("lpeg")' 2>/dev/null || { echo "MISSING: lpeg -- see README.md"; exit 1; }
	@forge --version 2>&1 || { echo "MISSING: foundry -- see README.md"; exit 1; }
	@gpp --version >/dev/null 2>&1 || { echo "MISSING: gpp -- see README.md"; exit 1; }
	@$(SED) --version >/dev/null 2>&1 || { echo "MISSING: GNU sed (set SED=gsed on macOS) -- see README.md"; exit 1; }
	@echo "All tools found."

all: build test-all

build: generate-step generate-reset generate-send-cmio-response generate-constants generate-prod
	forge build --use $(SOLIDITY_VERSION)

clean:
	rm -rf test/UArchReplay_*.t.sol
	rm -rf $(DEPDIRS) $(DOWNLOADDIR)
	forge clean

test-transpiler:
	$(LUA) helper_scripts/test_generate_UArchSolidity.lua

test-all: test-transpiler
	$(MAKE) test-mock
	$(MAKE) test-replay
	$(MAKE) test-prod

coverage-mock: dep
	$(MAKE) generate-mock
	forge coverage --use $(SOLIDITY_VERSION) --report lcov --match-contract UArchInterpret
	mv lcov.info lcov-mock.info

coverage-prod: dep
	$(MAKE) generate-prod
	$(MAKE) generate-replay
	forge coverage --use $(SOLIDITY_VERSION) --report lcov --no-match-contract UArchInterpret
	mv lcov.info lcov-prod.info

COVERAGE_OUTPUT_DIR ?= coverage

coverage-report: $(COVERAGE_OUTPUT_DIR)
	lcov -a lcov-mock.info -a lcov-prod.info -o $(COVERAGE_OUTPUT_DIR)/lcov.info
	lcov --summary $(COVERAGE_OUTPUT_DIR)/lcov.info | tee $(COVERAGE_OUTPUT_DIR)/coverage.txt
	genhtml --ignore-errors unmapped $(COVERAGE_OUTPUT_DIR)/lcov.info -o $(COVERAGE_OUTPUT_DIR)/html

$(COVERAGE_OUTPUT_DIR):
	mkdir -p $(COVERAGE_OUTPUT_DIR)

test-mock: dep
	$(MAKE) generate-mock
	forge test --use $(SOLIDITY_VERSION) -vv --match-contract UArchInterpret

test-prod: dep
	$(MAKE) generate-prod
	forge test --use $(SOLIDITY_VERSION) -vv --no-match-contract "UArchInterpret|UArchReplay|UArchReset"

test-replay: dep
	$(MAKE) generate-prod
	$(MAKE) generate-replay
	forge test --use $(SOLIDITY_VERSION) -vv --match-contract "UArchReset|SendCmioResponse|UArchReplay"

generate-mock:
	./helper_scripts/generate_AccessLogs.sh mock
	$(MAKE) fmt

generate-prod:
	./helper_scripts/generate_AccessLogs.sh prod
	$(MAKE) fmt

generate-replay:
	./helper_scripts/generate_ReplayTests.sh
	$(MAKE) fmt

generate-constants: $(EMULATOR_DIR)
	EMULATOR_DIR=$(EMULATOR_DIR) ./helper_scripts/generate_EmulatorConstants.sh

GEN_SOL = $(LUA) helper_scripts/generate_UArchSolidity.lua

generate-step: $(EMULATOR_DIR)/src/uarch-step.hpp $(EMULATOR_DIR)/src/uarch-step.cpp
	$(GEN_SOL) $(EMULATOR_DIR)/src/uarch-step.cpp src/UArchStep.sol UArchStep step
	forge fmt src/UArchStep.sol

generate-reset: $(EMULATOR_DIR)/src/uarch-reset-state.cpp
	$(GEN_SOL) $(EMULATOR_DIR)/src/uarch-reset-state.cpp src/UArchReset.sol UArchReset reset
	forge fmt src/UArchReset.sol

generate-send-cmio-response: $(EMULATOR_DIR)/src/send-cmio-response.cpp
	$(GEN_SOL) $(EMULATOR_DIR)/src/send-cmio-response.cpp src/SendCmioResponse.sol SendCmioResponse sendCmioResponse
	forge fmt src/SendCmioResponse.sol

fmt:
	forge fmt src test

download: $(DOWNLOADDIR)

pretest: dep

dep: $(DEPDIRS)

EMULATOR_TESTS_DIR = $(EMULATOR_DIR)/tests
EMULATOR_UARCH_BIN_DIR = $(EMULATOR_TESTS_DIR)/build/uarch
EMULATOR_UARCH_LOG_DIR = $(EMULATOR_TESTS_DIR)/build/uarch-riscv-tests-json-logs

local-dep: $(EMULATOR_UARCH_BIN_DIR) $(EMULATOR_UARCH_LOG_DIR)
	rm -rf $(TESTS_DATA_DIR) $(LOG_TEST_DIR)
	mkdir -p $(TESTS_DATA_DIR) $(LOG_TEST_DIR)
	cp $(EMULATOR_UARCH_BIN_DIR)/*.bin $(TESTS_DATA_DIR)/
	cp $(EMULATOR_UARCH_LOG_DIR)/*.json $(LOG_TEST_DIR)/

$(DOWNLOADDIR):
	@mkdir -p $(DOWNLOADDIR)
	@wget -nc $(TESTS_DATA_DOWNLOAD_URL) -P $(DOWNLOADDIR)
	@wget -nc $(LOG_DOWNLOAD_URL) -P $(DOWNLOADDIR)
	$(MAKE) checksum-download

shasum-download:
	shasum -a 256 $(DOWNLOADFILES) > shasum-download

checksum-download:
	@shasum -ca 256 shasum-download

$(TESTS_DATA_DIR): | download
	@mkdir -p $(TESTS_DATA_DIR)
	@ar p $(TESTS_DATA_DOWNLOAD_FILEPATH) data.tar.xz | tar -xJf - --strip-components=7 -C $(TESTS_DATA_DIR) ./usr/share/cartesi-machine/tests/data/uarch
	@rm -f $(TESTS_DATA_DIR)/*.dump $(TESTS_DATA_DIR)/*.elf

$(LOG_TEST_DIR): | download
	@mkdir -p $(LOG_TEST_DIR)
	@tar --no-same-owner -xzf $(LOG_DOWNLOAD_FILEPATH) --strip-components=1 -C $(LOG_TEST_DIR)

submodules:
	git submodule update --init --recursive

.PHONY: help all build clean checksum-download shasum-download fmt generate-mock generate-prod generate-replay generate-step download pretest dep local-dep submodules test-all test-mock test-prod test-replay test-transpiler env-check generate-constants generate-reset generate-send-cmio-response coverage-mock coverage-prod coverage-report
