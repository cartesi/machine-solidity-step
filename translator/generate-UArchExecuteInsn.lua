#!/usr/bin/env lua5.3

-- Copyright Cartesi and individual authors (see AUTHORS)
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

local emulator_src_path = os.getenv("EMULATOR_DIR") or "../machine-emulator"
local cpp_execute_path = emulator_src_path .. "/src/uarch-execute-insn.h"

local template_execute_path = "./translator/UArchExecuteInsn.sol.template"

local solidity_src_path = "./contracts/"
local solidity_compat_path = solidity_src_path .. "UArchCompat.sol"
local solidity_execute_path = solidity_src_path .. "UArchExecuteInsn.sol"

local keyword_start = "START OF AUTO-GENERATED CODE"
local keyword_end = "END OF AUTO-GENERATED CODE"

-- compatibility functions replacement dictionary
local compat_fns = {}

-- pure functions
local pure_fns = {"decode", "insnMatch", "operand", "copyBits"}

-- internal functions need to be accessed in UArchinterpret.sol
local internal_fns = {"uarchExecuteInsn", "readUint32"}

-- functions that require special treatment for unused parameter insn to silence the warning
local unused_insn_fns = {"executeFENCE"}

local function readAll(file)
    local f = assert(io.open(file, "r"), "error opening file: " .. file)
    local content = f:read("*all")
    f:close()
    return content
end

-- get all lines from file start to keyword_start
local function read_lines_head_to_keyword(file)
    local fd = assert(io.open(file, "r"), "error opening file: " .. file)
    local lines = {}
    for line in fd:lines() do
        lines[#lines + 1] = line
        if line:find(keyword_start, 1, true) then
            break
        end
    end
    fd:close()
    return lines
end

-- get all lines from keyword_end to eof
local function read_lines_keyword_to_tail(file)
    local fd = assert(io.open(file, "r"), "error opening file: " .. file)
    local keyword_found = false
    local lines = {}
    for line in fd:lines() do
        if line:find(keyword_end, 1, true) then
            keyword_found = true
        end
        if keyword_found then
            lines[#lines + 1] = line
        end
    end
    fd:close()
    return lines
end

local function print_r(fd, content)
    fd = fd or io.stdout
    if type(content) == "table" then
        for i = 1, #content do
            fd:write(content[i] .. "\n")
        end
    else
        fd:write(content .. "\n")
    end
end

local function savetxt(file, content)
    local fd = assert(io.open(file, "w"), "error opening file: " .. file)
    print_r(fd, content)
    fd:close()
end

local function build_compat_fns(src)
    local function_regex = "function ([^%(]+)"
    for x in src:gmatch(function_regex) do
        compat_fns[#compat_fns + 1] = x
    end
end

local function build_solidity_function(r_type, name, args)
    local ret = ""
    if r_type ~= "void" then
        ret = "returns (" .. r_type .. ")"
    end

    local accessibility = "private"
    local mutability = ""

    for i = 1, #internal_fns do
        if name:find(internal_fns[i]) then
            accessibility = "internal"
        end
    end

    for i = 1, #pure_fns do
        if name:find(pure_fns[i]) then
            mutability = "pure"
        end
    end

    for i = 1, #unused_insn_fns do
        if name:find(unused_insn_fns[i]) then
            args = args:gsub("uint32 insn", "uint32")
        end
    end

    local new

    if mutability == "" then
        new = "function " .. name .. "(" .. args .. ") " .. accessibility .. " " .. ret .. " {"
    else
        new = "function " .. name .. "(" .. args .. ") " .. accessibility .. " " .. mutability .. " " .. ret .. " {"
    end

    return new
end

local function replace_cpp_functions(src)
    local function_regex = "static inline (%w+) (%w+)%(([^\n]+)%) {"
    local temp = src
    return temp:gsub(function_regex, build_solidity_function)
end

local template_head = read_lines_head_to_keyword(template_execute_path)
local template_tail = read_lines_keyword_to_tail(template_execute_path)

-- capture functions in cartesi namespace
local src = readAll(cpp_execute_path)
src = src:match("namespace cartesi {(.*)}.*")

-- remove cpp specific code
src = src:gsub("template <typename UarchState>\n", "")
src = src:gsub(" +dumpInsn[^\n]+\n", "")
src = src:gsub(" +auto note[^\n]+\n", "")
src = src:gsub(" +%(void%) note;\n", "")
-- replace UarchState &a
src = src:gsub("UarchState &a", "IUArchState.State memory a")
-- replace throw
src = src:gsub("throw std::runtime_error", "revert")
src = src:gsub("::", ".")
src = src:gsub("constexpr ", "")
-- replace cpp function signature with solidity function signature
src = replace_cpp_functions(src)

-- replace all compatibility function calls with UArchCompat. prefix
local compat_src = readAll(solidity_compat_path)
build_compat_fns(compat_src)
for i = 1, #compat_fns do
    src = src:gsub("([ ~%(])" .. compat_fns[i], "%1UArchCompat." .. compat_fns[i])
end

-- construct the actual solidity code from template and processed cpp code
local out = template_head
out[#out + 1] = src
for i = 1, #template_tail do
    out[#out + 1] = template_tail[i]
end
savetxt(solidity_execute_path, out)
