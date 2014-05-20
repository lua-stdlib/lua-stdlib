--[[--
 Efficient array of homogenous objects.

 An Array is a block of contiguous memory, divided into equal sized
 elements that can be indexed quickly.

 Create a new Array with:

     > Array = require "std.array"
     > array = Array ("int", 0xdead, 0xbeef, 0xfeed)
     > =array[1], array[2], array[3], array[-1]
     57005	48879	65261	65261

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


local debug  = require "std.debug"
local argcheck, argscheck = debug.argcheck, debug.argscheck

local Object = require "std.object"
local prototype = Object.prototype

local alien_type = {}

local have_alien, alien = pcall (require, "alien")
if have_alien then

  -- Element types to be managed by alien:
  for e in require "std.base".elems {
    "byte", "char", "short", "ushort", "int", "uint", "long", "ulong",
    "ptrdiff_t", "size_t", "float", "double", "pointer",
    "ref char", "ref int", "ref uint", "ref double",
    "longlong", "ulonglong"}
  do
      alien_type[e] = true
  end

else

  -- Fallback to Lua implementation.
  alien = require "std.alien"

end
local calloc, memmove, memset, sizeof =
      alien.array, alien.memmove, alien.memset, alien.sizeof
local typeof = type


local element_chunk_size = 16


--- Convert an array element index into a pointer.
-- @tparam alien.array array an array
-- @int i[opt=1] an index into array
-- @treturn alien.buffer.pointer suitable for memmove or memset
local function topointer (array, i)
  i = i or 1
  return array.buffer:topointer ((i - 1) * array.size + 1)
end


--- Fast zeroing of a contiguous block of array elements.
-- @tparam alien.array array an array
-- @int from index of first element to zero out
-- @int n number of elements to zero out
-- @treturn alien.array array
local function setzero (array, from, n)
  if n > 0 then
    if alien_type[array.type] then
      memset (topointer (array, from), 0, n * array.size)
    else
      for i = from, from + n - 1 do
        array.buffer[i] = 0
      end
    end
  end
  return array
end


--- Clone the elements of an array.
-- @param self object with in progress clone
-- @string type element type
-- @int required number of elements required in clone
-- @treturn alien.array a clone of `self.array`
local function clone (self, type, required)
  local parray, pused = self.array, self.length
  local a = calloc (type, required)

  if alien_type[type] and sizeof (type) == sizeof (parray.type) then
    local bytes   = math.min (required, pused) * parray.size
    memmove (topointer (a), topointer (parray), bytes)
  else
    local a, b = a.buffer, parray.buffer
    for i = 1, math.min (required, pused) do a[i] = b[i] end
  end
  return setzero  (a, pused + 1, required - pused)
end


local _functions = {
  --- Remove the right-most element.
  -- @function pop
  -- @return the right-most element
  pop = function (self)
    argscheck ("pop", {"Array"}, {self})

    local used = self.length
    if used > 0 then
      local a = self.array
      local elem = a[used]
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

    local a, used = self.array, self.length + 1
    self:realloc (used)
    a[used] = elem
    return elem
  end,


  --- Change the number of elements allocated to be at least `n`.
  -- @function realloc
  -- @int n the number of elements required
  -- @treturn Array the array
  realloc = function (self, n)
    argscheck ("realloc", {"Array", "number"}, {self, n})

    local a, used = self.array, self.length
    if n > a.length or n < a.length / 2 then
      a:realloc (n + element_chunk_size)
    end

    -- Zero padding for uninitialised elements.
    setzero (a, used + 1, n - used)

    self.length = n
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

    local a, i = self.array, from + n - 1
    while i >= from do
      a[i] = v
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
      local a = self.array
      local elem
      if alien_type[a.type] then
        elem = a[1]
        memmove (topointer (a, 1), topointer (a, 2), n * a.size)
        self:realloc (n)
      else
        elem = table.remove (a.buffer, 1)
        self.length = n
        a.length = n
      end
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

    local a, n = self.array, self.length
    if alien_type[a.type] then
      self:realloc (n + 1)
      memmove (topointer (a, 2), topointer (a, 1), n * a.size)
      a[1] = elem
    else
      table.insert (a.buffer, 1, elem)
      self.length = n + 1
      a.length = n + 1
    end
    return elem
  end,
}


------
-- An efficient array of homogenous objects.
-- @table Array
-- @int length number of elements currently allocated
-- @tfield alien.array array a block of indexable memory
local Array = Object {
  _type = "Array",


  -- Prototype initial values.
  length = 0,
  array  = calloc ("int", {0}),


  -- Module functions.
  _functions = _functions,


  --- Instantiate a newly cloned Array.
  -- If not specified, `type` will be the same as the prototype array being
  -- cloned; otherwise, it can be any string.  Only valid alien accepted by
  -- `alien.array` will use the fast `alien.array` managed memory buffer for
  -- Array contents; otherwise, a much slower Lua emulation is used.
  -- @function __call

  -- @tparam[opt] int|table init initial size or list of initial elements
  -- @treturn Array a new Array object
  _init = function (self, type, init)
    if init ~= nil then
      -- When called with 2 arguments:
      argcheck ("Array", 1, {"string"}, type)
      argcheck ("Array", 2, {"number", "table"}, init)
    elseif type ~= nil then
      -- When called with 1 argument:
      argcheck ("Array", 1, {"number", "string", "table"}, type)
    end

    -- Non-string argument 1 is really an init argument.
    if typeof (type) ~= "string" then type, init = nil, type end

    -- New array type is copied from prototype if not specified.
    local parray = self.array
    if type == nil then type = parray.type end

    local a
    if init == nil then
      -- 1. A clone of prototype array.
      a = clone (self, type, parray.length)

    elseif typeof (init) == "number" then
      -- 2. Clone a number of elements from the prototype, padding with
      --    zeros if we have more elements than the prototype.
      a = clone (self, type, init)
      self.length = init

    elseif typeof (init) == "table" then
      -- 3. With an initialisation table, ignore prototype elements.
      a = calloc (type, init)
      self.length = #init
    end

    self.array = a
    return self
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
        return self.array[n]
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
      local a, used = self.array, self.length
      if n == 0 or math.abs (n) > used then
	return a[0] -- guaranteed to be out of bounds
      end
      if n < 0 then n = n + used + 1 end
      a[n] = elem
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

    local a = self.array
    local t = {}
    for i = 1, self.length do
      t[#t + 1] = tostring (a[i])
    end
    t = { '"' .. a.type .. '"', "{" .. table.concat (t, ", ") .. "}" }
    return prototype (self) .. " (" .. table.concat (t, ", ") .. ")"
  end,
}

return Array
