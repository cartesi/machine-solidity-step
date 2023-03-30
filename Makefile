EMULATOR_DIR=../machine-emulator
TEST_BIN_DIR=test/uarch-bin
DOWNLOADDIR=downloads
TEST_VERSION=v0.26.0-uarch
DOWNLOAD_URL=https://github.com/cartesi-corp/machine-tests/releases/download/$(TEST_VERSION)/machine-tests-$(TEST_VERSION).tar.gz

help:
	@echo 'Cleaning targets:'
	@echo '  clean                      - clean the cache artifacts'
	@echo 'Generic targets:'
	@echo '* all                        - build solidity code. To build from a clean clone, run: make submodules downloads all'
	@echo '  build                      - build solidity code'
	@echo '  deploy                     - deploy to local node'
	@echo '  generate                   - generate solidity code from cpp and template'
	@echo '  test                       - test with binary files'

$(DOWNLOADDIR):
	@mkdir -p $(DOWNLOADDIR)
	@wget -nc $(DOWNLOAD_URL) -P $(DOWNLOADDIR)

all: generate build test

build clean deploy:
	yarn $@

downloads: $(DOWNLOADDIR)

test: downloads
	mkdir -p $(TEST_BIN_DIR)
	tar -xzf $(DOWNLOADDIR)/machine-tests-${TEST_VERSION}.tar.gz -C $(TEST_BIN_DIR)
	rm $(TEST_BIN_DIR)/*.dump $(TEST_BIN_DIR)/*.elf
	forge test -vv

generate: $(EMULATOR_DIR)/src/uarch-execute-insn.h
	EMULATOR_DIR=$(EMULATOR_DIR) lua translator/generate-UArchExecuteInsn.lua
	yarn prettier -w

submodules:
	git submodule update --init --recursive

.PHONY: help all build clean deploy downloads test generate submodules
