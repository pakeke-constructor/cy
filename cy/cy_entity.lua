

local path = (...):gsub("%.cy_entity", "")

local groups = require(path..".cy_groups")
local msgpack = require(path..".messagepack")

local rembuffer = {} -- Where entities are put before destruction

local addbuffer = {} -- Where entities are put before being added to groups


local function err(ent, key, val)
    -- TODO: make some docs and link em.
    local msg3 = "See TODO.github.com for more information." -- This should link the docs
    local msg2 = "Attributes can only be set if they were definined originally, and aren't shared.\n"
    local msg = ("Attempted to set entity attribute: %s\n." .. msg2 .. msg3):format(tostring(key))
    error(msg)
end



local insert = table.insert

local function ent_delete(ent)
    insert(rembuffer, ent)
end

local function true_delete(ent)
    local groups_ = ent.___type.___groups
    for i=1, #groups_ do
        groups_[i]:remove(ent)
    end
end



local function add_to_groups(ent)
    local etype = ent.___type
    local group_arr = etype.___groups
    for i = 1, #group_arr do
        group_arr[i]:add(ent)
    end
    groups.all:add(ent)
end



local function new_ent(etype)
    local new = {} -- The entity
    
    for _,attr in ipairs(etype.___dynamic_fields) do
        new[attr] = false -- Dynamic attrs default to false.
    end
    
    setmetatable(new, etype.___ent_mt)

    table.insert(addbuffer, new)
    --add_to_groups(ent)

    return new
end


local function new_ent_fromtable(etype, new)    
    setmetatable(new, etype.___ent_mt)

    table.insert(addbuffer, new)
    --add_to_groups(ent)

    return new
end



local function ent_serialize(ent)
    return msgpack.serialize(ent)
end


local function ent_deserialize(etype, str)
    local tabl = msgpack.unpack(str)
    return new_ent_fromtable(etype, tabl)
end



local etype_mt = {
    __call = new_ent
}


local function new_etype(tabl)
    local dynamic_fields = {}
    local all_fields = {}

    for i=1, #tabl do
        table.insert(dynamic_fields, tabl[i])
        table.insert(all_fields, tabl[i])
    end

    local parent = {}
    for key, value in pairs(tabl) do 
        -- Don't care about JIT breaking; 
        -- this is only for entity type initialization.
        table.insert(all_fields, key)
        parent[key] = value
    end
    parent.delete = ent_delete

    local ent_mt = {
        __index = parent;
        __newindex = err;
        __metatable = "Entity metatables cannot be modified."
    }

    local _groups = groups._get_groups(all_fields)

    local etype = {
        ___groups = _groups,
        ___dynamic_fields = dynamic_fields,
        ___ent_mt = ent_mt
    }
    parent.___type = etype

    return setmetatable(etype, etype_mt)
end



return {
    construct   = new_etype;

    serialize   = ent_serialize;
    deserialize = ent_deserialize;
    
    rembuffer   = rembuffer;
    addbuffer   = addbuffer;

    add_to_groups = add_to_groups;

    true_delete = true_delete 
}


