#!/usr/bin/env lua5.4
-- Transpiles the emulator's uarch C++ files to Solidity. Not a general-purpose C++ parser.
-- The patterns here match the specific conventions in those files; if the C++ changes style,
-- update the transpiler to match rather than making it handle all possible C++.

local lpeg = require("lpeg")
local P, R, S, V, C, Cs = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.C, lpeg.Cs

local M = {}

M.LICENSE_BANNER = [=[// Copyright Cartesi and individual authors (see AUTHORS)
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//]=]

local ws    = S(" \t")
local nl    = P("\n")
local ident = (R("az","AZ") + P("_")) * (R("az","AZ","09") + P("_"))^0

local function extract_namespace_body(src)
    local pattern = (1 - P("namespace cartesi"))^0
                  * P("namespace cartesi") * ws^0
                  * P{ "{" * C(((1 - S("{}")) + V(1))^0) * "}" }
    return assert(pattern:match(src), "namespace cartesi not found")
end

local function strip_cpp_only(src)
    local rest_of_line    = (1 - nl)^0 * nl
    local until_semicolon = (1 - P(";"))^0 * P(";") * ws^0 * nl^-1
    local pattern = Cs((
          (ws^0 * P("template") * ws^0 * P("<") * (1 - P(">"))^0 * P(">") * ws^0) / ""
        + (ws^0 * P("template") * until_semicolon) / ""
        + (ws^0 * P("[[maybe_unused]]") * until_semicolon) / ""
        + (ws^0 * P("(void)") * S(" \t\n")^1 * P("note") * until_semicolon) / ""
        + (ws^0 * P("// Explicit instantiat") * rest_of_line) / ""
        + (P("constexpr") * ws^1) / ""
        + 1
    )^0)
    return pattern:match(src)
end

local function convert_fn_signatures(src, entrypoint)
    local static_inline = P("static") * ws^1 * P("inline") * ws^1
    local leading_ws    = C(ws^0)
    local return_type   = C(ident)
    local func_name     = C(ident)
    local param_list    = P("(") * C((1 - P(")"))^0) * P(")")
    local open_brace    = P("{")
    local fn_sig = leading_ws * static_inline^-1
                 * return_type * ws^1 * func_name
                 * ws^0 * param_list
                 * ws^0 * open_brace
    local rewrite = fn_sig / function(indent, ret_type, name, params)
        params = params:gsub("const%s+UarchState%s+a",            "AccessLogs.Context memory a")
        params = params:gsub("UarchState%s+&a",                   "AccessLogs.Context memory a")
        params = params:gsub("STATE_ACCESS%s+a",                  "AccessLogs.Context memory a")
        params = params:gsub("bytes%s+data",                      "bytes32 dataHash")
        params = params:gsub("const%s+unsigned%s+char%s+%%*data", "bytes32 dataHash")
        local fn_renames = {
            uarch_step = "step",
            send_cmio_response = "sendCmioResponse",
            uarch_reset_state = "reset",
        }
        name = fn_renames[name] or name
        local visibility = name == entrypoint and "internal" or "private"
        local ret = ret_type ~= "void" and (" returns (" .. ret_type .. ")") or ""
        return indent .. "function " .. name .. "(" .. params .. ") " .. visibility .. " pure" .. ret .. " {"
    end
    return Cs((rewrite + 1)^0):match(src)
end

local function transform_code(src, fn)
    local strings  = P('"') * (P('\\') * 1 + (1 - P('"')))^0 * P('"')
    local comments  = P("//") * (1 - nl)^0
    local not_string_or_comment = (1 - strings - comments)^1
    local code = C(not_string_or_comment) / fn
    return Cs((strings + comments + code)^0):match(src)
end

local function cpp_to_solidity_syntax(src)
    return transform_code(src, function(code)
        code = code:gsub("const%s+(u?int%d+)", "%1")
        code = code:gsub("::", ".")
        code = code:gsub("UINT64_MAX", "type(uint64).max")
        return code
    end)
end

local function prefix_names(src, names, prefix)
    return transform_code(src, function(code)
        for name in pairs(names) do
            code = code:gsub("%f[%w]" .. name .. "%f[%W]", prefix .. name)
        end
        return code
    end)
end

local function extract_names(src, pattern)
    local t = {}
    for name in src:gmatch(pattern) do t[name] = true end
    return t
end

local script_dir = debug.getinfo(1, "S").source:match("^@(.*/)")  or "./"
local src_dir = script_dir .. "../src/"

local function read_file(path)
    local f <close> = assert(io.open(path, "r"))
    return f:read("a")
end

function M.transpile(cpp_src, h_src, lib_name, entrypoint)
    local body = extract_namespace_body(cpp_src)
    body = strip_cpp_only(body)
    body = convert_fn_signatures(body, entrypoint)
    body = cpp_to_solidity_syntax(body)

    -- prefix compat functions and constants with their Solidity library name
    local compat_fn_names = extract_names(read_file(src_dir .. "EmulatorCompat.sol"), "function%s+([%w_]+)%s*%(")
    body = prefix_names(body, compat_fn_names, "EmulatorCompat.")
    local constants_names = extract_names(read_file(src_dir .. "EmulatorConstants.sol"), "constant%s+([%w_]+)")
    body = prefix_names(body, constants_names, "EmulatorConstants.")
    -- on-chain only the data hash is available, not the raw bytes
    body = transform_code(body, function(code)
        return code:gsub("%f[%w]data%f[%W]", "dataHash")
    end)

    -- extract enums from companion header
    local enums = ""
    if h_src then
        for ename, ebody in h_src:gmatch("enum class (%w+)%s*:%s*[%w_]+%s*{([^}]*)}") do
            enums = enums .. "enum " .. ename .. " {" .. ebody .. "}\n"
        end
    end

    -- wrap in Solidity library
    return M.LICENSE_BANNER .. "\n\n"
        .. "/// @dev This file is generated from C++ by generate_UArchSolidity.lua\n\n"
        .. "pragma solidity ^0.8.30;\n\n"
        .. "import \"./EmulatorCompat.sol\";\n\n"
        .. "library " .. lib_name .. " {\n"
        .. enums .. body .. "\n"
        .. "}\n"
end

local function help()
    io.stderr:write(string.format([=[
Usage:

  %s <input-cpp> <output-sol> <library-name> <entry-function>

Transpile a C++ uarch source file into a Solidity library.

Arguments:

  input-cpp       C++ source file to transpile (e.g. uarch-step.cpp).
                  If a companion .hpp or .h exists, enums are extracted from it.
  output-sol      Output .sol file path (e.g. src/UArchStep.sol)
  library-name    Solidity library name (e.g. UArchStep)
  entry-function  The library's public entry point (e.g. step).
                  Gets "internal" visibility; all others get "private".

]=], arg[0]))
    os.exit()
end

local function main()
    if not arg[1] or arg[1] == "-h" or arg[1] == "--help" then help() end
    local input_cpp      = arg[1]
    local output_sol     = assert(arg[2], "missing output-sol")
    local library_name   = assert(arg[3], "missing library-name")
    local entry_function = assert(arg[4], "missing entry-function")

    local input_cpp_src = read_file(input_cpp)
    local input_h_src
    for _, ext in ipairs({".hpp", ".h"}) do
        local h_path = input_cpp:gsub("%.cpp$", ext)
        local ok, src = pcall(read_file, h_path)
        if ok then input_h_src = src; break end
    end

    local result = M.transpile(input_cpp_src, input_h_src, library_name, entry_function)

    local f <close> = assert(io.open(output_sol, "w"))
    f:write(result)
    io.stderr:write("Generated " .. output_sol .. "\n")
end

if arg and arg[0] and arg[0]:match("/generate_UArchSolidity%.lua$") then
    main()
end

return M
