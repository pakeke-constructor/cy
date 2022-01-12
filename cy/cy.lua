
local path = (...):gsub('%.[^%.]+$', '')

local groups = require(path..".cy_groups")
local entity = require(path..".cy_entity")
local pckr = require(path..".pckr")
--local serialize = require(path..".cy_serialize")


local cy = setmetatable({},{
    __index = function(_,k)
        error("Accessed undefined attribute in cy table: "..tostring(k))
    end;
})


function cy.clear() -- Clears all entities
    local all = groups.all
    local ent
    for i=1, #all do
        ent = all[i]
        ent:delete()        
    end
    entity.clear_ids()
    cy.flush() -- force flush
end




function cy.flush()
    local rembuffer = entity.rembuffer
    local true_delete = entity.true_delete
    for i=#rembuffer, 1, -1 do
        true_delete(rembuffer[i])
        rembuffer[i] = nil
    end

    local addbuffer = entity.addbuffer
    for i=#addbuffer, 1, -1 do
        entity.add_to_groups(addbuffer[i])
        addbuffer[i] = nil
    end
end


function cy.new_etype(tabl, typename) -- Creates a new entity type
    return entity.construct(tabl, typename)
end


function cy.delete_etype(tabl_or_typename)
    entity.delete_etype(tabl_or_typename)
end




function cy.get_entities(...) -- gets an entity group
    return groups.get(...).view
end


function cy.get_entity(id)
    if not id then
        return nil
    end
    return entity.id_to_ent[id]
end



function cy.clear_fully()
    -- clears all entities, alongside their types
    cy.clear()
    local rembuffer = {}
    for typename, _ in pairs(entity.typename_to_etype) do
        table.insert(rembuffer, typename)
        pckr.unregister(typename)
    end
    for i=1, #rembuffer do
        entity.typename_to_etype[rembuffer[i]] = nil
    end
end


function cy.serialize()
    cy.flush()
    entity.set_reference_mode(false)
    local val = pckr.serialize(groups.all.view)
    entity.set_reference_mode(true)
    return val
end


function cy.deserialize(data)
    cy.flush()
    entity.set_reference_mode(false)
    
    local ret, err = pckr.deserialize(data)
    if err then
        return nil, err
    end
    
    -- ret should be an array of entities (`all` group)
    for i=1, #ret do
        entity.new_ent_fromtable(ret[i])
    end
    entity.set_reference_mode(true)
    return true
end


cy.pckr = pckr -- access to `pckr` library.


getmetatable(cy).__newindex = function()
    error("You sure you wanna do this? Use rawset if you're sure bro...")
end

return cy

