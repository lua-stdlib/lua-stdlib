-- Pickling

require "std.text.text"


-- @func pickle: Convert an value to a string
-- The string can be passed to dostring to retrieve the value
-- Does not work for recursive tables
--   @param x: object to pickle
-- returns
--   @param s: string that eval (s) is the same value as x
function pickle (x)
  local ty = type (x)
  local s
  if ty == "nil" then
    s = "nil"
  elseif ty == "number" then
    s = tostring (x)
  else
    local rep = stringifier[tag (x)] (x)
    if type (rep) == "table" then
      s = s .. "{"
      for i, v in rep do
        s = s .. "[" .. pickle (i) .. "]=" .. pickle (v) .. ","
      end
      s = s .. "}"
    else
      s = format ("%q", rep)
    end
  end
  return s
end
