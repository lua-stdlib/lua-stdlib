-- Base

require "std.data.table"
require "std.io.io"
require "std.string.string"


-- @func metamethod: Return given metamethod, if any, or nil
--   @param x: object to get metamethod of
--   @param n: name of metamethod to get
-- returns
--   @param m: metamethod function or nil if no metamethod or not a
--   function
function metamethod (x, n)
  local _, m = pcall (function (x)
                        return getmetatable (x)[n]
                      end,
                      x)
  if type (m) ~= "function" then
    m = nil
  end
  return m
end

-- print: Make print use tostring, so that improvements to tostring
-- are picked up
--   @param arg: objects to print
local _print = print
function print (...)
  for i = 1, table.getn (arg) do
    arg[i] = tostring (arg[i])
  end
  _print (unpack (arg))
end

-- @func tostring: Extend tostring to work better on tables
--   @param x: object to convert to string
-- returns
--   @param s: string representation
local _tostring = tostring
function tostring (x)
  if type (x) == "table" and (not metamethod (x, "__tostring")) then
    local s, sep = "{", ""
    for i, v in x do
      s = s .. sep .. tostring (i) .. "=" .. tostring (v)
      sep = ","
    end
    s = s .. "}"
    return s
  else
    return _tostring (x)
  end
end

-- @func totable: Turn an object into a table according to __totable
-- metamethod
--   @param x: object to turn into a table
-- returns
--   @param t: table or nil
function totable (x)
  local m = metamethod (x, "__totable")
  if m then
    return m (x)
  elseif type (x) == "table" then
    return x
  else
    return nil
  end
end

-- @func pickle: Convert a value to a string
-- The string can be passed to dostring to retrieve the value
-- Does not work for recursive tables
--   @param x: object to pickle
-- returns
--   @param s: string such that eval (s) is the same value as x
function pickle (x)
  if type (x) == "nil" then
    return "nil"
  elseif type (x) == "number" then
    return tostring (x)
  elseif type (x) == "string" then
    return format ("%q", x)
  else
    x = totable (x) or x
    if type (x) == "table" then
      local s, sep = "{", ""
      for i, v in x do
        s = s .. sep .. "[" .. pickle (i) .. "]=" .. pickle (v)
        sep = ","
      end
      s = s .. "}"
      return s
    else
      die ("can't pickle " .. tostring (x))
    end
  end
end

-- @func assert: Extend to allow formatted arguments
--   @param v: value
--   @param ...: arguments for format
-- returns
--   @param v: value
function assert (v, ...)
  if not v then
    error (string.format (unpack (arg or {""})))
  end
  return v
end

-- @func warn: Give warning with the name of program and file (if any)
--   @param ...: arguments for format
function warn (...)
  if prog.name then
    io.stderr:write (prog.name .. ":")
  end
  if prog.file then
    io.stderr:write (prog.file .. ":")
  end
  if prog.line then
    io.stderr:write (tostring (prog.line) .. ":")
  end
  if prog.name or prog.file or prog.line then
    io.stderr:write (" ")
  end
  io.writeLine (io.stderr, string.format (unpack (arg)))
end

-- @func die: Die with error
--   @param ...: arguments for format
function die (...)
  warn (unpack (arg))
  error (false)
end
