-- Base

require "std.data.table"


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
