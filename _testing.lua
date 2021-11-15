

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


local g_ab = cy.group("a", "b")

local g_plane = cy.group("p")

local g_b = cy.group("b")

local g_a = cy.group("a")

local g_ed = cy.group("edible")


for i=1,100 do
    apple()
end

