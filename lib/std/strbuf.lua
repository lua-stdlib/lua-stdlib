--[[--
 String buffers.

 Prototype Chain
 ---------------

      table
       `-> Object
            `-> StrBuf

 @classmod std.strbuf
]]

local base   = require "std.base"

local Object = require "std.object" {}

local insert = base.insert


--- Add a string to a buffer.
-- @static
-- @function concat
-- @string s string to add
-- @treturn StrBuf modified buffer
-- @usage
-- buf = concat (buf, "append this")
local function concat (self, s)
  return insert (self, s)
end


--- Convert a buffer to a string.
-- @static
-- @function tostring
-- @treturn string stringified `buf`
-- @usage
-- string = buf:tostring ()
local function tostring (buf)
  return table.concat (buf)
end


--- StrBuf prototype object.
--
-- Set also inherits all the fields and methods from
-- @{std.object.Object}.
-- @object StrBuf
-- @string[opt="StrBuf"] _type object name
-- @see std.container
-- @see std.object.__call
-- @usage
-- local std = require "std"
-- std.prototype (std.strbuf) --> "StrBuf"
-- os.exit (0)
return Object {
  -- Derived object type.
  _type = "StrBuf",

  --- Support concatenation to StrBuf objects.
  -- @function __concat
  -- @tparam StrBuf buffer object
  -- @string s a string
  -- @treturn StrBuf modified *buf*
  -- @see concat
  -- @usage
  -- buf = buf .. str
  __concat   = concat,


  --- Support fast conversion to Lua string.
  -- @function __tostring
  -- @tparam StrBuf buffer object
  -- @treturn string concatenation of buffer contents
  -- @see tostring
  -- @usage
  -- str = tostring (buf)
  __tostring = tostring,


  --- @export
  __index = {
    concat   = concat,
    tostring = tostring,
  },
}
