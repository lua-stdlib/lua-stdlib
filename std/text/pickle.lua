-- Pickling

require "std/text/text.lua"


-- @func pickle: convert an object to a string
-- Does not work for functions, userdata or recursive tables
--   @param x: object to pickle
-- returns
--   @param s: string that eval (s) is the same value as x
function pickle (x)
  local s = ""
  local rep = stringifier[tag (x)] (x)
  if type (rep) == "table" then
    s = s .. "{"
    for i, v in rep do
      s = s .. "[" .. pickle (i) .. "]=" .. pickle (v) .. ","
    end
    s = s .. "}"
  elseif type (rep) == "string" then
    s = "\"" .. rep .. "\""
  else
    s = tostring (rep)
  end
  return s
end
