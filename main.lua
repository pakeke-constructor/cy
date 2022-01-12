
_G.inspect = require("cy.inspect")

-- selene: allow(global_usage)
setmetatable(_G,{ 
    __index=function(_,k) error("undefined var: " .. tostring(k)) end;
    __newindex = function(_,k) error("attempt to create global: "..tostring(k)) end
})




require("test")


