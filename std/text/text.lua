-- Text processing

require "std/assert.lua"
require "std/text/regex.lua"
require "std/data/table.lua"


-- strconcat: Give a name to .. for strings
--   s, t: strings
-- returns
--   s_: s .. t
function strconcat (s, t)
  return s .. t
end

-- strcaps: Capitalise each word in a string
-- TODO: rewrite for 4.1 using bracket notation
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
-- TODO: rewrite for 4.1 using bracket notation
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

-- pad: Justify a string
-- When the string is longer than w, it is truncated (left or right
-- according to the sign of w)
--   s: string to justify
--   w: width to justify to (-ve means right-justify; +ve means
--     left-justify)
--   [p]: string to pad with [" "]
-- returns
--   s_: justified string
function pad (s, w, p)
  p = strrep (p or " ", abs (w))
  if w < 0 then
    return strsub (p .. s, -w)
  end
  return strsub (s .. p, 1, w)
end

-- wrap: Wrap a string into a paragraph
--   s: string to wrap
--   w: width to wrap to [78]
--   ind: indent [0]
--   ind1: indent of first line [ind]
-- returns
--   s_: wrapped paragraph
function wrap (s, w, ind, ind1)
  w = w or 78
  ind = ind or 0
  ind1 = ind1 or ind
  affirm (ind1 < w and ind < w,
          "the indents must be less than the line width")
  s = strrep (" ", ind1) .. s
  local lstart, len = 1, strlen (s)
  while len - lstart > w - ind do
    local i = lstart + w - ind
    while i > lstart and strsub (s, i, i) ~= " " do
      i = i - 1
    end
    local j = i
    while j > lstart and strsub (s, j, j) == " " do
      j = j - 1
    end
    s = strsub (s, 1, j) .. "\n" .. strrep (" ", ind) ..
      strsub (s, i + 1, -1)
    local change = ind + 1 - (i - j)
    lstart = j + change
    len = len + change
  end
  return s
end

-- escapePattern: Escape a string to be used as a pattern
-- TODO: rewrite for 4.1 using bracket notation
--   s: string to process
-- returns
--   s_: processed string
function escapePattern (s)
  s = gsub (s, "(%W)", "%%%1")
  return s
end

-- escapeShell: Escape a string to be used as a shell token
-- Quotes spaces, parentheses and \s
-- TODO: rewrite for 4.1 using bracket notation
--   s: string to process
-- returns
--   s_: processed string
function escapeShell (s)
  s = gsub (s, "([ %(%)%\\])", "\\%1")
  return s
end

-- stringifier: table of functions to stringify objects
-- Default method for otherwise unhandled table types
--   {[t] = f, ...} where
--     t: tag
--     f: function
--       x: object of tag t
--     returns
--       s: string representation of t
stringifier =
  defaultTable (function (x)
                  if type (x) == "table" then
                    local s, sep = "{", ""
                    for i, v in x do
                      s = s .. sep .. tostring (i) .. "=" ..
                        tostring (v)
                      sep = ","
                    end
                    return s .. "}"
                  else
                    return nil
                  end
                end,
                {})

-- tostring: Extend tostring to work better on tables
-- TODO: make it output in {v1, v2 ..; x1=y1, x2=y2 ..} format; use
-- nexti; show the n field (if any) on the RHS
--   x: object to convert to string
-- returns
--   s: string representation
local _tostring = tostring
function tostring (x)
  return stringifier[tag (x)] (x) or %_tostring (x)
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
