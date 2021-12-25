
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
  (The reason this works is because we won't need to update entities that
    don't exist yet! The updates will come through when we recv the entity.)




>>> Resources and References:
`Whats the difference between a resource and a reference?`
References are temporary to a single serialization session.

Resources are constant across ALL serialization sessions,
and are usually commomly used tables and stuff.
For example, all library tables, like `math`, `_G`, etc, 
should be made resources.
(The user can also define custom resources.)

Common strings should also be made resources too!
For example, all strings that represent images should be made a resource.



### aha, take a look at this:
https://www.lua.org/manual/5.3/manual.html#6.4.2
Any format string starts as if prefixed by "!1=", 
that is, with maximum alignment of 1 (no alignment) and native endianness.
(note the `no alignment`.)






### target usage:
This is how we want `ser` to be used:
```lua

-- adds a resource (same as `binser`)
ser.resource(resource, name)



ser.register_type(metatable, name)

ser.unregister_type(metatable, name)


-- sets a template for type keys, so it can be flattened.
ser.add_template(vector_metatable, {"x", "y", "z"})






ser.clear() -- clears resources, and stops any 
-- serialization or deserialization that is currently happening.



-- Simple instant deserialization and serialization
local data = ser.serialize(a, b, c, d, e)
local a, b, c, d, e = ser.deserialize(data)



local poller, data = ser.serialize_async()
-- gets an async serialization object.

local data = poller:serialize(max_bytes, ...)
-- serializes a target amount of `max_bytes` bytes of data.
-- If nil is returned, the serialization is complete.



local reader, err = ser.deserialize_async(start_data)
-- If it cannot deserialize, `reader` is nil, and error msg is returned.

local data, err = reader:deserialize(data)
-- returns `true` if there are still entities to serialize, false otherwise.



```

