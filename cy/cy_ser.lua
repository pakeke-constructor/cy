
local assert = assert
local error = error

local select = select
local pairs = pairs

local getmetatable = getmetatable
local setmetatable = setmetatable

local type = type
local concat = table.concat
local sub = string.sub
local floor = math.floor

local unpack = love.data.unpack
local pack = love.data.pack

local abs = math.abs

local pcall = pcall



local USMALL = "\230" -- there is another u8 following this. 
-- This means that `usmall` can be between 0 and 58880.
local MAX_USMALL = 58880

local I16 = "\237"
local I32 = "\238"
local I64 = "\239"

local U32 = "\240"
local U64 = "\241"

local NUMBER = "\242"

local NIL   = "\243"

local TRUE  = "\244"
local FALSE = "\245"

local STR = "\246"

local ENT  = "\247"    -- (uint etype_ref, flat table data)
local ENT_REF = "\248" -- (uint ref)

local ARRAY   = "\249" -- (flat table data)
local TABLE   = "\250" -- (table data; must use `pairs` to serialize)

local FLAT_TABLE  = "\251"  --(flat table data)

local BYTEDATA  = "\252" -- (A love2d ByteData; requires special attention with .unpack)

local RESOURCE  = "\253" -- (uint ref)
local REF = "\254" -- (uint ref)
local FUTURE_REF = "\255" -- (uint ref)


local PREFIX = ">!1"



local ser = {}


local ser_funcs = {
    -- [uint8] ==> serializaton_func ( data )
}

local deser_funcs = {
    -- [uint8]
}


local data -- string that is being deserialized
local index -- current index of `data`


local function get_ser_funcs(type, is_bytedata)
    local container = "string"
    if is_bytedata then
        container = is_bytedata
    end
    local format = PREFIX .. type

    local ser = function(data)
        return pack(container, format, data)
    end

    local deser = function(data)
        return pcall(unpack, format, data)
    end

    return ser, deser
end


local function add_reference(buffer, x)
    local refs = buffer.refs
    local count = refs.count
    refs[x] = count + 1
end


local serializers = {}

local deserializers = {}



local function push(buffer, x)
    -- pushes `x` onto the buffer
    local newlen = buffer.len + 1
    buffer[newlen] = x
    buffer.len = newlen
end


local function push_ref(buffer, ref_num)
    push(buffer, REF)
    serializers.number(buffer, ref_num)
end







--[[

Serializers:

]]

function serializers.table(buffer, x)
    if buffer.refs[x] then
        push_ref(buffer, buffer.refs[x])
    else
        -- okay: How are we going to do this?
    end
end


-- Number serialization:
local sUSMALL, dUSMALL = get_ser_funcs("I2")
local sU32, dU32 = get_ser_funcs("I4")
local sU64, dU64 = get_ser_funcs("I8")
local sI16, dI16 = get_ser_funcs("i2") -- lowercase `i` is signed.
local sI32, dI32 = get_ser_funcs("i4")
local sI64, dI64 = get_ser_funcs("i8")

function serializers.number(buffer, x)
    if x > 0 then
        -- serialize unsigned
        if x < MAX_USMALL then
            push(buffer, sUSMALL(x))
        elseif x < (2^32 - 1) then
            push(buffer, U32)
            push(buffer, sU32(x))
        else -- x is U64
            push(buffer, U64)
            push(buffer, sU64(x))
        end
    else
        -- serialize signed
        local mag = abs(x)
        if mag < ((2^15) - 2) then -- 16 bit signed num.
            push(buffer, I16)
            push(buffer, sI16(x))
        elseif mag < (2 ^ 31 - 2) then -- 32 bit signed num
            push(buffer, I32)
            push(buffer, sI32(x))
        else
            push(buffer, I64) -- else its 64 bit.
            push(buffer, sI64(x))
        end
    end
end


function serializers.string(buffer, x)
    if buffer.refs[x] then
        push_ref(buffer, buffer.refs[x])
    else
        push(buffer, string)
        push(buffer, x)
        add_reference(buffer, x)
    end
end



local function newbuffer()
    local buffer = {
        len = 0;
        refs = {count = 0} -- count = the number of references.
    }
    return buffer
end


function ser.serialize(...)
    local buffer = newbuffer()

    local len = select("#", ...)
    for i=1, len do
        local x = select(i, ...)
        serializers[type(x)](buffer, x)
    end
    return concat(buffer)
end


