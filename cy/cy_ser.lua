


local ignore_fields = {
    --[[
        fields that are ignored in tables and entities.
    ]]
    ___type = true;
    
    ___serialize = true;
    ___deserialize = true;
    
    ___flat = true;
}


--[[
cy serialization
chars:


242  =  
243  =  float

244  =  true
245  =  false

246  =  string

247  =  entity   (etype_id, table data)
248  =  ent_ref  (ent_id)

249  =  array    (table data)
250  =  table    (table data + keys)

251  =  resource   (int ref)
252  =  reference  (int ref)


Whats the difference between a resource and a reference?
References are temporary to this serialization session.

Resources are constant across all serialization sessions,
and usually target constant tables and stuff.
For example, all library tables, like `math`, `_G`, etc, 
should be made resources.
(The user can also define custom resources.)


]]




