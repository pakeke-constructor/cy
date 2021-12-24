
# cy_ser

Cy custom serialization.
I didn't want to have to do this...


### SER PLANNING::::
Use love.data.pack  AND  love.data.unpack for numbers.
It's twice as faster as binser!  (benchmarked it.)
Note that you will also have to use pcall for this too, though.

- Map ent-type names to numbers in the world serialization header.

- If we encounter an entity ref (lets call it `X`), 
  and the entity doesn't exist yet, put something in ent `X`s "ref buffer".
  When ent `X` is serialized, you can then go through the "ref buffer",
  and update every entity that was supposed to be pointing to `X`.
  In the meantime, all the references to `X` should just point to a dummy
  table that throws away any changes that are made.







### target usage:
This is how we want `ser` to be used:
```lua


local data = cy.start_serialize() -- serializes whole world

local data = cy.poll_serialize(n)
-- serializes a target amount of `n` bytes of data.

-- If nil is returned, the serialization is complete.



cy.start_deserialize(start_data)

local keep_going = cy.poll_deserialize(data, n)
-- serializes a maximum of `n` entities.
-- returns `true` if there are still entities to serialize, false otherwise.


```

We want to ensure that `ser` handles circular references,
handles 


