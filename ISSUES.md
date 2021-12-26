

### ISSUES
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

