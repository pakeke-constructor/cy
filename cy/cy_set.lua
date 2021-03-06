
--[[
MIT License
Copyright (c) 2018 Justin van der Leij
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]


local set = {}

local set_mt = {__index=set}


--- Creates a new set.
-- @return A new list
function set.new()
   return setmetatable({
      objects  = {},
      pointers = {},
      size     = 0,
   }, set_mt)
end

--- Clears the set completely.
-- @return self
function set:clear()
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

--- Adds an object to the set.
-- @param obj The object to add
-- @return self
function set:add(obj)
   if self:has(obj) then
      return self
   end

   local size = self.size + 1

   self.objects[size] = obj
   self.pointers[obj] = size
   self.size          = size

   return self
end

--- Removes an object from the set. If the object isn't in the set, returns nil.
-- @param obj The object to remove
-- @param index The known index
-- @return self
function set:remove(obj, index)

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

   return self
end

--- Gets an object by numerical index.
-- @param index The index to look at
-- @return The object at the index
function set:get(index)
   return self.objects[index]
end

--- Gets if the set has the object.
-- @param obj The object to search for
-- @param true if the list has the object, false otherwise
function set:has(obj)
   return self.pointers[obj] and true
end


--- Returns a memory-unique copy of another set
-- @return copied set
function set:copy()
   local new = set.new()
   for i=1,self.size do
      new:add(self.objects[i])
   end
   return new
end




return set.new

