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

local Container = require "std.container".prototype
local std       = require "std.base"

local stdtype = std.type
local toqstring = std.base.toqstring


--- Stringify tuple values, as a memoization key.
-- @tparam prototype tuple tuple to process
-- @treturn string a comma separated ordered list of stringified *tup* elements
local function argstr (tuple)
  local s = {}
  for i = 1, tuple.n do
    local v = tuple[i]
    s[i] = toqstring (v)
  end
  return table.concat (s, ", ")
end


-- Maintain a weak functable of all interned tuples.
-- @function intern
-- @param ... tuple elements
-- @treturn table an interned proxied table with ... elements
local intern = setmetatable ({}, {
  __mode = "kv",

  __call = function (self, ...)
    local t = {n = select ("#", ...), ...}
    local k = argstr (t)
    if self[k] == nil then
      -- Use a proxy table so that __newindex always fires
      self[k] = setmetatable ({}, { __contents = t, __index = t })
    end
    return self[k]
  end,
})



--[[ ============= ]]--
--[[ Tuple Object. ]]--
--[[ ============= ]]--


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
  _type = "Tuple",

  _init = function (obj, ...)
    return intern (...)
  end,

  --- Metamethods
  -- @section metamethods

  -- The actual contents of *tup*.
  -- This ensures __newindex will trigger for existing elements too.
  -- It also informs @{std.table.unpack} that that the elements to unpack are
  -- not in the usual place.
  __contents = getmetatable (intern ()).__contents,


  -- Another reference to the proxy table, so that [] operations work as
  -- expected.
  __index = getmetatable (intern ()).__index,

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
    return ("%s (%s)"):format (stdtype (self), argstr (self))
  end,
}


return std.object.Module {
  prototype = prototype,
}
