--- String buffers

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


--- Metamethods for string buffers
local metatable = {
  __concat   = concat,   -- buffer .. string
  __tostring = tostring, -- tostring
}

--- Create a new string buffer
-- @return strbuf
local function new ()
  return setmetatable ({}, metatable)
end

-- Public interface
local M = {
  concat   = concat,
  new      = new,
  tostring = tostring,
}

-- buffer:method ()
metatable.__index = M

return M
