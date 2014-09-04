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


local function X (decl, fn)
  return require "std.debug".argscheck ("std.strbuf." .. decl, fn)
end


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
-- local buf = StrBuf {"initial buffer contents"}
-- buf = buf .. "append to buffer"
-- print (buf) -- implicit `tostring` concatenates everything
-- os.exit (0)
return Object {
  _type = "StrBuf",

  --- Support concatenation to StrBuf objects.
  -- @function __concat
  -- @tparam StrBuf buffer object
  -- @string s a string
  -- @treturn StrBuf modified *buf*
  -- @see concat
  -- @usage
  -- buf = buf .. str
  __concat = X ("__concat (StrBuf, string)", base.insert),

  --- Support fast conversion to Lua string.
  -- @function __tostring
  -- @tparam StrBuf buffer object
  -- @treturn string concatenation of buffer contents
  -- @see tostring
  -- @usage
  -- str = tostring (buf)
  __tostring = X ("__tostring (StrBuf)", table.concat),


  __index = {
    --- Add a string to a buffer.
    -- @static
    -- @function concat
    -- @string s string to add
    -- @treturn StrBuf modified buffer
    -- @usage
    -- buf = concat (buf, "append this")
    concat = X ("concat (StrBuf, string)", base.insert),

    --- Convert a buffer to a string.
    -- @static
    -- @function tostring
    -- @treturn string stringified `buf`
    -- @usage
    -- string = buf:tostring ()
    tostring = X ("tostring (StrBuf)", table.concat),
  },
}
