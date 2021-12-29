
local assert = assert
local error = error

local select = select
local pairs = pairs

local getmetatable = getmetatable
local setmetatable = setmetatable

local type = type
local concat = table.concat

local unpack = love.data.unpack
local pack = love.data.pack

local abs = math.abs
local max = math.max
local min = math.min
local floor = math.floor

local byte = string.byte
local char = string.char
local sub = string.sub

local pcall = pcall



local USMALL = "\230" -- there is another uint8 following this. 
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

local STRING = "\246"

local CUSTOM_TYPE = "\247" -- (type_name,  table // flat-table // array )

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


local mt_to_name = {} -- metatable --> name_str
local name_to_mt = {} -- name_str --> metatable
local mt_to_template = {} -- metatable --> template
local mt_to_arraybool = {} -- metatable --> is array? (boolean)


function pckr.register_type(metatable, name)
    assert(not name, "Duplicate registered type: " .. tostring(name))
    name_to_mt[name] = metatable
    mt_to_name[metatable] = name
end


function pckr.unregister_type(metatable, name)
    local mt = name_to_mt[name]
    name_to_mt[name] = nil
    if mt then
        mt_to_name[mt] = nil

        mt_to_template[mt] = nil
        mt_to_arraybool[mt] = nil
    end
end


function pckr.unregister_all()
    name_to_mt = {}
    mt_to_name = {}
    mt_to_template = {}
    mt_to_arraybool = {}
end


function pckr.register_template(name_or_mt, template)
    -- Templates must be registered the same!
    local mt = name_or_mt
    if type(name_or_mt) == "string" then
        mt = name_to_mt[name_or_mt] -- assume `name_or_mt` is name
    end
    mt_to_template[mt] = template
end



function pckr.register_array(name_or_mt)
    -- registers the given metatable as an array type
    local mt = name_or_mt
    if type(name_or_mt) == "string" then 
        mt = name_to_mt[name_or_mt] -- assume `name_or_mt` is name
    end
    mt_to_template[mt] = template
end




local function add_reference(buffer, x)
    local refs = buffer.refs
    local new_count = refs.count + 1
    refs[x] = new_count
    refs.count = new_count
end














--[[

Serializers:

]]


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


local function serialize_raw(x)
    push(buffer, TABLE)
    for k,v in pairs(x) do
        serialize[type(k)](k)
        serialize[type(v)](v)
    end
    push(buffer, TABLE_END)
end


local function serialize_with_meta(x, meta)
    local is_array = mt_to_template[meta] -- whether `x` is an array or not.
    local name = mt_to_name[meta]

    -- TODO TODO TODO:::: This is unfinished.
    -- We haven't even properly planned how to put the tags for this!!!!
    -- Maybe do something like:
    -- CUSTOM_TYPE [type_str]  FLAT_TABLE [flat table data]  ARRAY [array data] END
    -- Or, if there is no ARRAY part, don't have an ARRAY tag.
    if mt_to_template[meta] then
        push(buffer, FLAT_TABLE)
        local template = mt_to_template[meta]
        for i=1, #template do
            local k = template[i]
            local val = x[k]
            serializers[type(val)](val)
        end
        push(buffer, TABLE_END)
        assert(type(meta) == "table", "`meta` not a table..?")
        serializers.table(meta)
    else
        -- gonna have to serialize normally, oh well
        serialize_raw(x)
        serializers.table(meta)
    end
end



function serializers.table(buffer, x)
    if buffer.refs[x] then
        push_ref(buffer, buffer.refs[x])
    else
        add_reference(buffer, x)
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
local sN, dN = get_ser_funcs("n")

function serializers.number(buffer, x)
    if floor(x) == x then
        -- then is integer
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
    else
        push(buffer, NUMBER)
        push(buffer, sN(x))
    end
end


function serializers.string(buffer, x)
    if buffer.refs[x] then
        push_ref(buffer, buffer.refs[x])
    else
        push(buffer, STRING)
        push(buffer, x)
        push(buffer, "\0") -- remember to push null terminator!
        -- TODO: Is this null terminator needed? Do testing
        add_reference(buffer, x)
    end
end













--[[

deserializers

]]

local function poll(reader, )

end



















local function newbuffer()
    local buffer = {
        len = 0;
        refs = {count = 0} -- count = the number of references.
    }
    return buffer
end


local function newreader()
    local reader = {
        
    }
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




