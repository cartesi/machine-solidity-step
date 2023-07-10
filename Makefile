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
	@echo '  clean                      - clean the cache artifacts'
	@echo 'Generic targets:'
	@echo '* all                        - build solidity code. To build from a clean clone, run: make submodules all'
	@echo '  build                      - build solidity code'
	@echo '  generate                   - generate solidity code from cpp and template'
	@echo '  test                       - test both binary files and general functionalities'
	@echo '  test-replay                - test log files'

$(BIN_DOWNLOAD_FILEPATH):
	@mkdir -p $(DOWNLOADDIR)
	@wget -nc $(BIN_DOWNLOAD_URL) -P $(DOWNLOADDIR)

$(LOG_DOWNLOAD_FILEPATH):
	@mkdir -p $(DOWNLOADDIR)
	@wget -nc $(LOG_DOWNLOAD_URL) -P $(DOWNLOADDIR)
	@shasum -ca 256 shasumfile

all: build test

build: generate
	forge build

clean:
	rm -rf cache foundry_artifacts

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

test: pretest
	./helper_scripts/generate_AccessLogs.sh mock
	forge test -vv --match-contract UArchInterpret
	./helper_scripts/generate_AccessLogs.sh prod
	forge test -vv --no-match-contract "UArchInterpret|UArchReplay"
	forge fmt

test-replay: pretest
	./helper_scripts/generate_AccessLogs.sh prod
	./helper_scripts/test_replays.sh
	forge fmt

generate: $(EMULATOR_DIR)/src/uarch-execute-insn.h
	EMULATOR_DIR=$(EMULATOR_DIR) ./helper_scripts/generate_UArchExecuteInsn.sh
	./helper_scripts/generate_AccessLogs.sh prod
	forge fmt

submodules:
	git submodule update --init --recursive

.PHONY: help all build clean checksum deploy test test-replay generate submodules
