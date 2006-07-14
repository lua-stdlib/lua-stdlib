-- String

module ("std.string", package.seeall)

require "std.lcs"


-- TODO: Pretty printing
--
--   (Use in getopt)
--
--   John Hughes's and Simon Peyton Jones's Pretty Printer Combinators
--   
--   Based on The Design of a Pretty-printing Library in Advanced
--   Functional Programming, Johan Jeuring and Erik Meijer (eds), LNCS 925
--   http://www.cs.chalmers.se/~rjmh/Papers/pretty.ps
--   Heavily modified by Simon Peyton Jones, Dec 96
--   
--   Haskell types:
--   data Doc     list of lines
--   quote :: Char -> Char -> Doc -> Doc    Wrap document in ...
--   (<>) :: Doc -> Doc -> Doc              Beside
--   (<+>) :: Doc -> Doc -> Doc             Beside, separated by space
--   ($$) :: Doc -> Doc -> Doc              Above; if there is no overlap it "dovetails" the two
--   nest :: Int -> Doc -> Doc              Nested
--   punctuate :: Doc -> [Doc] -> [Doc]     punctuate p [d1, ... dn] = [d1 <> p, d2 <> p, ... dn-1 <> p, dn]
--   render      :: Int                     Line length
--               -> Float                   Ribbons per line
--               -> (TextDetails -> a -> a) What to do with text
--               -> a                       What to do at the end
--               -> Doc                     The document
--               -> a                       Result


-- TODO: Replace the string.* API so that pattern arguments always
--   have their metamethods called, and if you call a function, e.g.
--   string.gsub or string.find, it automatically does the right
--   thing. The functions below should also be injected into the
--   metatables so they can be called as functions or methods.

-- @func string.concat: Give a name to .. for strings
--   @param s1, s2, ..., sn: strings
-- @returns
--   @param s_: s1 .. s2 .. ... .. sn
function string.concat (...)
  return table.concat (arg)
end

-- @func string.caps: Capitalise each word in a string
--   @param s: string
-- @returns
--   @param s_: capitalised string
function string.caps (s)
  return (string.gsub (s, "(%w)([%w]*)",
                       function (l, ls)
                         return string.upper (l) .. ls
                       end))
end

-- @func string.chomp: Remove any final newline from a string
--   @param s: string to process
-- @returns
--   @param s_: processed string
function string.chomp (s)
  return (string.gsub (s, "\n$", ""))
end

-- @func string.escapePattern: Escape a string to be used as a pattern
--   @param s: string to process
-- @returns
--   @param s_: processed string
function string.escapePattern (s)
  return (string.gsub (s, "(%W)", "%%%1"))
end

-- @param string.escapeShell: Escape a string to be used as a shell token
-- Quotes spaces, parentheses, brackets, quotes, apostrophes and \s
--   @param s: string to process
-- @returns
--   @param s_: processed string
function string.escapeShell (s)
  return (string.gsub (s, "([ %(%)%\\%[%]\"'])", "\\%1"))
end

-- @func string.ordinalSuffix: Return the English suffix for an ordinal
--   @param n: number of the day
-- @returns
--   @param s: suffix
function string.ordinalSuffix (n)
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

-- @func string.lcs: Find the longest common subsequence of two
-- strings
--   @param: a, b: strings
-- @returns
--   @param: s: longest common subsequence
function string.lcs (a, b)
  return lcs.longestCommonSubseq (a, b,
                                  function (s, i)
                                    return string.sub (s, i, i)
                                  end,
                                  string.len, string.concat, "")
end

-- @func string.format: Extend to work better with one argument
-- If only one argument is passed, no formatting is attempted
--   @param f: format
--   @param ...: arguments to format
-- @returns
--   @param s: formatted string
local _format = string.format
function string.format (f, ...)
  if table.getn (arg) == 0 then
    return f
  else
    return _format (f, unpack (arg))
  end
end

-- @func string.pad: Justify a string
-- When the string is longer than w, it is truncated (left or right
-- according to the sign of w)
--   @param s: string to justify
--   @param w: width to justify to (-ve means right-justify; +ve means
--     left-justify)
--   @param [p]: string to pad with [" "]
-- @returns
--   s_: justified string
function string.pad (s, w, p)
  p = string.rep (p or " ", abs (w))
  if w < 0 then
    return string.sub (p .. s, -w)
  end
  return string.sub (s .. p, 1, w)
end

-- @func string.wrap: Wrap a string into a paragraph
--   @param s: string to wrap
--   @param w: width to wrap to [78]
--   @param ind: indent [0]
--   @param ind1: indent of first line [ind]
-- @returns
--   @param s_: wrapped paragraph
function string.wrap (s, w, ind, ind1)
  w = w or 78
  ind = ind or 0
  ind1 = ind1 or ind
  assert (ind1 < w and ind < w,
          "the indents must be less than the line width")
  s = string.rep (" ", ind1) .. s
  local lstart, len = 1, string.len (s)
  while len - lstart > w - ind do
    local i = lstart + w - ind
    while i > lstart and string.sub (s, i, i) ~= " " do
      i = i - 1
    end
    local j = i
    while j > lstart and string.sub (s, j, j) == " " do
      j = j - 1
    end
    s = string.sub (s, 1, j) .. "\n" .. string.rep (" ", ind) ..
      string.sub (s, i + 1, -1)
    local change = ind + 1 - (i - j)
    lstart = j + change
    len = len + change
  end
  return s
end

-- @func string.numbertosi: Write a number using SI suffixes
-- The number is always written to 3 s.f.
--   @param n: number
-- @returns
--   @param n_: string
function string.numbertosi (n)
  local SIprefix = {
    [-8] = "y", [-7] = "z", [-6] = "a", [-5] = "f",
    [-4] = "p", [-3] = "n", [-2] = "mu", [-1] = "m",
    [0] = "", [1] = "k", [2] = "M", [3] = "G",
    [4] = "T", [5] = "P", [6] = "E", [7] = "Z",
    [8] = "Y"
  }
  local t = string.format("% #.2e", n)
  local _, _, m, e = t:find(".(.%...)e(.+)")
  local man, exp = tonumber (m), tonumber (e)
  local siexp = math.floor (exp / 3)
  local shift = exp - siexp * 3
  local s = SIprefix[siexp] or "e" .. tostring (siexp)
  man = man * (10 ^ shift)
  return tostring (man) .. s
end


-- @function string.findl: Do string.find, returning captures as a list
--   @param s: target string
--   @param p: pattern
--   @param [init]: start position [1]
--   @param [plain]: inhibit magic characters [nil]
-- @returns
--   @param from, to: start and finish of match
--   @param capt: table of captures
function string.findl (s, p, init, plain)
  local function pack (from, to, ...)
    return from, to, {...}
  end
  return pack (s:find (p, init, plain))
end

-- @function string.finds: Do multiple string.find's on a string
--   @param s: target string
--   @param p: pattern
--   @param [init]: start position [1]
--   @param [plain]: inhibit magic characters [nil]
-- @returns
--   @param t: table of {from, to; capt = {captures}}
function string.finds (s, p, init, plain)
  init = init or 1
  local t = {}
  local from, to, r
  repeat
    from, to, r = string.findl (s, p, init, plain)
    if from ~= nil then
      table.insert (t, {from, to, capt = r})
      init = to + 1
    end
  until not from
  return t
end

-- @function string.gsubs: Perform multiple calls to string.gsub
--   @param s: string to call string.gsub on
--   @param sub: {pattern1=replacement1 ...}
--   @param [n]: upper limit on replacements [infinite]
-- @returns
--   @param s_: result string
--   @param r: number of replacements made
function string.gsubs (s, sub, n)
  local r = 0
  for i, v in pairs (sub) do
    local rep
    if n ~= nil then
      s, rep = string.gsub (s, i, v, n)
      r = r + rep
      n = n - rep
      if n == 0 then
        break
      end
    else
      s, rep = string.gsub (s, i, v)
      r = r + rep
    end
  end
  return s, r
end

-- @function string.split: Split a string at a given separator
--   @param [sep]: separator regex ["%s+"]
--   @param s: string to split
-- @returns
--   @param l: list of strings
function string.split (sep, s)
  if s == nil then
    s, sep = sep, "%s+" -- TODO: make the default pattern configurable by the regex library
  end
  -- string.finds gets a list of {from, to, capt = {}} lists; we then
  -- flatten the result, discarding the captures, add 0 (1 before the
  -- first character) to the start and 0 (1 after the last character)
  -- to the end, and flatten the result again.
  local pairs = list.concat ({0}, list.concat (unpack (string.finds(s, sep))), {0})
  local l = {}
  for i = 1, table.getn (pairs), 2 do
    table.insert (l, string.sub (s, pairs[i] + 1, pairs[i + 1] - 1))
  end
  return l
end

-- @function string.ltrim: Remove leading matter from a string
--   @param [r]: leading regex ["%s+"]
--   @param s: string
-- @returns
--   @param s_: string without leading r
function string.ltrim (r, s)
  if s == nil then
    s, r = r, "%s+"
  end
  return (string.gsub (s, "^" .. r, ""))
end

-- @function string.rtrim: Remove trailing matter from a string
--   @param [r]: trailing regex ["%s+"]
--   @param s: string
-- @returns
--   @param s_: string without trailing r
function string.rtrim (r, s)
  if s == nil then
    s, r = r, "%s+"
  end
  return (string.gsub (s, r .. "$", ""))
end

-- @function string.trim: Remove leading and trailing matter from a
-- string
--   @param [r]: leading/trailing regex ["%s+"]
--   @param s: string
-- @returns
--   @param s_: string without leading/trailing r
function string.trim (r, s)
  return string.ltrim (string.rtrim (r, s))
end

-- TODO: @function string.rgsub: string.gsub-like wrapper for match
--   @param s: target string
--   @param p: pattern
--   @param r: function
--     @param t: table of captures
--   @param [n]: maximum number of substutions [infinite]
--   @returns
--     @param rep: replacement
-- @returns
--   @param n: number of substitutions made
