-- Pickling

require "std.data.table"
require "std.text.text"


-- @func pickler: table of functions to pickle objects
-- Default method for otherwise unhandled table types
--   {[t] = f, ...} where
--     @param t: tag
--     @param f: function
--       @param x: object of tag t
--       @param [p]: parent object
--     returns
--       @param s: pickle of t
pickler =
  defaultTable (function (x)
                  if tabulator[tag (x)] then
                    x = tabulator[tag (x)] (x)
                  end
                  if type (x) == "table" then
                    local t = {}
                    for i, v in x do
                      t[pickler[tag (i)] (i)] = pickler[tag (v)] (v)
                    end
                    return t
                  else
                    return x
                  end
                end,
                {
                  [tag (nil)] = function (x)
                                  return "nil"
                                end,
                  [tag (0)]   = function (x)
                                  return tostring (x)
                                end,
                  [tag ("")]  = function (x)
                                  return format ("%q", x)
                                end,
                })

-- @func pickle: Convert an value to a string
-- The string can be passed to dostring to retrieve the value
-- Does not work for recursive tables
--   @param x: object to pickle
-- returns
--   @param s: string that eval (s) is the same value as x
function pickle (x)
  local rep = pickler[tag (x)] (x)
  if type (rep) == "table" then
    local s = "{"
    for i, v in rep do
      s = s .. "[" .. tostring (i) .. "]=" .. tostring (v) .. ","
    end
    s = s .. "}"
    return s
  else
    return format ("%q", tostring (rep))
  end
end
