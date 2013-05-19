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

-- Public interface
local M = {
  concat   = concat,
  tostring = tostring,
}

--- Create a new string buffer
-- @return strbuf
local function new (...)
  return Object {
    -- Derived object type.
    _type = "strbuf",

    -- Metamethods.
    __concat   = concat,   -- buffer .. string
    __tostring = tostring, -- tostring (buffer)

    -- strbuf:method ()
    __index = M,

    -- Initialise.
    ...
  }
end

-- Inject `new` method into public interface.
M.new = new

return setmetatable (M, {
  -- Sugar to call new automatically from module table.
  __call = function (self, t)
    return new (unpack (t))
  end,
})
