--
-- json.lua
--
-- A lightweight JSON library for Lua, based on rxi/json.lua
--
-- luacheck: globals error rawget select

local error = error
local rawget = rawget
local select = select
local json = { _version = "0.1.0" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
    ["\\"] = "\\\\",
    ['"'] = '\\"',
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
}

local function escape_char(c)
    return escape_char_map[c] or string.format("\\u%04x", c:byte())
end

local function encode_nil()
    return "null"
end

local function encode_table(val, stack)
    local res = {}
    stack = stack or {}

    if stack[val] then
        error("circular reference")
    end
    stack[val] = true

    if rawget(val, 1) ~= nil or next(val) == nil then
        for i = 1, #val do
            res[#res + 1] = encode(val[i], stack)
        end
        stack[val] = nil
        return "[" .. table.concat(res, ",") .. "]"
    end

    for k, v in pairs(val) do
        if type(k) ~= "string" then
            error("invalid table: mixed or non-string keys")
        end
        res[#res + 1] = encode(k, stack) .. ":" .. encode(v, stack)
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
end

local function encode_string(val)
    return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end

local function encode_number(val)
    if val ~= val or val <= -math.huge or val >= math.huge then
        error("invalid number")
    end
    return string.format("%.14g", val)
end

local type_func_map = {
    ["nil"] = encode_nil,
    ["table"] = encode_table,
    ["string"] = encode_string,
    ["number"] = encode_number,
    ["boolean"] = tostring,
}

encode = function(val, stack)
    local t = type(val)
    local f = type_func_map[t]
    if f then
        return f(val, stack)
    end
    error("unexpected type '" .. t .. "'")
end

function json.encode(val)
    return encode(val)
end

-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
    local res = {}
    local n = select("#", ...)
    for i = 1, n do
        res[select(i, ...)] = true
    end
    return res
end

local space_chars = create_set(" ", "\t", "\r", "\n")
local delim_chars = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local literals = create_set("true", "false", "null")

local literal_map = {
    ["true"] = true,
    ["false"] = false,
    ["null"] = nil,
}

local function next_char(str, idx, set, negate)
    for i = idx, #str do
        if set[str:sub(i, i)] ~= negate then
            return i
        end
    end
    return #str + 1
end

local function decode_error(_str, idx, msg)
    error(string.format("decode error at position %d: %s", idx, msg))
end

local function codepoint_to_utf8(n)
    local f = math.floor
    if n <= 0x7f then
        return string.char(n)
    elseif n <= 0x7ff then
        return string.char(f(n / 64) + 192, n % 64 + 128)
    elseif n <= 0xffff then
        return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
    elseif n <= 0x10ffff then
        return string.char(
            f(n / 262144) + 240,
            f(n % 262144 / 4096) + 128,
            f(n % 4096 / 64) + 128,
            n % 64 + 128
        )
    end
    error(string.format("invalid unicode codepoint '%x'", n))
end

local function parse_unicode_escape(s)
    local n1 = tonumber(s:sub(1, 4), 16)
    local n2 = tonumber(s:sub(7, 10), 16)
    if n2 then
        return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
    else
        return codepoint_to_utf8(n1)
    end
end

local function parse_string(str, i)
    local res = ""
    local j = i + 1
    local k = j

    while j <= #str do
        local x = str:byte(j)

        if x < 32 then
            decode_error(str, j, "control character in string")
        elseif x == 92 then
            res = res .. str:sub(k, j - 1)
            j = j + 1
            local c = str:sub(j, j)
            if c == "u" then
                local hex = str:match("^%x%x%x%x", j + 1)
                if not hex then
                    decode_error(str, j, "invalid unicode escape in string")
                end
                local codepoint = parse_unicode_escape(hex)
                res = res .. codepoint
                j = j + 4
                k = j + 1
            else
                local map = {
                    ["b"] = "\b",
                    ["f"] = "\f",
                    ["n"] = "\n",
                    ["r"] = "\r",
                    ["t"] = "\t",
                    ["\\"] = "\\",
                    ['"'] = '"',
                    ["/"] = "/",
                }
                if not map[c] then
                    decode_error(str, j, "invalid escape char '" .. tostring(c) .. "' in string")
                end
                res = res .. map[c]
                k = j + 1
            end
        elseif x == 34 then
            res = res .. str:sub(k, j - 1)
            return res, j + 1
        end

        j = j + 1
    end

    decode_error(str, i, "expected closing quote for string")
end

local function parse_number(str, i)
    local x = next_char(str, i, delim_chars)
    local s = str:sub(i, x - 1)
    local n = tonumber(s)
    if not n then
        decode_error(str, i, "invalid number '" .. s .. "'")
    end
    return n, x
end

local function parse_literal(str, i)
    local x = next_char(str, i, delim_chars)
    local word = str:sub(i, x - 1)
    if not literals[word] then
        decode_error(str, i, "invalid literal '" .. word .. "'")
    end
    return literal_map[word], x
end

local function parse_array(str, i)
    local res = {}
    local n = 1
    i = i + 1
    while true do
        local x
        i = next_char(str, i, space_chars, true)
        if str:sub(i, i) == "]" then
            return res, i + 1
        end
        x, i = parse(str, i)
        res[n] = x
        n = n + 1
        i = next_char(str, i, space_chars, true)
        local ch = str:sub(i, i)
        i = i + 1
        if ch == "]" then
            return res, i
        end
        if ch ~= "," then
            decode_error(str, i, "expected ']' or ','")
        end
    end
end

local function parse_object(str, i)
    local res = {}
    i = i + 1
    while true do
        local key, val
        i = next_char(str, i, space_chars, true)
        if str:sub(i, i) == "}" then
            return res, i + 1
        end
        if str:sub(i, i) ~= '"' then
            decode_error(str, i, "expected string for object key")
        end
        key, i = parse_string(str, i)

        i = next_char(str, i, space_chars, true)
        if str:sub(i, i) ~= ":" then
            decode_error(str, i, "expected ':' after key")
        end
        i = next_char(str, i + 1, space_chars, true)
        val, i = parse(str, i)

        res[key] = val
        i = next_char(str, i, space_chars, true)
        local ch = str:sub(i, i)
        i = i + 1
        if ch == "}" then
            return res, i
        end
        if ch ~= "," then
            decode_error(str, i, "expected '}' or ','")
        end
    end
end

local char_func_map = {
    ['"'] = parse_string,
    ["0"] = parse_number,
    ["1"] = parse_number,
    ["2"] = parse_number,
    ["3"] = parse_number,
    ["4"] = parse_number,
    ["5"] = parse_number,
    ["6"] = parse_number,
    ["7"] = parse_number,
    ["8"] = parse_number,
    ["9"] = parse_number,
    ["-"] = parse_number,
    ["t"] = parse_literal,
    ["f"] = parse_literal,
    ["n"] = parse_literal,
    ["["] = parse_array,
    ["{"] = parse_object,
}

parse = function(str, idx)
    local chr = str:sub(idx, idx)
    local f = char_func_map[chr]
    if f then
        return f(str, idx)
    end
    decode_error(str, idx, "unexpected character '" .. chr .. "'")
end

function json.decode(str)
    if type(str) ~= "string" then
        error("expected argument of type string for json.decode")
    end
    local res, idx = parse(str, next_char(str, 1, space_chars, true))
    idx = next_char(str, idx, space_chars, true)
    if idx <= #str then
        decode_error(str, idx, "trailing garbage")
    end
    return res
end

return json
