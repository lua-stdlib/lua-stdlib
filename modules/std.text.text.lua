-- Text

require "std.text.regex"
require "std.data.table"
require "std.io.io"


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

-- @func strconcat: Give a name to .. for strings
--   @param s, t: strings
-- returns
--   @param s_: s .. t
function strconcat (s, t)
  return s .. t
end

-- @func strcaps: Capitalise each word in a string
-- TODO: rewrite for 5.0 using bracket notation
--   @param s: string
-- returns
--   @param s_: capitalised string
function strcaps (s)
  s = gsub (s, "(%w)([%w]*)",
            function (l, ls)
              return strupper (l) .. ls
            end)
  return s
end

-- @func chomp: Remove any final line ending from a string
-- TODO: rewrite for 5.0 using bracket notation
--   @param s: string to process
-- returns
--   @param s_: processed string
function chomp (s)
  s = gsub (s, endOfLine .. "$", "")
  return s
end

-- @func join: Turn a list of strings into a sep-separated string
--   @param sep: separator
--   @param l: list of strings to join
-- returns
--   @param s: joined up string
function join (sep, l)
  local s = l[1] or ""
  for i = 2, getn (l) do
    s = s .. sep .. l[i]
  end
  return s
end

-- @func escapePattern: Escape a string to be used as a pattern
-- TODO: rewrite for 5.0 using bracket notation
--   @param s: string to process
-- returns
--   @param s_: processed string
function escapePattern (s)
  s = gsub (s, "(%W)", "%%%1")
  return s
end

-- @param escapeShell: Escape a string to be used as a shell token
-- Quotes spaces, parentheses and \s
-- TODO: rewrite for 5.0 using bracket notation
--   @param s: string to process
-- returns
--   @param s_: processed string
function escapeShell (s)
  s = gsub (s, "([ %(%)%\\])", "\\%1")
  return s
end

-- @func stringifier: Table of tostring methods
-- Table entries are tag = function from object to string
stringifier = {}

-- @func tostring: Extend tostring to work better on tables
--   @param x: object to convert to string
-- returns
--   @param s: string representation
local _tostring = tostring
function tostring (x)
  local tTag = tag (x)
  if stringifier[tTag] then
    x = stringifier[tTag] (x)
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
    return %_tostring (x)
  end
end

-- @func ordinalSuffix: return the English suffix for an ordinal
--   @param n: number of the day
-- returns
--   @param s: suffix
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
