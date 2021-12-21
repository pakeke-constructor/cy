
local path = (...):gsub("%._cy_testing", "")

local cy = require(path..".cy")


local g_app = cy.get_entities("a", "b")

local g_pla = cy.get_entities("p")

local g_app_bana = cy.get_entities("b")

local g_app_pla = cy.get_entities("a")

local g_app_bana2 = cy.get_entities("edible")

local all = cy.get_entities()




local apple = cy.entity({
    "a", "b",
    
    edible = true,
    color = "red",
    spicy = false,

    type = "apple"
})



local banana = cy.entity({
    "b",
    edible = true,
    color = "yellow",

    type = "banana"
})


local plane = cy.entity({
    "a", "p",
    color = "white",
    type = "plane"
})



local APPLES = 100
local BANANAS = 1000
local PLANES = 503

assert(g_app:size() == 0, g_app:size())
for i=1, APPLES do
    apple()
end
assert(g_app:size() == 0, g_app:size())
cy.flush()
assert(g_app:size() == APPLES, g_app:size())


for i=1,BANANAS do
    banana()
end

for i=1,PLANES do 
    plane()
end

cy.flush()

assert(g_pla:size() == PLANES)
assert(g_app_bana:size() == APPLES + BANANAS)
assert(g_app_pla:size() == APPLES+PLANES)
assert(g_app_bana2:size() == APPLES + BANANAS)
assert(all:size() == APPLES + BANANAS + PLANES)


local DEL = 126

for i, plane in ipairs(g_pla) do
    plane:delete()
    if i == 126 then
        break
    end
end

assert(g_pla:size() == PLANES)

cy.flush()

assert(g_pla:size() == PLANES - DEL)


print("[cy test] all tests passed")

