--- String buffers.

local Object = require "std.object"


--- Add a string to a buffer
-- @param b buffer
-- @param s string to add
-- @return buffer
local function concat (b, s)
  table.insert (b, s)
  return b
end


--- Convert a buffer to a string
-- @param b buffer
-- @return string
local function tostring (b)
  return table.concat (b)
end


return Object {
  -- Derived object type.
  _type = "StrBuf",

  -- Metamethods.
  __concat   = concat,   -- buffer .. string
  __tostring = tostring, -- tostring (buffer)

  -- strbuf:method ()
  __index = {
    concat   = concat,
    tostring = tostring,
  },
}
