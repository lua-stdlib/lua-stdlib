-- Text processing

require "std.text.regex"
require "std.data.table"


-- @func format: Format, but only if more than one argument
--   @param (s: string
--   ( or
--   @param (...: arguments for format
-- returns
--   @param r: formatted string, or s if only one argument
local _format = format
function format (...)
  if getn (arg) == 1 then
    return arg[1]
  else
    return call (%_format, arg)
  end
end

-- strconcat: Give a name to .. for strings
--   s, t: strings
-- returns
--   s_: s .. t
function strconcat (s, t)
  return s .. t
end

-- strcaps: Capitalise each word in a string
-- TODO: rewrite for 5.0 using bracket notation
--   s: string
-- returns
--   s_: capitalised string
function strcaps (s)
  s = gsub (s, "(%w)([%w]*)",
            function (l, ls)
              return strupper (l) .. ls
            end)
  return s
end

-- chomp: Remove any final \n from a string
-- TODO: rewrite for 5.0 using bracket notation
--   s: string to process
-- returns
--   s_: processed string
function chomp (s)
  s = gsub (s, "\n$", "")
  return s
end

-- join: Turn a list of strings into a sep-separated string
--   sep: separator
--   l: list of strings to join
-- returns
--   s: joined up string
function join (sep, l)
  local s = l[1] or ""
  for i = 2, getn (l) do
    s = s .. sep .. l[i]
  end
  return s
end

-- escapePattern: Escape a string to be used as a pattern
-- TODO: rewrite for 5.0 using bracket notation
--   s: string to process
-- returns
--   s_: processed string
function escapePattern (s)
  s = gsub (s, "(%W)", "%%%1")
  return s
end

-- escapeShell: Escape a string to be used as a shell token
-- Quotes spaces, parentheses and \s
-- TODO: rewrite for 5.0 using bracket notation
--   s: string to process
-- returns
--   s_: processed string
function escapeShell (s)
  s = gsub (s, "([ %(%)%\\])", "\\%1")
  return s
end

-- stringifier: table of functions to stringify objects
-- Default method for otherwise unhandled table types
-- TODO: make it output in {v1, v2 ..; x1=y1, x2=y2 ..} format; use
-- nexti; show the n field (if any) on the RHS
--   {[t] = f, ...} where
--     t: tag
--     f: function
--       x: object of tag t
--       [p]: parent object
--     returns
--       s: string representation of t
local _tostring = tostring
stringifier =
  defaultTable (function (x)
                  if tabulator[tag (x)] then
                    x = tabulator[tag (x)] (x)
                  end
                  if type (x) == "table" then
                    local t = {}
                    for i, v in x do
                      t[stringifier[tag (i)] (i)] =
                        stringifier[tag (v)] (v)
                    end
                    return t
                  else
                    return %_tostring (x)
                  end
                end,
                {})

-- tostring: Extend tostring to work better on tables
--   x: object to convert to string
-- returns
--   s: string representation
function tostring (x)
  local rep = stringifier[tag (x)] (x)
  if type (rep) == "table" then
    local s, sep = "{", ""
    for i, v in rep do
      s = s .. sep .. tostring (i) .. "=" .. tostring (v)
      sep = ","
    end
    s = s .. "}"
    return s
  else
    return rep
  end
end

-- ordinalSuffix: return the English suffix for an ordinal
--   n: number of the day
-- returns
--   s: suffix
function ordinalSuffix (n)
  n = imod (n, 100)
  local d = imod (n, 10)
  if d == 1 and n ~= 11 then
    return "st"
  elseif d == 2 and n ~= 12 then
    return "nd"
  elseif d == 3 and n ~= 13 then
    return "rd"
  else
    return "th"
  end
end
