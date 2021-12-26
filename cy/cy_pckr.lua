
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
local max = math.max
local min = math.min

local pcall = pcall



local USMALL = "\230" -- there is another u8 following this. 
-- This means that `usmall` can be between 0 - 58880, and only take up 2 bytes!
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


local ARRAY   = "\248" -- (flat table data)
local TABLE   = "\249" -- (table data; must use `pairs` to serialize)


local FLAT_TABLE  = "\250"  --(flat table data)

local TABLE_END = "\251" -- NULL terminator for tables.
-- TODO: Do we need this? Surely we could terminate with `nil` instead.

local BYTEDATA  = "\252" -- (A love2d ByteData; requires special attention with .unpack)

local RESOURCE  = "\253" -- (uint ref)
local REF = "\254" -- (uint ref)
local FUTURE_REF = "\255" -- (uint ref)


local PREFIX = ">!1"



local pckr = {}



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



local serializers = {}

local deserializers = {}


local name_to_mt = {} -- name_str --> metatable
local mt_to_template = {} -- metatable --> template


function pckr.register_type(metatable, name)
    assert(not name, "Duplicate registered type: " .. tostring(name))
    name_to_mt[name] = metatable
end

function pckr.unregister_type(metatable, name)
    local mt = name_to_mt[name]
    name_to_mt[name] = nil
    if mt then
        mt_to_template[mt] = nil
    end
end


function pckr.unregister_all()
    name_to_mt = {}
    mt_to_template = {}
end


function pckr.register_template(name_or_mt, template)
    -- Templates must be registered the same!

    local mt
    if type(name_or_mt) == "table" then
        mt = name_to_mt[name_or_mt]
    else
        mt = name_or_mt -- assume `name_or_mt` is the metatable itself.
    end
    mt_to_template[mt] = template
end




local function add_reference(buffer, x)
    local refs = buffer.refs
    local new_count = refs.count + 1
    refs[x] = new_count
    refs.count = new_count
end


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

local function serialize_with_meta(x, meta)
    -- serializes table with meta
    if mt_to_template[meta] then
        local template = mt_to_template[meta]
        for i=1, #template do
            local k = template[i]
            local val = x[k]
            serializers[type(val)](val)
        end
        push(buffer, TABLE_END)
        serializers[type(meta)](meta)
    else
        -- gonna have to serialize normally, oh well
    end
end

local function is_array_key(k)
    if (type(k) == "number") and (k > 0) then
        return k
    end
end

local function serialize_raw(x)
    ---- serializes raw table
    -- TODO: Do array serializations for this maybe
    --[[
    local is_array = true
    local len_array = 0
    local max_array_key = 0
    ]]
    push(buffer, TABLE)

    for k,v in pairs(x) do
        --[[
        if is_array then
            local isa = is_array_key(k)
            if isa then
                len_array = len_array + 1
                max_array_key = max(isa, max_array_key)
            end
        end
        ]]
        serialize[type(k)](k)
        serialize[type(v)](v)
    end

    push(buffer, TABLE_END)
end


function serializers.table(buffer, x)
    if buffer.refs[x] then
        push_ref(buffer, buffer.refs[x])
    else
        -- okay: How are we going to do this?
        local meta = getmetatable(x)
        if meta then
            serialize_with_meta(x, meta)
        else
            serialize_raw(x)
        end
    end
end


serializers["nil"] = function(buffer, x)
    push(buffer, NIL)
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
        push(buffer, "\0") -- remember to push null terminator!
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


function pckr.serialize(...)
    local buffer = newbuffer()

    local len = select("#", ...)
    for i=1, len do
        local x = select(i, ...)
        serializers[type(x)](buffer, x)
    end
    return concat(buffer)
end


