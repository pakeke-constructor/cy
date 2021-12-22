

local path = (...):gsub("%.cy_entity", "")

local groups = require(path..".cy_groups")
local inspect = require(path..".inspect")

local rembuffer = {} -- Where entities are put before destruction

local addbuffer = {} -- Where entities are put before being added to groups


local function err(ent, key, val)
    -- TODO: make some docs and link em.
    local msg3 = "See TODO.github.com for more information." -- This should link the docs
    local msg2 = "Attributes can only be set if they were definined originally, and aren't shared.\n"
    local msg = ("Attempted to set entity attribute: %s\n." .. msg2 .. msg3):format(tostring(key))
    error(msg)
end


local function ent_tostring(ent)
    local typename = ent.___type.___typename
    local start = "[" .. tostring(typename) .. "] "
    return start .. inspect(ent, {seen = ent.___type})
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



local function new_ent(etype, name)
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





local etype_mt = {
    __call = new_ent
}


local typename_to_etype = {}


local function new_etype(tabl, typename)
    assert(type(tabl) == "table", "etype should be table")
    assert(type(typename) == "string", "each entity needs a typename")

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
        __tostring = ent_tostring;
        __metatable = "Entity metatables cannot be modified."
    }

    local _groups = groups._get_groups(all_fields)

    local etype = {
        ___groups = _groups,
        ___dynamic_fields = dynamic_fields,
        ___ent_mt = ent_mt,
        ___typename = typename,
        _template = dynamic_fields -- Binser uses this.
    }
    parent.___type = etype

    typename_to_etype[typename] = etype

    return setmetatable(etype, etype_mt)
end


local function del_etype(name)
    typename_to_etype[name] = nil
end



return {
    construct   = new_etype;
    destruct    = del_etype;

--    serialize   = ent_serialize;
--    deserialize = ent_deserialize; -- we aren't using these i dont think
    
    rembuffer   = rembuffer;
    addbuffer   = addbuffer;

    add_to_groups = add_to_groups;

    typename_to_etype = typename_to_etype;

    true_delete = true_delete 
}


