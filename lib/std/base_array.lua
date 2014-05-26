------
-- @module std.base_array


local base = require "std.base"
local argcheck, argscheck = base.argcheck, base.argscheck

local Object = require "std.object"
local prototype = Object.prototype

local typeof = type


local _functions = {
  --- Remove the right-most element.
  -- @function pop
  -- @return the right-most element
  pop = function (self)
    argcheck ("pop", 1, "Array", self)

    self.length = math.max (self.length - 1, 0)
    return table.remove (self.buffer)
  end,


  --- Add elem as the new right-most element.
  -- @function push
  -- @param elem new element to be pushed
  -- @return elem
  push = function (self, elem)
    argscheck ("push", {"Array", "any"}, {self, elem})

    local length = self.length + 1
    self.buffer[length] = elem
    self.length = length
    return elem
  end,


  --- Change the number of elements allocated to be at least `n`.
  -- @function realloc
  -- @int n the number of elements required
  -- @treturn Array the array
  realloc = function (self, n)
    argscheck ("realloc", {"Array", "number"}, {self, n})

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
  -- @treturn Array the array
  set = function (self, from, v, n)
    argscheck ("set", {"Array", "number", "any", "number"},
               {self, from, v, n})

    local length = self.length
    if from < 0 then from = from + length + 1 end
    assert (from > 0 and from <= length)

    for i = from, from + n - 1 do
      self[i] = v
    end

    return self
  end,


  --- Shift the whole array to the left by removing the left-most element.
  -- This makes the array 1 element shorter than it was before the shift.
  -- @function shift
  -- @return the removed element.
  shift = function (self)
    argcheck ("shift", 1, "Array", self)

    self.length = math.max (self.length - 1, 0)
    return table.remove (self.buffer, 1)
  end,


  --- Shift the whole array to the right by inserting a new left-most element.
  -- @function unshift
  -- @param elem new element to be pushed
  -- @treturn elem
  unshift = function (self, elem)
    argscheck ("unshift", {"Array", "any"}, {self, elem})

    self.length = self.length + 1
    table.insert (self.buffer, 1, elem)
    return elem
  end,
}


------
-- A container for contiguous objects.
-- @table Array
-- @tfield table buffer contained objects
-- @int length number of elements
local Array = Object {
  _type = "Array",


  -- Prototype initial values.
  buffer    = {},
  length    = 0,


  -- Module functions.
  _functions = _functions,


  --- Instantiate a newly cloned Array.
  -- @function __call
  -- @string[opt] type element type name
  -- @tparam[opt] int|table init initial size or list of initial elements
  -- @treturn Array a new Array object
  _init = function (self, type, init)
    if init ~= nil then
      -- When called with 2 arguments:
      argcheck ("Array", 1, "string", type)
      argcheck ("Array", 2, {"number", "table"}, init)
    elseif type ~= nil then
      argcheck ("Array", 1, {"number", "string", "table"}, type)
    end

    -- Non-string argument 1 is reall an init argument.
    if typeof (type) ~= "string" then type, init = nil, type end

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
    self.buffer = b
    self.length = #b
    return self
  end,


  --- Return the number of elements in this Array.
  -- @function __len
  -- @treturn int number of elements
  __len = function (self)
    argcheck ("__len", 1, "Array", self)
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
        return self.buffer[n]
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
    argscheck ("__newindex", {"Array", "number", "any"}, {self, n, elem})

    if typeof (n) == "number" then
      local used = self.length
      if n == 0 or math.abs (n) > used then
	error ("array access " .. n .. " out of bounds: 0 < abs (n) <= " ..
               tostring (self.length), 2)
      end
      if n < 0 then n = n + used + 1 end
      self.buffer[n] = elem
    else
      rawset (self, n, elem)
    end
    return self
  end,


  --- Return a string representation of the contents of this Array.
  -- @function __tostring
  -- @treturn string string representation
  __tostring = function (self)
    argcheck ("__tostring", 1, "Array", self)

    local t = {}
    for i = 1, self.length do
      t[#t + 1] = tostring (self[i])
    end
    return prototype (self) .. " {" .. table.concat (t, ", ") .. "}"
  end,
}

return Array
