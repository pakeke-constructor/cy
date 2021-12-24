

setmetatable(_G,{
    __index=function(t,k) error("undefined var: " .. tostring(k)) end;
    __newindex = function(t,k) error("attempt to create global: "..tostring(k)) end
})

require("cy._cy_testing")


