EMULATOR_DIR ?= ../emulator
TEST_DIR := test
DOWNLOADDIR := downloads
SRC_DIR := src

EMULATOR_VERSION ?= v0.16.1

TESTS_DATA_FILE ?= cartesi-machine-tests-data-$(EMULATOR_VERSION).deb
TESTS_DATA_DOWNLOAD_URL := https://github.com/cartesi/machine-emulator/releases/download/$(EMULATOR_VERSION)/$(TESTS_DATA_FILE)
TESTS_DATA_DOWNLOAD_FILEPATH ?= $(DOWNLOADDIR)/$(TESTS_DATA_FILE)
TESTS_DATA_DIR ?= $(TEST_DIR)/uarch-bin

LOG_TEST_FILE ?= uarch-riscv-tests-json-logs-$(EMULATOR_VERSION).tar.gz
LOG_DOWNLOAD_URL := https://github.com/cartesi/machine-emulator/releases/download/$(EMULATOR_VERSION)/$(LOG_TEST_FILE)
LOG_DOWNLOAD_FILEPATH := $(DOWNLOADDIR)/$(LOG_TEST_FILE)
LOG_TEST_DIR := $(TEST_DIR)/uarch-log

DOWNLOADFILES := $(TESTS_DATA_DOWNLOAD_FILEPATH) $(LOG_DOWNLOAD_FILEPATH)
GENERATEDFILES := $(SRC_DIR)/*.sol

help:
	@echo 'Cleaning targets:'
	@echo '  clean                      - clean the cache artifacts and generated files'
	@echo 'Generic targets:'
	@echo '* all                        - build solidity code. To build from a clean clone, run: make submodules all'
	@echo '  build                      - build solidity code'
	@echo '  generate-step              - generate solidity-step code from cpp'
	@echo '  generate-reset             - generate solidity-reset code from cpp'
	@echo '  generate-constants         - generate solidity-constants code by querying the cartesi machine'
	@echo '  generate-mock              - generate mock library code'
	@echo '  generate-prod              - generate production library code'
	@echo '  generate-replay            - generate replay tests'
	@echo '  pretest                    - download necessary files for tests'
	@echo '  test-all                   - test all'
	@echo '  test-mock                  - test binary files with mock library'
	@echo '  test-prod                  - test production code'
	@echo '  test-replay                - test log files'

$(TESTS_DATA_DOWNLOAD_FILEPATH):
	@mkdir -p $(DOWNLOADDIR)
	@wget -nc $(TESTS_DATA_DOWNLOAD_URL) -P $(DOWNLOADDIR)

$(LOG_DOWNLOAD_FILEPATH):
	@mkdir -p $(DOWNLOADDIR)
	@wget -nc $(LOG_DOWNLOAD_URL) -P $(DOWNLOADDIR)

all: build test-all

build: generate-step generate-reset generate-constants
	forge build --use 0.8.21

clean:
	rm -rf src/AccessLogs.sol test/UArchReplay_*.t.sol
	rm -rf $(TESTS_DATA_DIR) $(LOG_TEST_DIR) $(DOWNLOADDIR)
	forge clean

shasum-download: $(DOWNLOADFILES)
	shasum -a 256 $^ > $@

shasum-generated: $(GENERATEDFILES)
	shasum -a 256 $^ > $@

checksum-download: $(DOWNLOADFILES)
	@shasum -ca 256 shasum-download

checksum-mock:
	@shasum -ca 256 shasum-mock

checksum-prod:
	@shasum -ca 256 shasum-prod

pretest: checksum-download
	mkdir -p $(TESTS_DATA_DIR) $(LOG_TEST_DIR)
	ar p $(TESTS_DATA_DOWNLOAD_FILEPATH) data.tar.xz | tar -xJf - --strip-components=7 -C $(TESTS_DATA_DIR) ./usr/share/cartesi-machine/tests/data/uarch
	tar -xzf $(LOG_DOWNLOAD_FILEPATH) --strip-components=1 -C $(LOG_TEST_DIR)
	rm -f $(TESTS_DATA_DIR)/*.dump $(TESTS_DATA_DIR)/*.elf

test-all:
	$(MAKE) test-mock
	$(MAKE) test-prod
	$(MAKE) test-replay

test-mock: pretest
	$(MAKE) generate-mock
	forge test --use 0.8.21 -vv --match-contract UArchInterpret

test-prod: pretest
	$(MAKE) generate-prod
	forge test --use 0.8.21 -vv --no-match-contract "UArchInterpret|UArchReplay|UArchReset"

test-replay: pretest
	$(MAKE) generate-prod
	$(MAKE) generate-replay
	forge test --use 0.8.21 -vv --match-contract "UArchReplay|UArchReset"

generate-mock:
	./helper_scripts/generate_AccessLogs.sh mock
	$(MAKE) fmt
	$(MAKE) checksum-mock

generate-prod:
	./helper_scripts/generate_AccessLogs.sh prod
	$(MAKE) fmt
	$(MAKE) checksum-prod

generate-replay:
	./helper_scripts/generate_ReplayTests.sh
	$(MAKE) fmt

generate-constants: $(EMULATOR_DIR)
	EMULATOR_DIR=$(EMULATOR_DIR) ./helper_scripts/generate_UArchConstants.sh

generate-step: $(EMULATOR_DIR)/src/uarch-step.h $(EMULATOR_DIR)/src/uarch-step.cpp
	EMULATOR_DIR=$(EMULATOR_DIR) ./helper_scripts/generate_UArchStep.sh

generate-reset: $(EMULATOR_DIR)/src/uarch-reset-state.cpp
	EMULATOR_DIR=$(EMULATOR_DIR) ./helper_scripts/generate_UArchReset.sh

fmt:
	forge fmt src test

submodules:
	git submodule update --init --recursive

.PHONY: help all build clean checksum-download checksum-mock checksum-prod fmt generate-mock generate-prod generate-replay generate-step pretest submodules test-all test-mock test-prod test-replay generate-constants generate-reset
