-- Pickling

require "std.text.text"


-- pickler: table of functions to pickle objects
-- Default method for otherwise unhandled table types
--   {[t] = f, ...} where
--     t: tag
--     f: function
--       self: stringifier table
--       x: object of tag t
--       [p]: parent object
--     returns
--       s: pickle of t
pickler =
  defaultTable (function (self, x)
                  if type (x) == "table" then
                    local t = {}
                    for i, v in x do
                      t[self[tag (i)] (self, i)] =
                        self[tag (v)] (self, v)
                    end
                    return t
                  else
                    return tostring (x)
                  end
                end,
                {
                  [tag (nil)] = function (self, x)
                                  return "nil"
                                end,
                  [tag (0)]   = function (self, x)
                                  return tostring (x)
                                end,
                  [tag ("")]  = function (self, x)
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
  local rep = pickler[tag (x)] (pickler, x)
  if type (rep) == "table" then
    local s = "{"
    for i, v in rep do
      s = s .. "[" .. pickle (i) .. "]=" .. pickle (v) .. ","
    end
    s = s .. "}"
    return s
  else
    return format ("%q", tostring (rep))
  end
end
