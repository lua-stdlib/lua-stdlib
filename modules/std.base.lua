-- Base

require "std.data.table"


-- print: Extend print to work better on tables
--   @param arg: objects to print
local _print = print
function print (...)
  for i = 1, table.getn (arg) do
    arg[i] = tostring (arg[i])
  end
  _print (unpack (arg))
end

-- @func stringifier: Table of tostring methods
-- Table entries are metatable = function from object to string
stringifier = {}

-- @func tostring: Extend tostring to work better on tables
--   @param x: object to convert to string
-- returns
--   @param s: string representation
local _tostring = tostring
function tostring (x)
  local meta = getmetatable (x)
  if stringifier[meta] then
    x = stringifier[meta] (x)
  else
    x = tabulate (x) or x
  end
  if type (x) == "table" then
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

-- @func pickle: Convert a value to a string
-- The string can be passed to dostring to retrieve the value
-- Does not work for recursive tables
--   @param x: object to pickle
-- returns
--   @param s: string that eval (s) is the same value as x
function pickle (x)
  if type (x) == "nil" then
    return "nil"
  elseif type (x) == "number" then
    return tostring (x)
  elseif type (x) == "string" then
    return format ("%q", x)
  else
    x = tabulate (x) or x
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
