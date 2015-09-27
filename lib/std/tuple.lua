--[[--
 Tuple container prototype.

 An interned, immutable, nil-preserving tuple object.

 Like Lua strings, tuples with the same elements can be quickly compared
 with a straight forward `==` comparison.  The `prototype` field in the
 returned module table is the empty tuple, which can be cloned to create
 tuples with other contents.

 In addition to the functionality described here, Tuple containers also
 have all the methods and metamethods of the @{std.container.prototype}
 (except where overridden here),

 The immutability guarantees only work if you don't change the contents
 of tables after adding them to a tuple.  Don't do that!

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Tuple

 @prototype std.tuple
]]


local error		= error
local getmetatable	= getmetatable
local next		= next
local select		= select
local setmetatable	= setmetatable
local type		= type

local string_format	= string.format
local table_concat	= table.concat
local table_unpack	= table.unpack or unpack


local _ = {
  container		= require "std.container",
  setenvtable		= require "std.strict".setenvtable,
  std			= require "std.base",
}

local Container		= _.container.prototype
local Module		= _.std.object.Module

local _type		= _.std.type
local pickle		= _.std.string.pickle
local toqstring		= _.std.base.toqstring


local _, _ENV		= nil, _.setenvtable {}



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


-- Maintain a weak functable of all interned tuples.
-- @function intern
-- @int n number of elements in *t*, including trailing `nil`s
-- @tparam table t table of elements
-- @treturn table interned *n*-tuple *t*
local intern = setmetatable ({}, {
  __mode = "kv",

  __call = function (self, k, t)
    if self[k] == nil then
      self[k] = {[t] = k}
    end
    return self[k]
  end,
})



--[[ ================== ]]--
--[[ Type Declarations. ]]--
--[[ ================== ]]--


--- Tuple prototype object.
-- @object prototype
-- @string[opt="Tuple"] _type object name
-- @int n number of tuple elements
-- @see std.container.prototype
-- @usage
-- local Tuple = require "std.tuple".prototype
-- function count (...)
--   argtuple = Tuple (...)
--   return argtuple.n
-- end
-- count () --> 0
-- count (nil) --> 1
-- count (false) --> 1
-- count (false, nil, true, nil) --> 4
local prototype = Container {
  _type = "std.tuple.Tuple",

  _init = function (obj, ...)
    local n = select ("#", ...)
    local s, t = {}, {n = n, ...}
    for i = 1, n do s[i] = toqstring (t[i]) end
    return intern (table_concat (s, ", "), t)
  end,

  --- Metamethods
  -- @section metamethods

  __index = function (self, k)
    return next (self) [k]
  end,

  --- Return the length of this tuple.
  -- @function prototype:__len
  -- @treturn int number of elements in *tup*
  -- @usage
  -- -- Only works on Lua 5.2 or newer:
  -- #Tuple (nil, 2, nil) --> 3
  -- -- For compatibility with Lua 5.1, use @{std.operator.len}
  -- len (Tuple (nil, 2, nil)
  __len = function (self)
    return self.n
  end,

  --- Prevent mutation of *tup*.
  -- @function prototype:__newindex
  -- @param k tuple key
  -- @param v tuple value
  -- @raise cannot change immutable tuple object
  __newindex = function (self, k, v)
    error ("cannot change immutable tuple object", 2)
  end,

  --- Return a string representation of *tup*
  -- @function prototype:__tostring
  -- @treturn string representation of *tup*
  -- @usage
  -- -- 'Tuple ("nil", nil, false)'
  -- print (Tuple ("nil", nil, false))
  __tostring = function (self)
    local _, argstr = next (self)
    return string_format ("%s (%s)", _type (self), argstr)
  end,

  --- Unpack tuple values between index *i* and *j*, inclusive.
  -- @function prototype:__unpack
  -- @int[opt=1] i first index to unpack
  -- @int[opt=len(t)] j last index to unpack
  -- @return ... values at indices *i* through *j*, inclusive
  -- @usage
  -- t = Tuple (1, 3, 2, 5)
  -- --> 3, 2, 5
  -- table.unpack (t, 2)
  __unpack = function (self, i, j)
    return table_unpack (next (self), i, j)
  end,

  --- Return a loadable serialization of this object, where possible.
  -- @function prototype:__pickle
  -- @treturn string pickled object representataion
  -- @see std.string.pickle
  __pickle = function (self)
    local mt, vals = getmetatable (self), {}
    for i = 1, self.n do
      vals[i] = pickle (self[i])
    end
    if type (mt._module) == "string" then
      return string_format ('require "%s".prototype (%s)',
                      mt._module, table_concat (vals, ","))
    end
    return string_format ("%s (%s)", mt._type, table_concat (vals, ","))
  end,

  -- Prototype is the 0-tuple.
  [intern ("", {n = 0})] = "",
}


return Module {
  prototype = prototype,
}
