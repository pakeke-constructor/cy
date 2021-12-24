
local path = (...):gsub(".cy_serialize", "")

local binser = require(path..".binser")
local entity = require(path..".cy_entity")
local groups = require(path..".cy_groups")

local coroutine = coroutine


local SERIALIZATION_VERSION = 1



local s = {}


local function copy(t)
    local cpy = {}
    for i=1, #t do
        cpy[i] = t[i]
    end
    return cpy
end


local function serialize_schema(typename_arr)
    --[[
        returns `data`, `typename_arr`.

        `data` is the serialized etype data,
        as per PLANNING.md
    ]]
    local buffer = {}
    for i, typename in ipairs(typename_arr) do
        local etype = entity.typename_to_etype[typename]
        buffer[typename] = copy(etype.___dynamic_fields)
    end

    return binser.s(buffer)
end



local RANGE = 255

local char = string.char
local floor = math.floor


local function squash(i)
    assert(i > 0 and i < 0x1000000, "[cy_serialize.squash error] umm... this is an odd error. Please contact Oli")

    return char(
        floor(x / 0x1000000) % 0x100,
        floor(x / 0x10000) % 0x100,
        floor(x / 0x100) % 0x100,
        x % 0x100
    )
end




local function serialize_registry(typename_arr)
    --[[
        returns `data`,
        and sets up the binser registry for serialization.
        WARNING: This operation is stateful!
    ]]
    local shortstr_to_typename = {}

    for i, typename in ipairs(typename_arr) do
        local shortstr = squash(i)
        -- TODO: This is probably a bad way of doing this.
        -- I can't believe I am saying this, but it would probably be better
        -- to monkeypatch binser to allow for numbers as names.
        shortstr_to_typename[shortstr] = typename
        
        local mt = entity.typename_to_etype[typename].___ent_mt
        binser.registerClass(mt, shortstr)
    end

    return binser.s(shortstr_to_typename)
end



local function serialize_entities(start_i, n)
    local ent_arr = groups.all.view
    return start_i + n, binser.serializeTable(groups.)
    return binser.s(ent_arr)
end




function s.serialize_world(ent_list, start_i, count)
    -- We are going to assume that the current entity schematics are
    -- defined as per what the user intends.
    
    binser.unregisterAllClasses() --  TODO: make sure this works.
    
    -- SERIALIZE VERSION
    local s_version = binser.s(SERIALIZATION_VERSION)

    local typename_arr = {}
    for typename, _ in pairs(entity.typename_to_etype) do
        table.insert(typename_arr, typename)
    end

    -- SERIALIZE CHAR MAPPING
    local s_char_mapping = serialize_char_mapping(typename_arr)

    -- SERIALIZE SCHEMA
    local s_schema = serialize_schema(typename_arr)

    -- SERIALIZE ENTITIES.
    local s_ents = serialize_entities(typename_arr)

    return s_version .. s_char_mapping .. s_schema .. s_ents
end






--[[
===
===
====  Deserialization
===
===
===
--]]



local function deserialize_registry(data, start_i)
    --[[
        TODO:
        Account for mis-matching registries.
        Take a look at PLANNING.md to see what we do in the case of an entity
        mis-match.
    ]]
    local registry, next_i = binser.deserialize(data, start_i)
    if not registry then
        return nil, next_i
    end

    local typename_to_badfields = { 
        -- fields that need to be removed for each etype.
        -- I.e, if a serialized ent had extra unused fields, this table tags them
        -- for removal.

        -- [typename] : {field_list}
    }

    for typename, dynamic_fields in pairs(registry) do
        local bad_fields = {}
        local exists = {}
        local our_dyn_fields = entity.typename_to_etype[typename].___dynamic_fields
        for i=1, #(our_dyn_fields) do
            local f = our_dyn_fields[i]
            exists[f] = true
        end

        for i=1, #dynamic_fields do
            local fld = dynamic_fields[i]
            if not exists[fld] then
                table.insert(bad_fields, fld)
            end
        end

        typename_to_badfields[typename] = bad_fields
    end

    return registry, next_i, typename_to_badfields
end



local yield = coroutine.yield


local buffer = {}
local version = {}

function s.start_deserialize()

end

function s.deserialize_header(data, start_i)
    local i = start_i

    -- make sure to use pcall here
    local version, i = pcall(binser.deserialize, data, i)
    if not version then
        return nil, i
    end
    if (version ~= SERIALIZATION_VERSION) then
        return nil, "cy serialization versions are different. Is your game updated?"
    end

    local registry, i = pcall(deserialize_registry, data, i, typename_to_chr)
    if not registry then
        return nil, i
    end

    return 
end


