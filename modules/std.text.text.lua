-- Text

require "std.text.regex"
require "std.data.table"
require "std.io.io"


-- @func strconcat: Give a name to .. for strings
--   @param s, t: strings
-- returns
--   @param s_: s .. t
function strconcat (s, t)
  return s .. t
end

-- @func strcaps: Capitalise each word in a string
--   @param s: string
-- returns
--   @param s_: capitalised string
function strcaps (s)
  return (string.gsub (s, "(%w)([%w]*)",
                       function (l, ls)
                         return strupper (l) .. ls
                       end))
end

-- @func chomp: Remove any final line ending from a string
--   @param s: string to process
-- returns
--   @param s_: processed string
function chomp (s)
  return (string.gsub (s, endOfLine .. "$", ""))
end

-- @func join: Turn a list of strings into a sep-separated string
--   @param sep: separator
--   @param l: list of strings to join
-- returns
--   @param s: joined up string
function join (sep, l)
  local s = l[1] or ""
  for i = 2, table.getn (l) do
    s = s .. sep .. l[i]
  end
  return s
end

-- @func escapePattern: Escape a string to be used as a pattern
--   @param s: string to process
-- returns
--   @param s_: processed string
function escapePattern (s)
  return (string.gsub (s, "(%W)", "%%%1"))
end

-- @param escapeShell: Escape a string to be used as a shell token
-- Quotes spaces, parentheses and \s
--   @param s: string to process
-- returns
--   @param s_: processed string
function escapeShell (s)
  return (string.gsub (s, "([ %(%)%\\])", "\\%1"))
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

-- @func ordinalSuffix: return the English suffix for an ordinal
--   @param n: number of the day
-- returns
--   @param s: suffix
function ordinalSuffix (n)
  n = math.mod (n, 100)
  local d = math.mod (n, 10)
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
