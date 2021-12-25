local assert = assert
local error = error
local select = select
local pairs = pairs
local getmetatable = getmetatable
local setmetatable = setmetatable
local type = type
local loadstring = loadstring or load
local concat = table.concat
local char = string.char
local byte = string.byte
local format = string.format
local sub = string.sub
local dump = string.dump
local floor = math.floor
local frexp = math.frexp
local unpack = unpack or table.unpack

-- Lua 5.3 frexp polyfill
-- From https://github.com/excessive/cpml/blob/master/modules/utils.lua
if not frexp then
    local log, abs, floor = math.log, math.abs, math.floor
    local log2 = log(2)
    frexp = function(x)
        if x == 0 then return 0, 0 end
        local e = floor(log(abs(x)) / log2 + 1)
        return x / 2 ^ e, e
    end
end

local function pack(...)
    return {...}, select("#", ...)
end

local function not_array_index(x, len)
    return type(x) ~= "number" or x < 1 or x > len or x ~= floor(x)
end

local function type_check(x, tp, name)
    assert(type(x) == tp,
        format("Expected parameter %q to be of type %q.", name, tp))
end

local bigIntSupport = false
local isInteger
if math.type then -- Detect Lua 5.3
    local mtype = math.type
    bigIntSupport = loadstring[[
    local char = string.char
    return function(n)
        local nn = n < 0 and -(n + 1) or n
        local b1 = nn // 0x100000000000000
        local b2 = nn // 0x1000000000000 % 0x100
        local b3 = nn // 0x10000000000 % 0x100
        local b4 = nn // 0x100000000 % 0x100
        local b5 = nn // 0x1000000 % 0x100
        local b6 = nn // 0x10000 % 0x100
        local b7 = nn // 0x100 % 0x100
        local b8 = nn % 0x100
        if n < 0 then
            b1, b2, b3, b4 = 0xFF - b1, 0xFF - b2, 0xFF - b3, 0xFF - b4
            b5, b6, b7, b8 = 0xFF - b5, 0xFF - b6, 0xFF - b7, 0xFF - b8
        end
        return char(212, b1, b2, b3, b4, b5, b6, b7, b8)
    end]]()
    isInteger = function(x)
        return mtype(x) == 'integer'
    end
else
    isInteger = function(x)
        return floor(x) == x
    end
end

-- Copyright (C) 2012-2015 Francois Perrad.
-- number serialization code modified from https://github.com/fperrad/lua-MessagePack
-- Encode a number as a big-endian ieee-754 double, big-endian signed 64 bit integer, or a small integer
local function number_to_str(n)
    if isInteger(n) then -- int
        if n <= 100 and n >= -27 then -- 1 byte, 7 bits of data
            return char(n + 27)
        elseif n <= 8191 and n >= -8192 then -- 2 bytes, 14 bits of data
            n = n + 8192
            return char(128 + (floor(n / 0x100) % 0x100), n % 0x100)
        elseif bigIntSupport then
            return bigIntSupport(n)
        end
    end
    local sign = 0
    if n < 0.0 then
        sign = 0x80
        n = -n
    end
    local m, e = frexp(n) -- mantissa, exponent
    if m ~= m then
        return char(203, 0xFF, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    elseif m == 1/0 then
        if sign == 0 then
            return char(203, 0x7F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
        else
            return char(203, 0xFF, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
        end
    end
    e = e + 0x3FE
    if e < 1 then -- denormalized numbers
        m = m * 2 ^ (52 + e)
        e = 0
    else
        m = (m * 2 - 1) * 2 ^ 52
    end
    return char(203,
                sign + floor(e / 0x10),
                (e % 0x10) * 0x10 + floor(m / 0x1000000000000),
                floor(m / 0x10000000000) % 0x100,
                floor(m / 0x100000000) % 0x100,
                floor(m / 0x1000000) % 0x100,
                floor(m / 0x10000) % 0x100,
                floor(m / 0x100) % 0x100,
                m % 0x100)
end



-- Copyright (C) 2012-2015 Francois Perrad.
-- number deserialization code also modified from https://github.com/fperrad/lua-MessagePack
local function number_from_str(str, index)
    local b = byte(str, index)
    if not b then error("Expected more bytes of input.") end
    if b < 128 then
        return b - 27, index + 1
    elseif b < 192 then
        local b2 = byte(str, index + 1)
        if not b2 then error("Expected more bytes of input.") end
        return b2 + 0x100 * (b - 128) - 8192, index + 2
    end
    local b1, b2, b3, b4, b5, b6, b7, b8 = byte(str, index + 1, index + 8)
    if (not b1) or (not b2) or (not b3) or (not b4) or
        (not b5) or (not b6) or (not b7) or (not b8) then
        error("Expected more bytes of input.")
    end
    if b == 212 then
        local flip = b1 >= 128
        if flip then -- negative
            b1, b2, b3, b4 = 0xFF - b1, 0xFF - b2, 0xFF - b3, 0xFF - b4
            b5, b6, b7, b8 = 0xFF - b5, 0xFF - b6, 0xFF - b7, 0xFF - b8
        end
        local n = ((((((b1 * 0x100 + b2) * 0x100 + b3) * 0x100 + b4) *
            0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8
        if flip then
            return (-n) - 1, index + 9
        else
            return n, index + 9
        end
    end
    if b ~= 203 then
        error("Expected number")
    end
    local sign = b1 > 0x7F and -1 or 1
    local e = (b1 % 0x80) * 0x10 + floor(b2 / 0x10)
    local m = ((((((b2 % 0x10) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8
    local n
    if e == 0 then
        if m == 0 then
            n = sign * 0.0
        else
            n = sign * (m / 2 ^ 52) * 2 ^ -1022
        end
    elseif e == 0x7FF then
        if m == 0 then
            n = sign * (1/0)
        else
            n = 0.0/0.0
        end
    else
        n = sign * (1.0 + m / 2 ^ 52) * 2 ^ (e - 0x3FF)
    end
    return n, index + 9
end




local x = 0


local function timeit(func, name)
    local t1 = love.timer.getTime()
    func()
    local t2 = love.timer.getTime()
    print("Time taken - " .. (name or ""), t2 - t1)
end


local AM = 0xffffff

timeit(function()
for i=1, AM do
    x = (x + number_from_str(number_to_str(i % 100), 1)) % 5000
end
end, "binser")


x = 0
local pack, unpack = love.data.pack, love.data.unpack

local format = ">!1I2"
timeit(function()
for i=1, AM do
    x = (x + (unpack(format, pack("string",format, i % 100)))) % 5000
end
end, "pack unpack")








