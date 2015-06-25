--[[--
 String buffer prototype.

 Buffers are mutable by default, but being based on objects, they can
 also be used in a functional style:

    local StrBuf = require "std.strbuf".prototype
    local a = StrBuf {"a"}
    local b = a:concat "b"    -- mutate *a*
    print (a, b)              --> ab   ab
    local c = a {} .. "c"     -- copy and append
    print (a, c)              --> ab   abc

 In addition to the functionality described here, StrBuf objects also
 have all the methods and metamethods of the @{std.object.prototype}
 (except where overridden here),

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Object
                 `-> StrBuf

 @prototype std.strbuf
]]

local std    = require "std.base"
local debug  = require "std.debug"

local Object = require "std.object".prototype

local ielems, insert = std.ielems, std.table.insert


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

--- StrBuf prototype object.
-- @object prototype
-- @string[opt="StrBuf"] _type object name
-- @see std.object.prototype
-- @usage
-- local StrBuf = require "std.strbuf".prototype
-- local a = StrBuf {1, 2, 3}
-- local b = StrBuf {a, "five", "six"}
-- a = a .. 4
-- b = b:concat "seven"
-- print (a, b) --> 1234   1234fivesixseven
-- os.exit (0)

local M = {
  --- Methods
  -- @section methods

  --- Add a object to a buffer.
  -- Elements are stringified lazily, so if you add a table and then
  -- change its contents, the contents of the buffer will be affected
  -- too.
  -- @function prototype:concat
  -- @param x object to add to buffer
  -- @treturn prototype modified buffer
  -- @usage
  -- c = StrBuf {} :concat "append this" :concat (StrBuf {" and", " this"})
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


local prototype = Object {
  _type = "StrBuf",

  --- Metamethods
  -- @section metamethods

  __index = M,

  --- Support concatenation to StrBuf objects.
  -- @function prototype:__concat
  -- @param x a string, or object that can be coerced to a string
  -- @treturn prototype modified *buf*
  -- @see concat
  -- @usage
  -- buf = buf .. x
  __concat = __concat,

  --- Support fast conversion to Lua string.
  -- @function prototype:__tostring
  -- @treturn string concatenation of buffer contents
  -- @see tostring
  -- @usage
  -- str = tostring (buf)
  __tostring = __tostring,
}


return std.object.Module {
  prototype = prototype,
}
