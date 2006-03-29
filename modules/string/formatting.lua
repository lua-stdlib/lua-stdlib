-- Formatting text

module ("string.formatting", package.seeall)

require "assert_ext"


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
  local _, _, m, e = string.find(t, ".(.%...)e(.+)")
  local man, exp = tonumber (m), tonumber (e)
  local siexp = math.floor (exp / 3)
  local shift = exp - siexp * 3
  local s = SIprefix[siexp] or "e" .. tostring (siexp)
  man = man * (10 ^ shift)
  return tostring (man) .. s
end
