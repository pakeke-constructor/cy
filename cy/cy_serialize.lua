
local path = (...):gsub(".cy_serialize", "")

local binser = require(path..".binser")
local entity = require(path..".cy_entity")
local groups = require(path..".cy_groups")



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
    assert(i > 0 and i < 0x10000,
[[too many entity types to fit into our registry....
this is really bad, there are more than 65536 entity types...]])

    return char(
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



local function serialize_entities(typename_arr)
    local ent_arr = groups.all.view
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
Here we go.... hopefully this isn't too much of a mess.
--]]



local function deserialize_char_mapping(data, start_i)
    local chr_mapping, next_i = binser.deserialize(data, start_i)
    return chr_mapping, next_i
end


local function deserialize_registry(data, start_i)
    --[[
        TODO:
        Account for mis-matching registries.
        Take a look at PLANNING.md to see what we do in the case of an entity
        mis-match.
    ]]
    local registry, next_i = binser.deserialize(data, start_i)
    return registry, next_i
end




function s.deserialize_world(data, start_i, count)
    local i = start_i

    -- make sure to use pcall here
    local version, i = pcall(binser.deserialize, data, i)
    
    if not version then
        return nil, i
    end
    if (version ~= SERIALIZATION_VERSION) then
        return nil, "cy serialization versions are different. Is your game updated?"
    end

    local typename_to_chr, i = pcall(deserialize_char_mapping, data, i)
    if not typename_to_chr then
        return nil, i
    end

    local registry, i = pcall(deserialize_registry, data, i)
    if not registry then
        return nil, i
    end
end


