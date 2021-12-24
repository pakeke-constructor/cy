


# Entities need to be able to:

Know what fields to serialize at "load time"

Define shared constants


Be initialized with a CTOR
- hmm, should this be done by cy? We don't really need a ctor do we?


#### EACH ENTITY SHOULD HAVE A `.id` FIELD!!!


### Serialization planning:
We need a `cy_version` field at the top of the header.
Okay, this is what it should consist of:
(Assume there are no gaps in data.)

#### world header file:
Key:
anything inside of <these> is data to be put into the file



### ISSUE 1:
We need to serialize ents, but we ALSO need to NOT serialize
any nested entities!!!

Okay:
We could use serialization functions:
`serialize` and `deserialize`.
Put an upvalue flag outside each of the serialize functions that
describes whether we should serialize by id or by the actual ent table.

FOR ALL NESTED `serialize` CALLS, THIS FLAG MUST BE TRUE!!!!
We don't want to serialize nested entities, we just want their ids.


### ISSUE 2:
Another issue:
How do we distinguish ent ids from a number?
AHA! We don't even need to, binser will do it for us if we register it as a 
custom type.
We either serialize as a `number` or a `table.` Since binser will always know
if a type is a table or a number, we will know whether we serialized it as an
id, (because its a number,) and we will know whether we serialized as a table.

-->> Issue with this solution:
References are not 

### ISSUE 3:
binser may not recognise our entities because the metatable is protected.
Uh oh....
Do some checks on this! ^^^^^^^^
this could be a hard to catch bug if we forget about it!









### API:
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


<cyan_version>

>> ent type definitions. This is done so we can check that ent implementations
>> are consistent across different versions.
>> If this file's ent-def is different from the current ent-defs defined,
>> We are in trouble; however there are ways around it:
>>
>> If this file's ent-def has LESS fields than the current ent-def,
>> We set the extra fields to `false`,
>> or call a callback.  (TODO: How do we define this Callback?)
>>
>> If a deserialized ent has MORE fields than the current ent-def, the extra
>> fields are simply thrown away.
>>
>> In both cases, a warning prompt should be sent to the user!!!!!!
<etype_name___to___dynamic_fields>
{
    player = {
        "controller", "pos", "vel"
    };

    enemy = {
        "target", "pos", "vel", "hp"
    };
}


>> Now we just have a list of ents.
>> If any are in the incorrect format, they are dealt with as per above.
<ent_1>
<ent_2>
<ent_3>
<ent_4>
<ent_5>
...
...
<ent_N>

