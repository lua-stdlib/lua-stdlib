--[[--
 Tuple container prototype.

 An interned immutable nil-preserving tuple object.

 Like Lua strings, tuples with the same elements can be quickly compared with
 a straight forward `==` comparison.

 The immutability guarantees only work if you don't change the contents of
 tables after adding them to a tuple.  Don't do that!

 Prototype Chain
 ---------------

      table
       `-> Object
            `-> Container
                 `-> Tuple

 @classmod std.tuple
 @see std.container
]]

local Container = require "std.container" {}
local stdtype = require "std.base".type


-- Stringify tuple values, as a memoization key.
-- @tparam Tuple tup tuple to process
-- @treturn string a comma separated ordered list of stringified *tup* elements
local function argstr (tuple)
  local s = {}
  for i = 1, tuple.n do
    local v = tuple[i]
    s[i] = (type (v) ~= "string" and "%s" or "%q"):format (tostring (v))
  end
  return table.concat (s, ", ")
end


-- Maintain a weak functable of all interned tuples.
-- @static
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
--
-- Set also inherits all the fields from @{std.container.Container}
-- @object Tuple
-- @string[opt="Tuple"] _type object name
-- @int n number of tuple elements
-- @see std.container
-- @usage
-- local Tuple = require "std.tuple"
-- function count (...)
--   argtuple = Tuple (...)
--   return argtuple.n
-- end
-- count () --> 0
-- count (nil) --> 1
-- count (false) --> 1
-- count (false, nil, true, nil) --> 4
return  Container {
  _type = "Tuple",

  _init = function (obj, ...)
    return intern (...)
  end,

  -- The actual contents of *tup*.
  -- This ensures __newindex will trigger for existing elements too.
  -- It also informs `table.unpack` that that the elements to unpack are
  -- not in the usual place.
  __contents = getmetatable (intern ()).__contents,


  -- Another reference to the proxy table, so that [] operations work as
  -- expected.
  __index = getmetatable (intern ()).__index,

  --- Return the length of this tuple.
  -- @static
  -- @function __len
  -- @tparam Tuple tup object to process
  -- @treturn int number of elements in *tup*
  -- @usage
  -- -- Only works on Lua 5.2 or newer:
  -- #Tuple (nil, 2, nil) --> 3
  -- -- For compatibility with Lua 5.1, use @{std.len}
  -- len (Tuple (nil, 2, nil)
  __len = function (self)
    return self.n
  end,

  --- Prevent mutation of *tup*.
  -- This metamethod never returns, because Tuples are immutable.
  -- @static
  -- @function __newindex
  -- @tparam Tuple tup object to process
  -- @param k tuple key
  -- @param v tuple value
  __newindex = function (self, k, v)
    error ("cannot change immutable tuple object", 2)
  end,

  --- Return a string representation of *tup*
  -- @static
  -- @function __tostring
  -- @tparam Tuple tup object to process
  -- @treturn string representation of *tup*
  -- @usage
  -- -- 'Tuple ("nil", nil, false)'
  -- print (Tuple ("nil", nil, false))
  __tostring = function (self)
    return ("%s (%s)"):format (stdtype (self), argstr (self))
  end,
}
