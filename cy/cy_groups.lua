
local path = (...):gsub("%.cy_groups", "")

local group_ctor = require(path..".cy_group")


local groups = {
    all = group_ctor({})
}


-- an array of all groups
local all_groups = {groups.all}


-- A hasher that keeps track of all groups
local group_hash = {
    --[[
    ["field1:field2:field3"] = group
    ]]
}


-- A hasher that records all groups for every field
local field_to_groups = {
    --[[
        ["field_1"] : { group1, group2, group3 }
        ["field_2"] : { group3, group5 }
    ]]
}



local get_groups_called = false


local function set_ftps(fields, group)
    --[[
        Updates group field hash with new fields
    ]]
    for _,field in ipairs(fields) do
        if not field_to_groups[field] then
            field_to_groups[field] = {group}
        else
            table.insert(field_to_groups[field], group)
        end
    end
end


local SEP_CHR = "@" --  Seperation character for key

local function make_key(fields)
    table.sort(fields) -- TOOD: make sure this is consistent!!!!
    return table.concat(fields, SEP_CHR)
end


local out_of_order_err = "You must define all cy groups before you define any cy entities!"

function groups.get(...)
    local fields = {...}

    if #fields == 0 then
        return groups.all
    end
    
    -- First, check for already existing groups
    local key = make_key(fields)

    local group
    if group_hash[key] then
        group = group_hash[key]
    else
        -- Else, make a new one
        if get_groups_called then -- This could easily trip people up,
            error(out_of_order_err) -- its best to check.
        end -- TODO: Maybe automatically update existing groups instead? this would be cleanre
        group = group_ctor(fields)
        group_hash[key] = group
        set_ftps(fields, group)
        table.insert(all_groups, group)
    end

    return group
end


function groups.clear()
    for i=1, #all_groups do
        local g = all_groups[i]
        g:clear()
    end
    groups.all:clear()
end



local function contains(tab, search)
    for i=1, #tab do
        if tab[i] == search then
            return true
        end
    end
    return false
end


local function is_worthy(group, candidate_fields)
    for _, gf in ipairs(group.fields) do
        if not contains(candidate_fields, gf) then
            -- We don't care about the O(n^2) here,
            -- This function is hardly ever called
            return false
        end
    end
    return true
end



function groups._get_groups(fields)
    --[[
        Gets all the groups for given fields
    ]]
    get_groups_called = true
    local tab = {}
    local seen = {}

    for i=1, #fields do
        local f = fields[i]
        if field_to_groups[f] then
            for _, group in ipairs(field_to_groups[f]) do
                if (not seen[group]) and is_worthy(group, fields) then
                    table.insert(tab, group)
                    seen[group] = true
                end
            end
        end
    end

    return tab
end



return groups

