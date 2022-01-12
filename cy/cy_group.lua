
local path = (...):gsub("%.cy_group", "")

local sset = require(path..".cy_set")
local pckr = require(path..".pckr")


local group = {}
local group_mt = {__index = group}


-- `view` is what the user has access to!!!
local view = {} -- User view method proxy
local view_mt = {__index = view}

pckr.register(view_mt, "view_mt")
pckr.low.set_template(view_mt, {"foo"})


function view:size()
   return self.___self.size
end

view.length = view.size -- Aliases
view.len = view.size

function view:has(ent)
   return self.___self.pointers[ent]
end


-- callback for when entities are added  (signature:  (ent))
function view:on_added(func)
    local g = self.___self
    g.added_cbs:add(func)
end

-- callback for when entities are removed (signature:  (ent))
function view:on_removed(func)
    local g = self.___self
    g.removed_cbs:add(func)
end

function view:delete_callback(func)
    local g = self.___self
    -- deletes this callback from both `on_added` and `on_removed`
    g.added_cbs:remove(func)
    g.removed_cbs:remove(func)
end



local function new(fields)
   local has_field = {}
   for i=1, #fields do
      has_field[fields[i]] = true
   end

   local ret = setmetatable({
      added_cbs = sset(), -- Added and removed callbacks
      removed_cbs = sset(),

      view      = setmetatable({}, view_mt),
      pointers  = {},
      size      = 0,
      has_f  = has_field, -- used interally by cy_groups.
      fields = fields -- used internally too.
   }, group_mt)

   ret.view.___self = ret

   return ret
end




function group:clear() -- private method
   -- be nice on GC
   local obj
   local objs = self.view
   local ptrs = self.pointers
   for i=1, #self.view do
      obj = objs[i]
      ptrs[obj] = nil
      objs[i] = nil
      if self.view.removed then
         self.view.removed(obj)
      end    
   end
   self.view  = {
      ___self = self
   }
   self.pointers = {}
   self.size     = 0
   return self
end



function group:add(obj) -- private method
    if self.pointers[obj] then
        return self
    end

    local size = self.size + 1

    self.view[size] = obj
    self.pointers[obj] = size
    self.size          = size

    if self.added then
        self.view.added(obj) -- added callback
    end

    return self
end



function group:remove(obj, index) -- private method
   if not self.pointers[obj] then
      return nil
   end

   index = index or self.pointers[obj]
   local size  = self.size

   if index == size then
      self.view[size] = nil
   else
      local other = self.view[size]

      self.view[index]  = other
      self.pointers[other] = index

      self.view[size] = nil
   end

   self.pointers[obj] = nil
   self.size = size - 1

   if self.view.removed then
      self.view.removed(obj) -- removed callback0
   end

   return self
end




function group:has(obj)
   return self.pointers[obj] and true
end

group.contains = group.has


function group:ipairs()
   return ipairs(self.view)
end

group.iter = group.ipairs




return new

