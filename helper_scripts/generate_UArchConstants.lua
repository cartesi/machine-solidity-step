#!/usr/bin/lua5.4

-- This scripts generates a snippet of solidity code to be inserted
-- in the UarchConstants.sol file.

local cartesi = require("cartesi")

local function hex(n)
    return string.format("%x", n)
end

local function hexstring(hash)
    return (string.gsub(hash, ".", function(c) return string.format("%02x", string.byte(c)) end))
end

local out = io.stdout

out:write('    uint64 constant UCYCLE = 0x' .. hex(cartesi.machine.get_csr_address("uarch_cycle")) .. ';\n')
out:write('    uint64 constant UHALT = 0x' .. hex(cartesi.machine.get_csr_address("uarch_halt_flag")) .. ';\n')
out:write('    uint64 constant UPC = 0x' .. hex(cartesi.machine.get_csr_address("uarch_pc")) .. ';\n')
out:write('    uint64 constant UX0 = 0x' .. hex(cartesi.machine.get_uarch_x_address(0)) .. ';\n')
out:write('    uint64 constant UARCH_SHADOW_START_ADDRESS = 0x' .. hex(cartesi.UARCH_SHADOW_START_ADDRESS) .. ';\n')
out:write('    uint64 constant UARCH_SHADOW_LENGTH = 0x' .. hex(cartesi.UARCH_SHADOW_LENGTH) .. ';\n')
out:write('    uint64 constant UARCH_RAM_START_ADDRESS = 0x' .. hex(cartesi.UARCH_RAM_START_ADDRESS) .. ';\n')
out:write('    uint64 constant UARCH_RAM_LENGTH = 0x' .. hex(cartesi.UARCH_RAM_LENGTH) .. ';\n')
out:write('    uint64 constant RESET_POSITION = 0x' .. hex(cartesi.UARCH_STATE_START_ADDRESS) .. ';\n')
out:write('    uint8 constant RESET_ALIGNED_SIZE = ' .. cartesi.UARCH_STATE_LOG2_SIZE .. ';\n')
out:write('    bytes32 constant PRESTINE_STATE = 0x' .. hexstring(cartesi.UARCH_PRISTINE_STATE_HASH) .. ';\n')

out:close()
