
local group = {}


local function new()
   return setmetatable({
      objects  = {},
      pointers = {},
      size     = 0,
   }, group)
end



function group:___clear()
   -- be nice on GC
   local obj
   local objs = self.objects
   local ptrs = self.pointers
   for i=1, #self.objects do
      obj = objs[i]
      ptrs[obj] = nil
      objs[i] = nil    
   end
   self.objects  = {}
   self.pointers = {}
   self.size     = 0
   return self
end



function group:___add(obj)
   if self.pointers[obj] then
      return self
   end

   if self.added then
      self.added(obj)
   end

   local size = self.size + 1

   self.objects[size] = obj
   self.pointers[obj] = size
   self.size          = size

   return self
end



function group:___remove(obj, index)

   if not self.pointers[obj] then
      return nil
   end

   index = index or self.pointers[obj]
   local size  = self.size

   if index == size then
      self.objects[size] = nil
   else
      local other = self.objects[size]

      self.objects[index]  = other
      self.pointers[other] = index

      self.objects[size] = nil
   end

   self.pointers[obj] = nil
   self.size = size - 1

   if self.removed then
      self.removed(obj) -- removed callback
   end

   return self
end




function group:has(obj)
   return self.pointers[obj] and true
end

group.contains = group.has



return new

