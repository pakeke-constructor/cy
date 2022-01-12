

--[[

cy testing

]]

local cy = require("cy.cy")

local g_app = cy.get_entities("a", "b")
local g_pla = cy.get_entities("p")
local g_app_bana = cy.get_entities("b")
local g_app_pla = cy.get_entities("a")
local g_app_bana2 = cy.get_entities("edible")
local all = cy.get_entities()



local apple = cy.new_etype({
    "a", "b",
    
    edible = true,
    color = "red",
    spicy = false,
    type = "apple"
}, "apple")



local banana = cy.new_etype({
    "b",
    edible = true,
    color = "yellow",

    type = "banana"
}, "banana")


local plane = cy.new_etype({
    "a", "p",
    color = "white",
    type = "plane"
}, "plane")



local APPLES = 100
local BANANAS = 1000
local PLANES = 503

assert(g_app:size() == 0, g_app:size())
for _=1, APPLES do
    apple()
end

assert(g_app:size() == 0, g_app:size())
cy.flush()
assert(g_app:size() == APPLES, g_app:size())


for _=1,BANANAS do
    banana()
end

for _=1,PLANES do 
    plane()
end

cy.flush()


local assert = assert
assert(g_pla:size() == PLANES)
assert(g_app_bana:size() == APPLES + BANANAS)
assert(g_app_pla:size() == APPLES+PLANES)
assert(g_app_bana2:size() == APPLES + BANANAS)
assert(all:size() == APPLES + BANANAS + PLANES)


local DEL = 126

for i, planee in ipairs(g_pla) do
    planee:delete()
    if i == 126 then
        break
    end
end

assert(g_pla:size() == PLANES)
cy.flush()
assert(g_pla:size() == PLANES - DEL)





local groups = {
    -- array of all groups
    g_app, g_pla, g_app_bana, g_app_bana2, g_app_pla, all
}


--[[ ]]
local d = cy.serialize()

local buff1 = {}
for i=1, #groups do
    local sze = groups[i]:size()
    table.insert(buff1, sze)
end

cy.clear()

local ok, deser_err = cy.deserialize(d)
if (not ok) then
    error("Error in cy deserialization:\n" .. deser_err)
end

local buff2 = {}
for i=1, #groups do
    local sze = groups[i]:size()
    table.insert(buff2, sze)
end

for i, v in ipairs(buff1) do
    assert(v == buff2[i], "Test failed: incorrect group size for group index: " .. tostring(i))
end
for i, v in ipairs(buff2) do
    assert(v == buff1[i], "Test failed: incorrect group size for group index: " .. tostring(i))
end
--]]

print("[cy test] all tests passed")







