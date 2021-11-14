
# cylua


Hybrid OOP / Entity-Component-System framework,
designed for easy and speedy
serialization and better workings with networking.

The successor of Cyan.



Entity definition:
```lua


-- These are the attributes of the entity.
local template = {"pos", "vel", "control"}


-- These are static attributes of the entity.
template.image = "player_image"

template.update = function(e,dt) ... end




local player = cylua.entity(template)

return player

```



Another entity definition example:
```lua

return cylua.entity({
    "pos", "vel",
    image = "bullet",
    damage = 40
})

```




