EMULATOR_DIR ?= ../emulator
TEST_DIR := test
DOWNLOADDIR := downloads

BIN_TEST_VERSION ?= v0.28.0
BIN_TEST_DIR := $(TEST_DIR)/uarch-bin
BIN_TEST_FILE := machine-tests-$(BIN_TEST_VERSION).tar.gz
BIN_DOWNLOAD_URL := https://github.com/cartesi/machine-tests/releases/download/$(BIN_TEST_VERSION)/$(BIN_TEST_FILE)
BIN_DOWNLOAD_FILEPATH := $(DOWNLOADDIR)/$(BIN_TEST_FILE)

LOG_TEST_VERSION ?= v0.14.0
LOG_TEST_DIR := $(TEST_DIR)/uarch-log
LOG_TEST_FILE := uarch-riscv-tests-json-logs-$(LOG_TEST_VERSION).tar.gz
LOG_DOWNLOAD_URL := https://github.com/cartesi/machine-emulator/releases/download/$(LOG_TEST_VERSION)/$(LOG_TEST_FILE)
LOG_DOWNLOAD_FILEPATH := $(DOWNLOADDIR)/$(LOG_TEST_FILE)

DOWNLOADFILES := $(BIN_DOWNLOAD_FILEPATH) $(LOG_DOWNLOAD_FILEPATH)

help:
	@echo 'Cleaning targets:'
	@echo '  clean                      - clean the cache artifacts and generated files'
	@echo 'Generic targets:'
	@echo '* all                        - build solidity code. To build from a clean clone, run: make submodules all'
	@echo '  build                      - build solidity code'
	@echo '  generate-all               - generate all solidity code'
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
	@shasum -ca 256 shasumfile

all: build test-all

build: generate-all
	forge build

clean:
	rm -rf src/UArchConstants.sol src/UArchStep.sol test/UArchReplay_*.t.sol
	forge clean

shasumfile: $(DOWNLOADFILES)
	shasum -a 256 $^ > $@

checksum: $(DOWNLOADFILES)
	@shasum -ca 256 shasumfile

pretest: checksum
	@mkdir -p $(BIN_TEST_DIR)
	@mkdir -p $(LOG_TEST_DIR)
	@tar -xzf $(BIN_DOWNLOAD_FILEPATH) -C $(BIN_TEST_DIR)
	@tar -xzf $(LOG_DOWNLOAD_FILEPATH) -C $(LOG_TEST_DIR)
	@rm $(BIN_TEST_DIR)/*.dump $(BIN_TEST_DIR)/*.elf

test-all: | pretest test-mock test-prod test-replay fmt

test-mock: | pretest generate-mock
	forge test -vv --match-contract UArchInterpret

test-prod: | pretest generate-prod
	forge test -vv --no-match-contract "UArchInterpret|UArchReplay"

test-replay: | pretest generate-prod generate-replay
	forge test -vv --match-contract UArchReplay

generate-all: generate-step generate-prod fmt

generate-mock:
	./helper_scripts/generate_AccessLogs.sh mock

generate-prod:
	./helper_scripts/generate_AccessLogs.sh prod

generate-replay:
	./helper_scripts/generate_ReplayTests.sh

generate-step: $(EMULATOR_DIR)/src/uarch-step.h $(EMULATOR_DIR)/src/uarch-step.cpp
	EMULATOR_DIR=$(EMULATOR_DIR) ./helper_scripts/generate_UArchStep.sh
	EMULATOR_DIR=$(EMULATOR_DIR) ./helper_scripts/generate_UArchConstants.sh

fmt:
	forge fmt

submodules:
	git submodule update --init --recursive

.PHONY: help all build clean checksum fmt generate-all generate-mock generate-prod generate-replay generate-step pretest submodules test-all test-mock test-prod test-replay
