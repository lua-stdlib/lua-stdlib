--[[--
 A pure Lua implementation of bits of the alien API stdlib relies on.

# Internal API

 This is very far from a full implementation, and serves barely sufficient
 functionality to enable use of `std.array` objects that won't work with
 the real alien module - either because it is not available, or because the
 contiguous memory model of alien arrays won't work for complex types that
 are supported by std.array.

 The documentation is here for completeness and to aid understanding, but
 you almost certainly won't find a good use for this module.

 @module std.alien
]]

local debug = require "std.debug"
local argscheck = debug.argscheck

local typeof = type


------
-- A pointer into a std.alien.buffer object.
-- This helps std.object.prototype recognise the fake pointers generated
-- by std.alien.array.buffer:topointer ().
-- @table std.alien.pointer
-- @tfield std.alien.buffer buffer std.alien.array objects contain one
-- @int index index into `buffer`
-- @see std.alien.buffer:topointer

local pointer_mt = {
  _type = "std.alien.pointer",
}


local buffer_methods = {
  --- Return a table containing the index and a buffer reference.
  -- @function std.alien.buffer:topointer
  -- @int index reference to an element from buffer
  -- @see std.alien.pointer
  topointer = function (self, index)
    return setmetatable ({ buffer = self, index = index }, pointer_mt)
  end,
}


local buffer_mt = {
  _type = "std.alien.array.buffer",
  __index = buffer_methods,
}


local array_methods = {
  --- Change the number of elements available in an array.
  -- @function std.alien.array:realloc
  -- @int count the minimum number of elements to make available
  -- @see std.alien.array
  realloc = function (self, count)
    self.length = count
  end,
}

local array_mt = {
  _type = "std.alien.array",

  --- Fetch the `index`th element, or fallback to a method name.
  -- If `index` is a number, and it is not between 1 and the length
  -- of this array, throw an "array access out of bounds" error.
  -- @function array.__index
  -- @tparam std.alien.array self an object from std.alien.array ()
  -- @int index element index
  -- @return the `index`th element of `self`
  -- @local
  __index = function (self, index)
    if typeof (index) == "number" then
      if index < 1 or index > self.length then
        error "array access out of bounds"
      end
      return rawget (self.buffer, index)
    end
    return array_methods[index]
  end,

  --- Fetch the number of elements available in this array.
  -- Note that this metamethod is ignored in Lua<5.2.  For compatibility
  -- with earlier releases, use array.length instead of #array.
  -- @function array.__len
  -- @tparam std.alien.array self an object fro std.alien.array ()
  -- @treturn int the number of avaliable element slots
  -- @local
  __len = function (self)
    return self.length
  end,

  --- Set the `index`th element to `value`.
  -- If `index` is a number, and it is not between 1 and the length
  -- of this array, throw an "array access out of bounds" error.
  -- @tparam std.alien.array self an object from std.alien.array ()
  -- @int index element index
  -- @int value set the `index`th element to this
  -- @return the `index`th element of `self`
  -- @local
  __newindex = function (self, index, value)
    if typeof (index) == "number" then
      if index < 1 or index > self.length then
        error "array access out of bounds"
      end
      rawset (self.buffer, index, value)
    else
      rawset (self, index, value)
    end
    return self
  end,
}


--- Return a new std.alien.array object.
-- @string type for API compatibility with alien proper
-- @tparam int|table init number of elements to allocate, or a table of values
-- @treturn std.alien.array a new std.alien.array object
-- @see std.alien.array
local function array (type, init)
  argscheck ('array', {"string", {"number", "table"}}, {type, init})

  local array = {
    type = type,
    buffer = {},
    size = 1,
    length = init,
  }

  if typeof (init) == "table" then
    array.buffer = init
    array.length = #init
  end
  array.buffer = setmetatable (array.buffer, buffer_mt)

  return setmetatable (array, array_mt)
end


--- Move a block of contiguous elements to a new position.
-- Works with overlapping blocks, or between entirely different arrays.
-- @tparam std.alien.pointer to destination for elements to copy
-- @tparam std.alien.pointer from source of elements to be copied
-- @int bytes number of elements to copy (this only works because we ensure
--   std.alien.array.size is always 1)
-- @see std.alien.buffer:topointer
local function memmove (to, from, bytes)
  argscheck ("memmove", {"std.alien.pointer", "std.alien.pointer", "number"},
             {to, from, bytes})

  local tobuf, frombuf = to.buffer, from.buffer
  local to, from = to.index, from.index
  if tobuf == frombuf and to > from then
    for i = bytes - 1, 0, -1 do
      tobuf[to + i] = frombuf[from + i]
    end
  else
    for i = 0, bytes - 1 do
      tobuf[to + i] = frombuf[from + i]
    end
  end
end


--- Set a new value for a contiguos block of elements.
-- There's no concept of bytes or object size in `std.alien.array`s, so
-- in practice, the use of this function is limited to zeroing out new
-- elements.
-- @tparam std.alien.pointer pointer an object returned by `topointer`
-- @param value the new value to set elements to
-- @int bytes numebr of elements to set (this only works because we ensure
--   std.alien.array.size is always 1)
-- @see std.alien.buffer:topointer
local function memset (pointer, value, bytes)
  argscheck ("memset", {"std.alien.pointer", "any", "number"},
             {pointer, value, bytes})

  local buffer, from, to = pointer.buffer, pointer.index, pointer.index + bytes -1
  for i = from, to do
    buffer[i] = value
  end
end


--- @export
return {
  array   = array,
  memmove = memmove,
  memset  = memset,
}

-- If we put these near the code they document, LDoc crashes! :-/

------
-- An array of homogenous elements.
-- Instantiate one of these by calling `array`.
-- @table std.alien.array
-- @string type nominal name of types of elements stored in this array
-- @tparam std.alien.buffer buffer the elements of this array
-- @int size the size of a single element, always 1 in this implementation
-- @int length the number of elements in this array
-- @see std.alien.buffer
-- @see array
-- @see std.alien.array:realloc


------
-- The element buffer of a `std.alien.array`.
-- In this implementation, a buffer is just the array part of a Lua table.
-- @table std.alien.buffer
-- @see std.alien.array
-- @see memmove
-- @see memset
