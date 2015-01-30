--[[--
 String buffers.

 Buffers are mutable by default, but being based on objects, they can
 also be used in a functional style:

    local StrBuf = require "std.strbuf" {}
    local a = StrBuf {"a"}
    local b = a:concat "b"    -- mutate *a*
    print (a, b)              --> ab   ab
    local c = a {} .. "c"     -- copy and append
    print (a, c)              --> ab   abc

 Prototype Chain
 ---------------

      table
       `-> Object
            `-> StrBuf

 @classmod std.strbuf
]]

local base   = require "std.base"
local debug  = require "std.debug"

local Object = require "std.object" {}

local ielems, insert, prototype = base.ielems, base.insert, base.prototype

local M, StrBuf


local function __concat (self, x)
  return insert (self, x)
end


local function __tostring (self)
  local strs = {}
  for e in ielems (self) do strs[#strs + 1] = tostring (e) end
  return table.concat (strs)
end


--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


local function X (decl, fn)
  return debug.argscheck ("std.strbuf." .. decl, fn)
end


M = {
  --- Add a object to a buffer.
  -- Elements are stringified lazily, so if add a table and then change
  -- its contents, the contents of the buffer will be affected too.
  -- @static
  -- @function concat
  -- @param x object to add to buffer
  -- @treturn StrBuf modified buffer
  -- @usage
  -- buf = buf:concat "append this" {" and", " this"}
  concat = X ("concat (StrBuf, any)", __concat),
}



--[[ ============= ]]--
--[[ Deprecations. ]]--
--[[ ============= ]]--


local DEPRECATED = debug.DEPRECATED

M.tostring = DEPRECATED ("41.1", "std.strbuf.tostring",
                         "use 'tostring (strbuf)' instead",
	                 X ("tostring (StrBuf)", __tostring))


--[[ ================== ]]--
--[[ Type Declarations. ]]--
--[[ ================== ]]--


--- StrBuf prototype object.
--
-- Set also inherits all the fields and methods from
-- @{std.object.Object}.
-- @object StrBuf
-- @string[opt="StrBuf"] _type object name
-- @see std.object.__call
-- @usage
-- local std = require "std"
-- local StrBuf = std.strbuf {}
-- local a = {1, 2, 3}
-- local b = {a, "five", "six"}
-- a = a .. 4
-- b = b:concat "seven"
-- print (a, b) --> 1234   1234fivesixseven
-- os.exit (0)
StrBuf = Object {
  _type = "StrBuf",

  __index = M,

  --- Support concatenation to StrBuf objects.
  -- @function __concat
  -- @tparam StrBuf buffer object
  -- @param x a string, or object that can be coerced to a string
  -- @treturn StrBuf modified *buf*
  -- @see concat
  -- @usage
  -- buf = buf .. x
  __concat = __concat,

  --- Support fast conversion to Lua string.
  -- @function __tostring
  -- @tparam StrBuf buffer object
  -- @treturn string concatenation of buffer contents
  -- @see tostring
  -- @usage
  -- str = tostring (buf)
  __tostring = __tostring,
}


return StrBuf
