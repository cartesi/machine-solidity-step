#!/usr/bin/lua5.4

-- This scripts generates a snippet of solidity code to be inserted
-- in the EmulatorhConstants.sol file.

local cartesi = require("cartesi")

local function hex(n)
    return string.format("%x", n)
end

local function hexstring(hash)
    return (string.gsub(hash, ".", function(c) return string.format("%02x", string.byte(c)) end))
end

local out = io.stdout

out:write('    uint64 constant UARCH_CYCLE_ADDRESS = 0x' .. hex(cartesi.machine.get_csr_address("uarch_cycle")) .. ';\n')
out:write('    uint64 constant UARCH_HALT_FLAG_ADDRESS = 0x' ..
    hex(cartesi.machine.get_csr_address("uarch_halt_flag")) .. ';\n')
out:write('    uint64 constant UARCH_PC_ADDRESS = 0x' .. hex(cartesi.machine.get_csr_address("uarch_pc")) .. ';\n')
out:write('    uint64 constant UARCH_X0_ADDRESS = 0x' .. hex(cartesi.machine.get_uarch_x_address(0)) .. ';\n')
out:write('    uint64 constant UARCH_SHADOW_START_ADDRESS = 0x' .. hex(cartesi.UARCH_SHADOW_START_ADDRESS) .. ';\n')
out:write('    uint64 constant UARCH_SHADOW_LENGTH = 0x' .. hex(cartesi.UARCH_SHADOW_LENGTH) .. ';\n')
out:write('    uint64 constant UARCH_RAM_START_ADDRESS = 0x' .. hex(cartesi.UARCH_RAM_START_ADDRESS) .. ';\n')
out:write('    uint64 constant UARCH_RAM_LENGTH = 0x' .. hex(cartesi.UARCH_RAM_LENGTH) .. ';\n')
out:write('    uint64 constant UARCH_STATE_START_ADDRESS = 0x' .. hex(cartesi.UARCH_STATE_START_ADDRESS) .. ';\n')
out:write('    uint8 constant UARCH_STATE_LOG2_SIZE = ' .. cartesi.UARCH_STATE_LOG2_SIZE .. ';\n')
out:write('    bytes32 constant UARCH_PRISTINE_STATE_HASH = 0x' .. hexstring(cartesi.UARCH_PRISTINE_STATE_HASH) .. ';\n')
out:write('    uint64 constant UARCH_ECALL_FN_HALT = ' .. cartesi.UARCH_ECALL_FN_HALT .. ';\n')
out:write('    uint64 constant UARCH_ECALL_FN_PUTCHAR = ' .. cartesi.UARCH_ECALL_FN_PUTCHAR .. ';\n')
out:write('    uint64 constant IFLAGS_ADDRESS = 0x' .. hex(cartesi.machine.get_csr_address("iflags")) .. ';\n')
out:write('    uint64 constant HTIF_FROMHOST_ADDRESS = 0x' ..
    hex(cartesi.machine.get_csr_address("htif_fromhost")) .. ';\n')
out:write('    uint8 constant HTIF_YIELD_REASON_ADVANCE_STATE = 0x' ..
    hex(cartesi.machine.HTIF_YIELD_REASON_ADVANCE_STATE) .. ';\n')
out:write('    uint32 constant TREE_LOG2_WORD_SIZE = 0x' .. hex(cartesi.TREE_LOG2_WORD_SIZE) .. ';\n')
out:write('    uint32 constant TREE_WORD_SIZE = uint32(1) << TREE_LOG2_WORD_SIZE;\n')
out:write('    uint64 constant PMA_CMIO_RX_BUFFER_START = 0x' .. hex(cartesi.PMA_CMIO_RX_BUFFER_START) .. ';\n')
out:write('    uint8 constant PMA_CMIO_RX_BUFFER_LOG2_SIZE = 0x' .. hex(cartesi.PMA_CMIO_RX_BUFFER_LOG2_SIZE) .. ';\n')
out:close()

out:close()
