

local path = (...):gsub("%.cylua_entity", "")

local sigfields = require(path..".cylua_sigfields")
local groups = require(path..".cylua_groups")



local function err(ent, key, val)
    -- TODO: make some docs and link em.
    local msg3 = "See TODO.github.com for more information." -- This should link the docs
    local msg2 = "Attributes can only be set if they were definined originally, and aren't shared.\n"
    local msg = ("Attempted to set entity attribute: %s\n." .. msg2 .. msg3):format(key)
    error(msg)
end


local function new_ent(etype)
    local new = { } -- The entity
    
    for _,attr in ipairs(etype.___dynamic_fields) do
        new[attr] = false -- Dynamic attrs default to false.
    end
    
    setmetatable(new, etype.___ent_mt)

    local group_arr = etype.___groups
    for i = 1, #group_arr do
        group_arr[i]:___add(new)
    end

    return new
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

    local ent_mt = {
        __index = parent;
        __newindex = err;
        __metatable = "Entity metatables cannot be modified."
    }

    local etype = {
        ___groups = groups._get_groups(all_fields),
        ___dynamic_fields = dynamic_fields,
        ___ent_mt = ent_mt
    }

    return setmetatable(etype, etype_mt)
end



return new


