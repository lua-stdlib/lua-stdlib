-- Pickling

require "std.text.text"


-- pickler: table of functions to pickle objects
-- Default method for otherwise unhandled table types
--   {[t] = f, ...} where
--     t: tag
--     f: function
--       self: stringifier table
--       x: object of tag t
--     returns
--       s: pickle of t
pickler =
  defaultTable (function (self, x)
                  local s
                  if type (x) == "table" then
                    s = "{"
                    for i, v in x do
                      s = s .. "[" .. pickler[tag (i)] (self, i) ..
                        "]=" .. pickler[tag (v)] (self, v) .. ","
                    end
                    s = s .. "}"
                  else
                    s = format ("%q", tostring (rep))
                  end
                  return s
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
  return pickler[tag (x)] (pickler, x)
end
