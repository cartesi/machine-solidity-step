EMULATOR_DIR ?= ../emulator
TEST_DIR := test
DOWNLOADDIR := downloads
SRC_DIR := src

EMULATOR_VERSION ?= v0.19.0
EMULATOR_TAG ?=

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
	@echo '  test-all                    - test all'
	@echo '  test-mock                   - test binary files with mock library'
	@echo '  test-prod                   - test production code'
	@echo '  test-replay                 - test log files'


all: build test-all

build: generate-step generate-reset generate-send-cmio-response generate-constants generate-prod
	forge build  --use 0.8.21

clean:
	rm -rf test/UArchReplay_*.t.sol
	rm -rf $(DEPDIRS) $(DOWNLOADDIR)
	forge clean

test-all:
	$(MAKE) test-mock
	$(MAKE) test-replay
	$(MAKE) test-prod

test-mock: dep
	$(MAKE) generate-mock
	forge test --use 0.8.21 -vv --match-contract UArchInterpret

test-prod: dep
	$(MAKE) generate-prod
	forge test --use 0.8.21 -vv --no-match-contract "UArchInterpret|UArchReplay|UArchReset"

test-replay: dep
	$(MAKE) generate-prod
	$(MAKE) generate-replay
	forge test --use 0.8.21 -vv --match-contract "UArchReset|SendCmioResponse|UArchReplay"

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

generate-step: $(EMULATOR_DIR)/src/uarch-step.h $(EMULATOR_DIR)/src/uarch-step.cpp
	EMULATOR_DIR=$(EMULATOR_DIR) ./helper_scripts/generate_UArchStep.sh

generate-reset: $(EMULATOR_DIR)/src/uarch-reset-state.cpp
	EMULATOR_DIR=$(EMULATOR_DIR) ./helper_scripts/generate_UArchReset.sh

generate-send-cmio-response: $(EMULATOR_DIR)/src/uarch-reset-state.cpp
	EMULATOR_DIR=$(EMULATOR_DIR) ./helper_scripts/generate_SendCmioResponse.sh

fmt:
	forge fmt src test


download: $(DOWNLOADDIR)

dep: $(DEPDIRS)

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
	@tar -xzf $(LOG_DOWNLOAD_FILEPATH) --strip-components=1 -C $(LOG_TEST_DIR)

submodules:
	git submodule update --init --recursive

.PHONY: help all build clean checksum-download shasum-download fmt generate-mock generate-prod generate-replay generate-step pretest submodules test-all test-mock test-prod test-replay generate-constants generate-reset generate-send-cmio-response
