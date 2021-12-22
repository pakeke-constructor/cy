


# Entities need to be able to:

Know what fields to serialize at "load time"

Define shared constants


Be initialized with a CTOR
- hmm, should this be done by cy? We don't really need a ctor do we?





### Serialization planning:
We need a `cy_version` field at the top of the header.
Okay, this is what it should consist of:
(Assume there are no gaps in data.)

#### world header file:
Key:
anything inside of <these> is data to be put into the file




<cyan_version>

>> ent_typename to char mapping:
>> (Saves us alot of space. If we don't have this, `binser` will write
>>   every single entity name into each entity, which sucks!)
<ent-typename__to__char-mapping>
{
    "\1" = "player";
    "\2" = "enemy";
}

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

