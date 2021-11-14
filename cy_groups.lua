

local path = (...):gsub("%.cylua_entity", "")
local sigfields = require(path..".cylua_set")


local groups = {}


-- A hasher that keeps track of all groups
local group_hash = {
    --[[
    ["field1:field2:field3"] = SSet()
    ]]
}


-- A hasher that records all groups for every field
local field_to_groups = {
    --[[
        ["field_1"] : { group1, group2, group3 }
        ["field_2"] : { group3, group5 }
    ]]
}


local group_fields = {
    --[[
        [group] : Sset() -- a sset of fields that each group contains
    ]]
}


local SEP_CHR = "@" --  Seperation character for group_hash






local function set_ftps(fields, group)
    --[[
        Updates group field hash with new fields
    ]]
    for i,field in ipairs(fields) do
        field_to_groups[field] = group
    end
end


function groups.get_entities(...)
    local fields = {...}
    
    -- First, check for already existing groups
    table.sort(fields)
    local key = table.concat(fields, SEP_CHR)

    local group
    if group_hash[key] then
        group = group_hash[key]
    else
        -- Else, make a new one
        group = SSet()
        group_hash[key] = group
        set_ftps(fields, group)
    end

    return new
end



local function is_worthy(group_fields, candidate_fields)
    for j, cand in ipairs(candidate_fields) do
        if not group_fields:has(cand) then
            return false
        end
    end
    return true
end



function groups._get_groups(fields)
    --[[
        Gets all the groups for given fields
    ]]
    local tab = {}

    for i=1, #fields do
        local f = fields[i]
        if field_to_groups[f] then
            for i, group in ipairs(field_to_groups[f]) do
                table.insert(tab, group)
            end
        end
    end

    return tab
end



return groups

