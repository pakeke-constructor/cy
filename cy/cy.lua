
local path = (...):gsub('%.[^%.]+$', '')

local groups = require(path..".cy_groups")
local entity = require(path..".cy_entity")
local serialize = require(path..".cy_serialize")


local cy = setmetatable({},{
    __index = function(t,k)
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


function cy.entity(tabl, typename) -- Creates a new entity
    return entity.construct(tabl, typename)
end


function cy.get_entities(...) -- gets an entity group
    return groups.get(...).view
end




function cy.serialize()
    -- TODO: Make this function asynchronous.
    -- i.e. you can call it multiple times to spread the load over multiple
    -- frames.
    --
    -- IF YOU DO THIS, HOWEVER, WARNING :::
    -- This functions should ABSOLUTELY NOT BE CALLED
    -- WHEN THE WORLD IS STILL UPDATING !!!!
    -- It will likely cause issues
    return serialize.serialize()
end

function cy.deserialize(etype, data)
    --[[
        TODO:

        Make this function asynchronous too.
        Like you can call it multiple times to spread the load over multiple
        frames.
        Also, you could add a loading bar :)
    ]]
    return serialize.deserialize()
end


getmetatable(cy).__newindex = function(t,k,v)
    error("You sure you wanna do this? Use rawset if you're sure bro...")
end

return cy

