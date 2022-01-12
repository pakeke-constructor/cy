

### ISSUES


Client / Server side entities.
What happens if we create a client side entity, with ent.id = 6969
and another entity is created on the server-side.
(Imagine that the server side entity also has ent.id = 6969)
Suddenly, the server sends over the Server-side entity, and tells the client
to create it!!
Oh no! this is bad.
--> Basically, I think this means that we shouldn't allow entities to exist
on the server-side or client-side only; they must exist on both sides at once.








Issues we may run into whilst serializing:


Serializing an entity, and then deleting the entity straight after.
ISSUE: what if the packets are recieved out of order???
- SOLN: Make sure in-order packets are recieved!




Sending ents
ISSUE: If we are sending over the entity array, an entities swap positions.
I.e. we are halfway through sending the entity list, and we do the classic:
```lua
ents[i], ents[#ents] = ents[#ents], nil -- deletes `ents[i]`
```
The issue here, is if we have serialized PAST index `i`. This would mean the
final entity won't get serialized!!!
- SOLN:  Serialize ents by id.   I.e, do something like:
```lua
for id=1, cy.get_max_id() do
    if cy.get_ent(id) then
        serialize(id) ... you get the idea
    end
end
```



ISSUE of nested entities getting in way of packet syncing:
This is gonna be hard to explain:::
Imagine that we want to serialize entities *greedily.*
I.e, we serialize all nested entities recursively, up to an unspecified depth.
This could work OK!  The issue however- is that we will be half-done serializing
many entities further up the call stack.
And if we are half-done serializing a lot of entities, there is a good chance
that those entities could become outdated if the serialization sending is done
over multiple frames.                       
(Because obviously, an entity can't be used if its only half-serialized!!!)

PROPOSED SOLUTION:  If the `pckr` serialization depth is greater than 1,
don't serialize the entity- rather serialize a `FUTURE_REF` to the entity.
(NOTE: This will mean that you will have to add some new functionality to define
how future_refs behave; you'll have to add something like `pckr.add_template`,
except for future refs.







ISSUE of out-syncing on initialize w/ lazy entity updating:
During serialization, we have 2 types of entities: `ready ents`, 
and `expected ents`.  "ready ents" are entities that have been fully recieved;
we are listening for updates to them. `expected ents` are ones that we have
yet to recieve, (but they may already be tagged via FUTURE REFs.)
----------->
The issue is if a `ready ent` field is updated to a value inside an 
`expected ent`. We won't be able to determine what to set the ready ent's 
field to, because the expected ent has not been recieved!!!!
EXAMPLE:
```lua
-- Server side:
server:broadcast("some_event", 
    e1, -- lets say on client side, `e1` is has been recieved, (ready)
    e2 -- but e2 has not been sent yet. (expected)
) 

-- Client side:
client:on("some_event", function(e1, e2)
    e1.x = e2.x -- CRAP! This is terrible:
    -- e2 does not exist yet!!! at the moment, its a FUTURE_REF.
end)
```

PROPOSED SOLUTION:
TODO:
No solution here I don't think; this is probably unsolveable.
The best we can do is just to encourage modders to not mutate entity state
outside of direct ent update broadcasts.
--> BUT KEEP THINKING OF POTENTIAL SOLUTIONS!!!





Solution:
We don't do async serialization;
just pause the server whilst players are joining.
There's no better way I don't think   :/










