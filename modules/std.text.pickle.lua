-- Pickling

require "std.data.table"
require "std.text.text"


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
    if tabulator[tag (x)] then
      x = tabulator[tag (x)] (x)
    end
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
