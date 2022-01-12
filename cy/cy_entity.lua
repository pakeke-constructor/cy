

local path = (...):gsub("%.cy_entity", "")

local groups = require(path..".cy_groups")
local inspect = require(path..".inspect")
local pckr = require(path .. ".pckr")

local assert = assert
local max = math.max



local rembuffer = {} -- Where entities are put before destruction

local addbuffer = {} -- Where entities are put before being added to groups


local reference_mode = false
-- Whether we should serialize entities as references or not.

-- [ent_id] --> entity
local id_to_ent = {}


local function err(_, key, _)
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





-- Ent ids   START 
local highest_id = 0 -- The first end id will be 1.
local id_buffer = {len = 0} -- a list of available ent ids.

local function clear_ids()
    highest_id = 0
    id_buffer = {len = 0}
end

local function remove_id(id)
    assert(id)
    local len = id_buffer.len + 1
    id_to_ent[id] = nil
    id_buffer[len] = id
end

local function get_id()
    if id_buffer.len > 0 then
        local id = id_buffer[id_buffer.len]
        id_buffer[id_buffer.len] = nil
        id_buffer.len = id_buffer.len - 1
        return id
    end

    highest_id = highest_id + 1
    return highest_id
end
-- Ent ids END




local insert = table.insert

local function ent_delete(ent)
    insert(rembuffer, ent)
end

local function true_delete(ent)
    local groups_ = ent.___type.___groups
    remove_id(ent.id)
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

    id_to_ent[ent] = ent -- initialize id here
    groups.all:add(ent)
end




local function new_ent(etype)
    local new = {} -- The entity
    
    for _,attr in ipairs(etype.___dynamic_fields) do
        new[attr] = false -- Dynamic attrs default to false.
    end
    
    new.id = get_id()
    setmetatable(new, etype.___ent_mt)

    table.insert(addbuffer, new)
    --add_to_groups(ent)

    return new
end


local function new_ent_fromtable(etype, tabl)
    if not tabl.id then
        tabl.id = get_id()
    else
        highest_id = max(highest_id, tabl.id)
    end

    if id_to_ent[tabl.id] then
        error("Duplicate ent id created") -- TODO: Find a clean way to do this.
        return -- Yeah, this is scuffed
    end

    setmetatable(tabl, etype.___ent_mt)

    table.insert(addbuffer, tabl)

    return tabl
end



local pckr_low_ser = pckr.low.serialize_raw
local pckr_low_deser = pckr.low.deserialize_raw

local pull = pckr.low.pull
local pckr_low_serializers = pckr.low.serializers

local function ent_ser(buffer, x, meta)
    if reference_mode then
        pckr_low_ser(buffer, x, meta)
    else
        pckr_low_serializers.number(buffer, x.id)
    end
end

local function ent_deser(reader, meta)
    local val, er1 = pull(reader)
    if er1 then
        return nil, er1
    end
    if type(val) == "number" then
        return id_to_ent[val]
    else
        return pckr_low_deser(val, meta)
    end
end


local function register_pckr(etype, typename)
    local mt = etype.___ent_mt
    pckr.register(mt, typename)
    pckr.low.set_template(mt, etype.___dynamic_fields)
    pckr.low.set_custom_functions(mt, ent_ser, ent_deser)
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
        local dyn_field = tabl[i]
        if dyn_field == "id" then
            error("Entities cannot have a .id member!") -- TODO: push this error up the stack.
        end
        table.insert(dynamic_fields, dyn_field)
        table.insert(all_fields, dyn_field)
    end

    table.sort(dynamic_fields) -- keep field ordering consistent
    table.sort(all_fields)

    local parent = {}
    for key, value in pairs(tabl) do 
        -- Don't care about JIT breaking; 
        -- this is only for entity type initialization.
        if key == "id" then
            error("Entities cannot have a .id member!") -- TODO: push this error up the stack.
        end

        table.insert(all_fields, key)
        parent[key] = value
    end
    parent.delete = ent_delete

    local ent_mt = {
        __index = parent;
        __newindex = err;
        __tostring = ent_tostring
    }

    local _groups = groups._get_groups(all_fields)

    local etype = {
        ___groups = _groups,
        ___dynamic_fields = dynamic_fields,
        ___ent_mt = ent_mt,
        ___typename = typename
    }
    parent.___type = etype

    typename_to_etype[typename] = etype

    register_pckr(etype, typename)
    return setmetatable(etype, etype_mt)
end


local function del_etype(name)
    pckr.unregister(name)
    typename_to_etype[name] = nil
end


local function set_reference_mode(ref_mode)
    reference_mode = ref_mode
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

    true_delete = true_delete;

    id_to_ent = id_to_ent;

    clear_ids = clear_ids;
    new_ent_fromtable = new_ent_fromtable;

    set_reference_mode = set_reference_mode
}


