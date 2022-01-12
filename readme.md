
# cy

Hybrid OOP / Entity-Component-System framework,
designed better serialization and better workings with networking.

The successor of [Cyan.](https://github.com/pakeke-constructor/Cyan)



Entity definition example:
```lua

local bullet = cy.entity({
    "pos", "vel", -- These are the variable attributes
        -- (i.e. these variables can change, and are unique to each instance.)

    image = "bullet", -- These are constant, shared entity attributes
    damage = 40 -- (Like static members in C# or Java.)
})



local b1 = bullet() -- `bullet` is like a class;
local b2 = bullet() -- here, we create 2 bullet ents, b1 and b2.


local str = cy.serialize(b1) -- Serializes bullet
-- This only works if the variable attributes are serializeable,
-- I.e. if the attributes are simple tables, numbers, or strings.


local b3 = cy.deserialize(bullet, str_data) -- Deserializes data


b1:delete() -- Deletes an entity.
-- BE WARNED! This entity is not deleted right away.


cy.flush() -- Deletes all queued entities.
-- (This makes it so you can delete entities mid-iteration.)


```

Entity views:
```lua

local group = cy.get_entities("pos", "vel")
-- Gets all entities with a pos and a vel.
-- THIS group IS READ ONLY!!!!


for i,e in ipairs(group) do
    update(e) -- We can iterate over groups
end



group:has(ent) -- whether a group has an ent (true/false)
-- ( This is O(1) )


group:on_added(function(end)
    ... -- Called when `ent` is added to group
end)


group:on_removed(function(ent)
    ... -- Called when `ent` is removed from group
end)


```

We define all of the components at load time so that entities can be
serialized really easily.
Sending entities to groups is also more efficient this way.

This works especially well with networking, because servers only need
to send over updates to the non-shared attributes.

This also means that entities can have functions as components- with
a classic implementation like Cyan, this would never work as closures are
impossible to send over a network.


## ADVANCED USAGE:
```lua

local ent_ctor = cy.new_etype({
    "position", "velocity", "health"
}, "main")


local e1 = ent_ctor()



e1:get_type() -- `main`


-- Also, since entity attributes are static,
-- entities can sort their attributes and put their data in an array,
-- as opposed to sending a whole msgpack data.
local indx = e1:get_attribute_index("position") -- attr index of `position`.

e1:get_attribute_name(index) -- "position"




```


