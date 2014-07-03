--[[--
 Vector of homogenous objects.

 A vector is usually a block of contiguous memory, divided into equal
 sized elements that can be indexed quickly.

 Create a new vector with:

     > vector = require "std.vector"
     > Vector = vector ()
     > a = Vector ("int", {0xdead, 0xbeef, 0xfeed})
     > =a[1], a[2], a[3], a[-3], a[-4]
     57005	48879	65261	57005	nil

 All the indices passed to vector methods use 1-based counting.

 If the Lua alien module is installed, and the `type` argument passed
 when cloning a new vector object is suitable (i.e. the name of a numeric
 C type that `alien.sizeof` understands), then the vector contents are
 managed in an `alien.buffer`.

 If alien is not installed, or does not understand the `type` argument
 given when cloning, then a much slower (but API compatible) Lua table
 is transparently used to manage elements instead.

 In either case, `std.vector` provides a means for managing collections
 of homogenous Lua objects with an array-like, stack-like or queue-like
 API.

 @classmod std.vector
]]


local _ARGCHECK = require "std.debug_init"._ARGCHECK

local have_alien, alien = pcall (require, "alien")
local base      = require "std.base"
local container = require "std.container"

local Container = container {}

local typeof = type

local argcheck, argscheck, prototype =
      base.argcheck, base.argscheck, base.prototype


--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


local buffer, memmove, memset
if have_alien then
  buffer, memmove, memset = alien.buffer, alien.memmove, alien.memset
else
  buffer = function () return {} end
end


--- Number of bytes needed in an alien.buffer for each `type` element.
-- @string type name of an element type
-- @treturn int bytes per `type`, or 0 if alien.buffer cannot store `type`s
local function sizeof (type)
  local ok, size = pcall ((alien or {}).sizeof, type)
  return ok and size or 0
end


--- Convert a vector element index into a pointer.
-- @tparam std.vector self a vector
-- @int i[opt=1] an index into vector
-- @treturn alien.buffer.pointer suitable for memmove or memset
local function topointer (self, i)
  i = i or 1
  return self.buffer:topointer ((i - 1) * self.size + 1)
end


--- Fast zeroing of a contiguous block of vector elements for `alien.buffer`s.
-- @tparam std.vector self a vector
-- @int from index of first element to zero out
-- @int n number of elements to zero out
local function setzero (self, from, n)
  if n > 0 then memset (topointer (self, from), 0, n * self.size) end
end



--[[ ================== ]]--
--[[ Lua Table Manager. ]]--
--[[ ================== ]]--


-- Initial vector prototype object, plus any derived object containing
-- elements that don't fit in alien buffers use `core_functions` to
-- find object methods and `core_metatable` for metamethods.

local core_metatable, alien_metatable -- forward declarations


local core_functions = {
  --- Remove the right-most element.
  -- @function pop
  -- @return the right-most element
  -- @usage removed = anvector:pop ()
  pop = function (self)
    self.length = math.max (self.length - 1, 0)
    return table.remove (self.buffer)
  end,


  --- Add elem as the new right-most element.
  -- @function push
  -- @param elem new element to be pushed
  -- @return elem
  -- @usage added = anvector:push (anelement)
  push = function (self, elem)
    local length = self.length + 1
    self.buffer[length] = elem
    self.length = length
    return elem
  end,


  --- Change the number of elements allocated to be at least `n`.
  -- @function realloc
  -- @int n the number of elements required
  -- @treturn std.vector the vector
  -- @usage anvector = anvector:realloc (anvector.length)
  realloc = function (self, n)
    argcheck ("realloc", 2, "int", n)

    -- Zero padding for uninitialised elements.
    for i = self.length + 1, n do
      self.buffer[i] = 0
    end
    self.length = n

    return self
  end,


  --- Set `n` elements starting at `from` to `v`.
  -- @function set
  -- @int from index of first element to set
  -- @param v value to store
  -- @int n number of elements to set
  -- @treturn std.vector the vector
  -- @usage anvector:realloc (anvector.length):set (1, -1, anvector.length)
  set = function (self, from, v, n)
    argscheck ("set", {"Vector", "int", "any", "int"},
               {self, from, v, n})

    local length = self.length
    if from < 0 then from = from + length + 1 end
    assert (from > 0 and from <= length)

    for i = from, from + n - 1 do
      self[i] = v
    end

    return self
  end,


  --- Shift the whole vector to the left by removing the left-most element.
  -- This makes the vector 1 element shorter than it was before the shift.
  -- @function shift
  -- @return the removed element.
  -- @usage removed = anvector:shift ()
  shift = function (self)
    self.length = math.max (self.length - 1, 0)
    return table.remove (self.buffer, 1)
  end,


  --- Shift the whole vector to the right by inserting a new left-most element.
  -- @function unshift
  -- @param elem new element to be pushed
  -- @treturn elem
  -- @usage added = anvector:unshift (anelement)
  unshift = function (self, elem)
    self.length = self.length + 1
    table.insert (self.buffer, 1, elem)
    return elem
  end,
}


core_metatable = {
  _type = "Vector",


  --- Instantiate a newly cloned vector.
  -- If not specified, `type` will be the same as the prototype vector being
  -- cloned; otherwise, it can be any string.  Only a type name accepted by
  -- `alien.sizeof` will use the fast `alien.buffer` managed memory buffer
  -- for vector contents; otherwise, a much slower Lua emulation is used.
  -- @function __call
  -- @string type element type name
  -- @tparam[opt] int|table init initial size or list of initial elements
  -- @treturn std.vector a new vector object
  -- @usage
  -- local Vector = require "std.vector" {} -- not a typo!
  -- local new = Vector ("int", {1, 2, 3})
  __call = function (self, type, init)
    if _ARGCHECK then
      if init ~= nil then
        -- When called with 2 arguments:
        argcheck ("Vector", 1, "string", type)
        argcheck ("Vector", 2, "int|table", init)
      elseif type ~= nil then
        -- When called with 1 argument:
        argcheck ("Vector", 1, "int|string|table", type)
      end
    end

    -- Non-string argument 1 is really an init argument.
    if typeof (type) ~= "string" then type, init = nil, type end

    type = type or self.type
    init = init or self.length

    -- This will become the cloned vector object.
    local obj = {}

    for k, v in pairs (self) do
      if typeof (v) ~= "table" or v._type ~= "modulefunction" then
        obj[k] = v
      end
    end

    local size = sizeof (type)
    obj.size = size -- setzero uses self.size for byte calculations

    if size == 0 then

      -- Either alien is not installed, or it cannot handle elements
      -- of `type`, so we'll use Lua tables and core_metatable:
      local b = {}
      if typeof (init) == "table" then
        for i = 1, #init do
          b[i] = init[i]
        end
      else
        local plength = self.length
        local length = init or plength
        for i = 1, math.min (plength, length) do
          b[i] = self.buffer[i]
        end
        for i = plength + 1, length do
          b[i] = 0
        end
      end
      obj.allocated = 0
      obj.buffer    = b
      obj.length    = #b

      setmetatable (obj, core_metatable)

    else

      -- We have alien, and it knows how to manage elements of `type`,
      -- so we'll use an alien.buffer and alien_metatable:
      if typeof (init) == "table" then
        obj.allocated = #init
        obj.buffer    = buffer (size * #init)
        obj.length    = #init

        for i = 1, #init do
          obj.buffer:set ((i - 1) * size + 1, init[i], type)
        end
      else
        obj.allocated = math.max (init or 0, 1)
        obj.buffer    = buffer (size * obj.allocated)
        obj.length    = init

        if size == self.size then
          local bytes = math.min (init, self.length) * size
          memmove (obj.buffer:topointer (), self.buffer:topointer (), bytes)
        else
          local a, b = obj.buffer, self.buffer
          for i = 1, math.min (init, self.length) do a[i] = b[i] end
        end
        setzero (obj, self.length + 1, init - self.length)
      end

      setmetatable (obj, alien_metatable)

    end
    obj.type = type

    return obj
  end,


  --- Iterate consecutively over all elements with `ipairs (vector)`.
  -- @function __ipairs
  -- @treturn function iterator function
  -- @usage for index, anelement in ipairs (anvector) do ... end
  __ipairs = function (self)
    local i, n = 0, self.length
    return function ()
      i = i + 1
      if i <= n then
        return i, self.buffer[i]
      end
    end
  end,


  --- Return the `n`th element in this vector.
  -- @function __index
  -- @int n 1-based index, or negative to index starting from the right
  -- @treturn string the element at index `n`
  -- @usage rightmost = anvector[anvector.length]
  __index = function (self, n)
    argcheck ("__index", 2, "int|string", n)

    if typeof (n) == "number" then
      if n < 0 then n = n + self.length + 1 end
      if n > 0 and n <= self.length then
        return self.buffer[n]
      end
    else
      return core_functions[n]
    end
  end,


  --- Set the `n`th element of this vector to `elem`.
  -- @function __newindex
  -- @int n 1-based index
  -- @param elem value to store at index n
  -- @treturn std.vector the vector
  -- @usage anvector[1] = newvalue
  __newindex = function (self, n, elem)
    argcheck ("__newindex", 2, "int",  n)

    if typeof (n) == "number" then
      local used = self.length
      if n == 0 or math.abs (n) > used then
	error ("vector access " .. n .. " out of bounds: 0 < abs (n) <= " ..
               tostring (self.length), 2)
      end
      if n < 0 then n = n + used + 1 end
      self.buffer[n] = elem
    else
      rawset (self, n, elem)
    end
    return self
  end,


  --- Return the number of elements in this vector.
  --
  -- Beware that Lua 5.1 does not respect this metamethod; use
  -- `vector.length` if you care about portability.
  -- @function __len
  -- @treturn int number of elements
  -- @usage length = #anvector
  __len = function (self)
    argcheck ("__len", 1, "Vector", self)

    return self.length
  end,


  --- Return a string representation of the contents of this vector.
  -- @function __tostring
  -- @treturn string string representation
  -- @usage print (anvector)
  __tostring = function (self)
    argcheck ("__tostring", 1, "Vector", self)

    local t = {}
    for i = 1, self.length do
      t[#t + 1] = tostring (self[i])
    end
    return prototype (self) .. ' ("' .. self.type ..
           '", {' .. table.concat (t, ", ") .. "})"
  end,
}



--[[ ===================== ]]--
--[[ Alien Buffer Manager. ]]--
--[[ ===================== ]]--


-- Cloned vector objects with elements managed by an alien buffer use
-- `alien_functions` to find object methods and `alien_metatable`
-- for metamethods.


local element_chunk_size = 16


local alien_functions = {
  pop = function (self)
    local used = self.length
    if used > 0 then
      local elem = self[used]
      self:realloc (used - 1)
      return elem
    end
    return nil
  end,


  push = function (self, elem)
    argcheck ("push", 2, "number", elem)

    local used = self.length + 1
    self:realloc (used)
    self[used] = elem
    return elem
  end,


  realloc = function (self, n)
    argcheck ("realloc", 2, "int", n)

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


  set = function (self, from, v, n)
    argscheck ("set", {"Vector", "int", "number", "int"},
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


  shift = function (self)
    local n = self.length - 1
    if n >= 0 then
      local elem = self[1]
      memmove (topointer (self), topointer (self, 2), n * self.size)
      self:realloc (n)
      return elem
    end
    return nil
  end,


  unshift = function (self, elem)
    argcheck ("unshift", 2, "number", elem)

    local n = self.length
    self:realloc (n + 1)
    memmove (topointer (self, 2), topointer (self), n * self.size)
    self[1] = elem
    return elem
  end,
}


alien_metatable = {
  _type = "Vector",

  __ipairs = function (self)
    local i, n = 0, self.length
    return function ()
      i = i + 1
      if i <= n then
        return i, self.buffer:get ((i - 1) * self.size + 1, self.type)
      end
    end
  end,

  __index = function (self, n)
    argcheck ("__index", 2, "int|string", n)

    if typeof (n) == "number" then
      if n < 0 then n = n + self.length + 1 end
      if n > 0 and n <= self.length then
        return self.buffer:get ((n - 1) * self.size + 1, self.type)
      end
    else
      return alien_functions[n]
    end
  end,

  __newindex = function (self, n, elem)
    argcheck ("__newindex", 2, "int", n)
    argcheck ("__newindex", 3, "number", elem)

    if typeof (n) == "number" then
      local used = self.length
      if n == 0 or math.abs (n) > used then
	error ("vector access " .. n .. " out of bounds: 0 < n <= " .. tostring (self.length), 2)
      end
      if n < 0 then n = n + used + 1 end
      self.buffer:set ((n - 1) * self.size + 1, elem, self.type)
    else
      rawset (self, n, elem)
    end
    return self
  end,

  __call     = core_metatable.__call,
  __len      = core_metatable.__len,
  __tostring = core_metatable.__tostring,
}



--[[ ========================= ]]--
--[[ Public Dispatcher Object. ]]--
--[[ ========================= ]]--


--- Return a function that dispatches to a virtual function table.
-- The __call metamethod ensures that cloned vector objects are assigned
-- a metatable and method table optimised for the element storage method
-- (either alien buffer, or Lua table element containers), but the vector
-- prototype returned by this module needs to dispatch to the correct
-- function according to the element type at run-time, because we want
-- to support passing either object as an argument to a module function.
-- @string name method name to dispatch
-- @treturn function call `alien_function[name]` or -- `core_function[name]`
--  as appropriate to the element manager of vector
local function dispatch (name)
  return function (vector, ...)
    argcheck (name, 1, "Vector", vector)
    local vfns = vector.size > 0 and alien_functions or core_functions
    return vfns[name] (vector, ...)
  end
end


------
-- An efficient vector of homogenous objects.
-- @table std.vector
-- @int allocated number of allocated element slots, for `alien.buffer`
--  managed elements
-- @tfield alien.buffer|table buffer a block of indexable memory
-- @int length number of elements currently stored
-- @int size length of each stored element, or 0 when `alien.buffer` is
--  not managing this vector
-- @string type type name for elements
local Vector = Container {
  _type = "Vector",


  -- Prototype initial values.
  allocated = 0,
  buffer    = {},
  length    = 0,
  size      = 0,
  type      = "any",


  _functions = {
    pop     = dispatch "pop",
    push    = dispatch "push",
    realloc = dispatch "realloc",
    set     = dispatch "set",
    shift   = dispatch "shift",
    unshift = dispatch "unshift",
  },


  __index    = dispatch "__index",
  __newindex = dispatch "__newindex",

  __call     = core_metatable.__call,
  __len      = core_metatable.__len,
  __tostring = core_metatable.__tostring,
}


return Vector
