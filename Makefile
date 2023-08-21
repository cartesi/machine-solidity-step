EMULATOR_DIR ?= ../emulator
TEST_DIR := test
DOWNLOADDIR := downloads
READY_SRC_DIR := ready_src

BIN_TEST_VERSION ?= v0.29.0
BIN_TEST_DIR := $(TEST_DIR)/uarch-bin
BIN_TEST_FILE := machine-tests-$(BIN_TEST_VERSION).tar.gz
BIN_DOWNLOAD_URL := https://github.com/cartesi/machine-tests/releases/download/$(BIN_TEST_VERSION)/$(BIN_TEST_FILE)
BIN_DOWNLOAD_FILEPATH := $(DOWNLOADDIR)/$(BIN_TEST_FILE)

LOG_TEST_VERSION ?= v0.15.2
LOG_TEST_DIR := $(TEST_DIR)/uarch-log
LOG_TEST_FILE := uarch-riscv-tests-json-logs-$(LOG_TEST_VERSION).tar.gz
LOG_DOWNLOAD_URL := https://github.com/cartesi/machine-emulator/releases/download/$(LOG_TEST_VERSION)/$(LOG_TEST_FILE)
LOG_DOWNLOAD_FILEPATH := $(DOWNLOADDIR)/$(LOG_TEST_FILE)

DOWNLOADFILES := $(BIN_DOWNLOAD_FILEPATH) $(LOG_DOWNLOAD_FILEPATH)
GENERATEDFILES := $(READY_SRC_DIR)/*.sol

help:
	@echo 'Cleaning targets:'
	@echo '  clean                      - clean the cache artifacts and generated files'
	@echo 'Generic targets:'
	@echo '* all                        - build solidity code. To build from a clean clone, run: make submodules all'
	@echo '  build                      - build solidity code'
	@echo '  generate-step              - generate solidity-step code from cpp'
	@echo '  generate-mock              - generate mock library code'
	@echo '  generate-prod              - generate production library code'
	@echo '  generate-replay            - generate replay tests'
	@echo '  pretest                    - download necessary files for tests'
	@echo '  test-all                   - test all'
	@echo '  test-mock                  - test binary files with mock library'
	@echo '  test-prod                  - test production code'
	@echo '  test-replay                - test log files'

$(BIN_DOWNLOAD_FILEPATH):
	@mkdir -p $(DOWNLOADDIR)
	@wget -nc $(BIN_DOWNLOAD_URL) -P $(DOWNLOADDIR)

$(LOG_DOWNLOAD_FILEPATH):
	@mkdir -p $(DOWNLOADDIR)
	@wget -nc $(LOG_DOWNLOAD_URL) -P $(DOWNLOADDIR)

all: build test-all

build: generate-step
	forge build

clean:
	rm -rf src/UArchConstants.sol src/UArchStep.sol test/UArchReplay_*.t.sol
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
	@mkdir -p $(BIN_TEST_DIR)
	@mkdir -p $(LOG_TEST_DIR)
	@tar -xzf $(BIN_DOWNLOAD_FILEPATH) -C $(BIN_TEST_DIR)
	@tar -xzf $(LOG_DOWNLOAD_FILEPATH) -C $(LOG_TEST_DIR)
	@rm $(BIN_TEST_DIR)/*.dump $(BIN_TEST_DIR)/*.elf

test-all:
	$(MAKE) test-mock
	$(MAKE) test-prod
	$(MAKE) test-replay

test-mock: pretest
	$(MAKE) generate-mock
	forge test -vv --match-contract UArchInterpret

test-prod: pretest
	$(MAKE) generate-prod
	forge test -vv --no-match-contract "UArchInterpret|UArchReplay"

test-replay: pretest
	$(MAKE) generate-prod
	$(MAKE) generate-replay
	forge test -vv --match-contract UArchReplay

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

generate-step: $(EMULATOR_DIR)/src/uarch-step.h $(EMULATOR_DIR)/src/uarch-step.cpp
	EMULATOR_DIR=$(EMULATOR_DIR) ./helper_scripts/generate_UArchStep.sh
	EMULATOR_DIR=$(EMULATOR_DIR) ./helper_scripts/generate_UArchConstants.sh
	$(MAKE) generate-prod

fmt:
	forge fmt

submodules:
	git submodule update --init --recursive

.PHONY: help all build clean checksum-download checksum-mock checksum-prod fmt generate-mock generate-prod generate-replay generate-step pretest submodules test-all test-mock test-prod test-replay
