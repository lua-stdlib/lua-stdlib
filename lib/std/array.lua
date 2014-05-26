--[[--
 Efficient array of homogenous objects.

 An Array is a block of contiguous memory, divided into equal sized
 elements that can be indexed quickly.

 Create a new Array with:

     > Array = require "std.array"
     > array = Array ("int", {0xdead, 0xbeef, 0xfeed})
     > =array[1], array[2], array[3], array[-3], array[-4]
     57005	48879	65261	57005	nil

 All the indices passed to methods use 1-based counting.

 If the Lua alien module is installed, and the `type` argument passed
 when cloning an Array object is suitable (i.e. the name of a numeric
 C type that alien.array understands), then the array contents are
 managed in an alien.array.

 If alien is not installed, or does not understand the `type` argument
 it is given, then a much slower (but API compatible) Lua table is used
 to manage elements.

 In either case, std.array provides a means for managing collections
 of homogenous Lua objects with a vector-like, stack-like or queue-like
 API.

 @classmod std.array
]]


local base = require "std.base"
local argcheck, argscheck = base.argcheck, base.argscheck

local Object = require "std.object"
local prototype = Object.prototype

local BaseArray = require "std.base_array"

local have_alien, alien = pcall (require, "alien")
local buffer, memmove, memset
if have_alien then
  buffer, memmove, memset = alien.buffer, alien.memmove, alien.memset
else
  buffer = function () return {} end
end
local typeof = type


local element_chunk_size = 16


--- Convert an array element index into a pointer.
-- @tparam std.array self an array
-- @int i[opt=1] an index into array
-- @treturn alien.buffer.pointer suitable for memmove or memset
local function topointer (self, i)
  i = i or 1
  return self.buffer:topointer ((i - 1) * self.size + 1)
end


--- Fast zeroing of a contiguous block of array elements for `alien.buffer`s.
-- @tparam std.array self an array
-- @int from index of first element to zero out
-- @int n number of elements to zero out
local function setzero (self, from, n)
  if n > 0 then memset (topointer (self, from), 0, n * self.size) end
end


local _functions = {
  --- Remove the right-most element.
  -- @function pop
  -- @return the right-most element
  pop = function (self)
    argscheck ("pop", {"Array"}, {self})

    local used = self.length
    if used > 0 then
      local elem = self[used]
      self:realloc (used - 1)
      return elem
    end
    return nil
  end,


  --- Add elem as the new right-most element.
  -- @function push
  -- @param elem new element to be pushed
  -- @return elem
  push = function (self, elem)
    argscheck ("push", {"Array", "number"}, {self, elem})

    local used = self.length + 1
    self:realloc (used)
    self[used] = elem
    return elem
  end,


  --- Change the number of elements allocated to be at least `n`.
  -- @function realloc
  -- @int n the number of elements required
  -- @treturn Array the array
  realloc = function (self, n)
    argscheck ("realloc", {"Array", "number"}, {self, n})

    if n > self.allocated or n < self.allocated / 2 then
      self.allocated = n + element_chunk_size
      self.buffer:realloc (self.allocated * self.size)
    end

    -- Zero padding for uninitialised elements.
    local used = self.length
    self.length = n
    setzero (self, used + 1, n - used)

    return self
  end,


  --- Set `n` elements starting at `from` to `v`.
  -- @function set
  -- @int from index of first element to set
  -- @int v value to store
  -- @int n number of elements to set
  -- @treturn Array the array
  set = function (self, from, v, n)
    argscheck ("set", {"Array", "number", "number", "number"},
               {self, from, v, n})

    local used = self.length
    if from < 0 then from = from + used + 1 end
    assert (from > 0 and from <= used)

    local i = from + n - 1
    while i >= from do
      self[i] = v
      i = i - 1
    end
    return self
  end,


  --- Shift the whole array to the left by removing the left-most element.
  -- This makes the array 1 element shorter than it was before the shift.
  -- @function shift
  -- @return the removed element.
  shift = function (self)
    argscheck ("shift", {"Array"}, {self})

    local n = self.length - 1
    if n >= 0 then
      local elem = self[1]
      memmove (topointer (self), topointer (self, 2), n * self.size)
      self:realloc (n)
      return elem
    end
    return nil
  end,


  --- Shift the whole array to the right by inserting a new left-most element.
  -- @function unshift
  -- @param elem new element to be pushed
  -- @treturn elem
  unshift = function (self, elem)
    argscheck ("unshift", {"Array", "number"}, {self, elem})

    local n = self.length
    self:realloc (n + 1)
    memmove (topointer (self, 2), topointer (self), n * self.size)
    self[1] = elem
    return elem
  end,
}


--- Number of bytes needed in an alien.buffer for each `type` element.
-- @string type name of an element type
-- @treturn int bytes per `type`, or 0 if alien.buffer cannot store `type`s
local function sizeof (type)
  local ok, size = pcall ((alien or {}).sizeof, type)
  return ok and size or 0
end


------
-- An efficient array of homogenous objects.
-- @table Array
-- @int length number of elements currently allocated
-- @tfield alien.array array a block of indexable memory
local Array = Object {
  _type = "Array",


  -- Prototype initial values.
  allocated = 1,
  buffer    = buffer (sizeof "int"),
  length    = 0,
  size      = sizeof "int",
  type      = "int",


  -- Module functions.
  _functions = _functions,


  --- Instantiate a newly cloned Array.
  -- If not specified, `type` will be the same as the prototype array being
  -- cloned; otherwise, it can be any string.  Only valid alien accepted by
  -- `alien.array` will use the fast `alien.array` managed memory buffer for
  -- Array contents; otherwise, a much slower Lua emulation is used.
  -- @function __call
  -- @string type element type name
  -- @tparam[opt] int|table init initial size or list of initial elements
  -- @treturn Array a new Array object
  __call = function (self, type, init)
    if init ~= nil then
      -- When called with 2 arguments:
      argcheck ("Array", 1, "string", type)
      argcheck ("Array", 2, {"number", "table"}, init)
    elseif type ~= nil then
      -- When called with 1 argument:
      argcheck ("Array", 1, {"number", "string", "table"}, type)
    end

    -- Non-string argument 1 is really an init argument.
    if typeof (type) ~= "string" then type, init = nil, type end

    type = type or self.type
    init = init or self.length

    -- If type cannot be managed by an alien.buffer, revert to a table
    -- based BaseArray object instead.
    local size = sizeof (type)
    if size == 0 then
      return BaseArray (init)
    end

    -- This will become the cloned Array object.
    local obj = {}

    for k, v in pairs (self) do
      if typeof (v) ~= "table" or v._type ~= "modulefunction" then
        obj[k] = v
      end
    end
    obj.size = size
    obj.type = type

    if typeof (init) == "table" then
      obj.length = #init
      obj.allocated = #init
      obj.buffer = buffer (size * #init)
      for i = 1, #init do
        obj.buffer:set ((i - 1) * size + 1, init[i], type)
      end
    else
      obj.length = init
      obj.allocated = math.max (init or 0, 1)
      obj.buffer = buffer (size * obj.allocated)

      if size == self.size then
        local bytes = math.min (init, self.length) * size
        memmove (obj.buffer:topointer (), self.buffer:topointer (), bytes)
      else
        local a, b = obj.buffer, self.buffer
        for i = 1, math.min (init, self.length) do a[i] = b[i] end
      end
      setzero (obj, self.length + 1, init - self.length)
    end

    return setmetatable (obj, getmetatable (self))
  end,


  --- Return the number of elements in this Array.
  -- @function __len
  -- @treturn int number of elements
  __len = function (self)
    argscheck ("__len", {"Array"}, {self})
    return self.length
  end,


  --- Return the `n`th character in this Array.
  -- @function __index
  -- @int n 1-based index, or negative to index starting from the right
  -- @treturn string the element at index `n`
  __index = function (self, n)
    argscheck ("__index", {"Array", {"number", "string"}}, {self, n})

    if typeof (n) == "number" then
      if n < 0 then n = n + self.length + 1 end
      if n > 0 and n <= self.length then
        return self.buffer:get ((n - 1) * self.size + 1, self.type)
      end
    else
      return _functions[n]
    end
  end,


  --- Set the `n`th element of this Array to `elem`.
  -- @function __newindex
  -- @int n 1-based index
  -- @param elem value to store at index n
  -- @treturn Array the array
  __newindex = function (self, n, elem)
    argscheck ("__newindex", {"Array", "number", "number"}, {self, n, elem})

    if typeof (n) == "number" then
      local used = self.length
      if n == 0 or math.abs (n) > used then
	error ("array access " .. n .. " out of bounds: 0 < n <= " .. tostring (self.length), 2)
      end
      if n < 0 then n = n + used + 1 end
      self.buffer:set ((n - 1) * self.size + 1, elem, self.type)
    else
      rawset (self, n, elem)
    end
    return self
  end,


  --- Return a string representation of the contents of this Array.
  -- @function __tostring
  -- @treturn string string representation
  __tostring = function (self)
    argscheck ("__tostring", {"Array"}, {self})

    local t = {}
    for i = 1, self.length do
      t[#t + 1] = tostring (self[i])
    end
    t = { '"' .. self.type .. '"', "{" .. table.concat (t, ", ") .. "}" }
    return prototype (self) .. " (" .. table.concat (t, ", ") .. ")"
  end,
}

return Array
