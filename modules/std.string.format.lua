-- Formatting text

require "std.assert"


-- TODO: Pretty printing
--
--   Use in getopt
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


-- @func string.format: Format, but only if more than one argument
--   @param (s: string
--   ( or
--   @param (...: arguments for format
-- returns
--   @param r: formatted string, or s if only one argument
local _format = string.format
function string.format (...)
  if table.getn (arg) == 1 then
    return arg[1]
  else
    return _format (unpack (arg) or "")
  end
end

-- string.pad: Justify a string
-- When the string is longer than w, it is truncated (left or right
-- according to the sign of w)
--   s: string to justify
--   w: width to justify to (-ve means right-justify; +ve means
--     left-justify)
--   [p]: string to pad with [" "]
-- returns
--   s_: justified string
function string.pad (s, w, p)
  p = string.rep (p or " ", abs (w))
  if w < 0 then
    return string.sub (p .. s, -w)
  end
  return string.sub (s .. p, 1, w)
end

-- string.wrap: Wrap a string into a paragraph
--   s: string to wrap
--   w: width to wrap to [78]
--   ind: indent [0]
--   ind1: indent of first line [ind]
-- returns
--   s_: wrapped paragraph
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
