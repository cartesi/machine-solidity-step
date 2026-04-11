#!/usr/bin/env lua5.4

package.path = "helper_scripts/?.lua;" .. package.path
local gen = require("generate_UArchSolidity")

local pass, fail = 0, 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        pass = pass + 1
    else
        fail = fail + 1
        io.stderr:write("FAIL: " .. name .. "\n  " .. tostring(err) .. "\n")
    end
end

local function normalize(s)
    -- Remove comments and extra whitespace for easier comparison
    s = s:gsub("//[^\n]*", "")
    s = s:gsub("%s+", " ")
    s = s:gsub("^ ", ""):gsub(" $", "")
    return s
end

local function assert_transpiles(input_cpp, input_h, lib, entry, expected_sol)
    local result = gen.transpile(input_cpp, input_h, lib, entry)
    local actual = normalize(result:sub(#gen.LICENSE_BANNER + 1))
    local expected = normalize(expected_sol)
    assert(actual == expected,
        "\nexpected:\n" .. expected .. "\n\ngot:\n" .. actual)
end


test("uarch-step", function()
    local input_cpp = [==[
        // Copyright Cartesi and individual authors (see AUTHORS)
        // SPDX-License-Identifier: LGPL-3.0-or-later

        #include "uarch-step.h"
        #include "uarch-record-state-access.h"   // IWYU pragma: keep
        #include "uarch-solidity-compat.h"

        // NOLINTBEGIN(google-readability-casting,misc-const-correctness)
        namespace cartesi {

        template  < typename UarchState >
        static  inline  uint64 readUint64(const  UarchState  a, uint64 paddr) {
            return readWord(a, paddr);
        }

        template	<typename UarchState>
        static inline void executeLUI(const UarchState a, uint32 insn, uint64 pc) {
            [[maybe_unused]]   auto note = dumpInsn(a, pc, insn,
                "lui");
            (void)
                note;
            constexpr  uint32 mask = 0xfffff000;
            const  uint64 imm = int32ToUint64(int32(insn) & int32(mask));
            uint8 rd = operandRd(insn);
        }

        template <typename UarchState>
        UArchStepStatus uarch_step(const	UarchState a) {
            uint64 cycle = readCycle(a);
            if (cycle >= UINT64_MAX) {
                return UArchStepStatus::CycleOverflow;
            }
        }

        // Explicit instantiation for uarch_state_access
        template UArchStepStatus uarch_step(const uarch_state_access a);
        // Explicit instantiation for uarch_record_state_access
        template UArchStepStatus uarch_step(const uarch_record_state_access a);
        }
        // NOLINTEND(google-readability-casting,misc-const-correctness)
    ]==]
    local input_h = "enum class UArchStepStatus : int { Success, CycleOverflow, UArchHalted };"

    local expected_sol = [=[
        pragma solidity ^0.8.30;
        import "./EmulatorCompat.sol";

        library UArchStep {
            enum UArchStepStatus { Success, CycleOverflow, UArchHalted }

            function readUint64(AccessLogs.Context memory a, uint64 paddr) private pure returns (uint64) {
                return EmulatorCompat.readWord(a, paddr);
            }

            function executeLUI(AccessLogs.Context memory a, uint32 insn, uint64 pc) private pure {
                uint32 mask = 0xfffff000;
                uint64 imm = EmulatorCompat.int32ToUint64(int32(insn) & int32(mask));
                uint8 rd = operandRd(insn);
            }

            function step(AccessLogs.Context memory a) internal pure returns (UArchStepStatus) {
                uint64 cycle = EmulatorCompat.readCycle(a);
                if (cycle >= type(uint64).max) {
                    return UArchStepStatus.CycleOverflow;
                }
            }
        }
    ]=]

    assert_transpiles(input_cpp, input_h, "UArchStep", "step", expected_sol)
end)


test("uarch-reset-state", function()
    local input_cpp = [==[
        // Copyright Cartesi and individual authors (see AUTHORS)
        // SPDX-License-Identifier: LGPL-3.0-or-later

        #include "uarch-reset-state.h"
        #include "uarch-record-state-access.h"   // IWYU pragma: keep
        #include "uarch-solidity-compat.h"

        namespace cartesi {

        template <typename UarchState>
        void uarch_reset_state(UarchState &a) {
            resetState(a);
        }

        // edge cases: no params, empty body
        static inline void noop() {}

        // Explicit instantiation for uarch_state_access
        template void uarch_reset_state(uarch_state_access &a);
        // Explicit instantiation for uarch_record_state_access
        template void uarch_reset_state(uarch_record_state_access &a);
        }
        // NOLINTEND(google-readability-casting,misc-const-correctness)
    ]==]

    local expected_sol = [=[
        pragma solidity ^0.8.30;
        import "./EmulatorCompat.sol";

        library UArchReset {
            function reset(AccessLogs.Context memory a) internal pure {
                EmulatorCompat.resetState(a);
            }

            function noop() private pure {}
        }
    ]=]

    assert_transpiles(input_cpp, nil, "UArchReset", "reset", expected_sol)
end)


test("send-cmio-response", function()
    local input_cpp = [==[
        // Copyright Cartesi and individual authors (see AUTHORS)
        // SPDX-License-Identifier: LGPL-3.0-or-later

        #include "send-cmio-response.h"
        #include "uarch-solidity-compat.h"

        // NOLINTBEGIN(google-readability-casting,misc-const-correctness)
        namespace cartesi {

        template <typename STATE_ACCESS>
        void send_cmio_response(STATE_ACCESS a, uint16 reason, bytes data, uint32 dataLength) {
            if (dataLength > 0) {
                uint32 writeLengthLog2Size = uint32Log2(dataLength);
                writeMemoryWithPadding(a, AR_CMIO_RX_BUFFER_START, data, dataLength, writeLengthLog2Size);
            }
            throwRuntimeError(a, "CMIO response data is too large");
            writeHtifFromhost(a, 0);
            writeIflagsY(a, 0);
        }

        // Explicit instantiation for state_access
        template void send_cmio_response(state_access a, uint16_t reason, const unsigned char *data, uint32 length);
        // Explicit instantiation for record_state_access
        template void send_cmio_response(record_send_cmio_state_access a, uint16_t reason, const unsigned char *data,
            uint32 length);
        }
        // NOLINTEND(google-readability-casting,misc-const-correctness)
    ]==]

    local expected_sol = [=[
        pragma solidity ^0.8.30;
        import "./EmulatorCompat.sol";

        library SendCmioResponse {
            function sendCmioResponse(AccessLogs.Context memory a, uint16 reason, bytes32 dataHash, uint32 dataLength) internal pure {
                if (dataLength > 0) {
                    uint32 writeLengthLog2Size = EmulatorCompat.uint32Log2(dataLength);
                    EmulatorCompat.writeMemoryWithPadding(a, EmulatorConstants.AR_CMIO_RX_BUFFER_START, dataHash, dataLength, writeLengthLog2Size);
                }
                EmulatorCompat.throwRuntimeError(a, "CMIO response data is too large");
                EmulatorCompat.writeHtifFromhost(a, 0);
                EmulatorCompat.writeIflagsY(a, 0);
            }
        }
    ]=]

    assert_transpiles(input_cpp, nil, "SendCmioResponse", "sendCmioResponse", expected_sol)
end)


print(string.format("\n%d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
