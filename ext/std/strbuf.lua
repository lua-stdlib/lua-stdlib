--[[--
 String buffers.
 @classmod std.strbuf
]]


local Object = require "std.object"


--- Add a string to a buffer.
-- @param b buffer
-- @param s string to add
-- @return buffer
local function concat (b, s)
  table.insert (b, s)
  return b
end


--- Convert a buffer to a string.
-- @param b buffer
-- @return string
local function tostring (b)
  return table.concat (b)
end


return Object {
  -- Derived object type.
  _type = "StrBuf",

  ------
  -- Support concatenation of StrBuf objects.
  --     buffer = buffer .. str
  -- @metamethod __concat
  -- @see concat
  __concat   = concat,


  ------
  -- Support fast conversion to Lua string.
  --     str = tostring (buffer)
  -- @metamethod __tostring
  -- @see tostring
  __tostring = tostring,


  --- @export
  __index = {
    concat   = concat,
    tostring = tostring,
  },
}
