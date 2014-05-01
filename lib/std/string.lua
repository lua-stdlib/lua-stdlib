--[[--
 Additions to the string module.

 If you `require "std"`, the contents of this module are all available
 in the `std.string` table.

 However, this module also contains references to the Lua core string
 table entries, so it's safe to load it like this:

     local string = require "std.string"

 Of course, if you do that you'll lose references to any core string
 functions overwritten by `std.string`, so you might want to save any
 that you want access to before you overwrite them.

 If your code does not `require "std"` anywhere, then you'll also need
 to manually overwrite string functions in the global namespace if you
 want to use them from there:

     local assert, tostring = string.assert, string.tostring

 And finally, to use the string metatable improvements with all core
 strings, you'll need to merge this module's metatable into the core
 string metatable (again, `require "std"` does this automatically):

     local string_metatable = getmetatable ""
     string_metatable.__append = string.__append
     string_metatable.__concat = string.__concat
     string_metatable.__index = string.__index

 @module std.string
]]

local List   = require "std.list"
local StrBuf = require "std.strbuf"
local table  = require "std.table"

local metamethod = (require "std.base").metamethod

local _format   = string.format
local _tostring = _G.tostring

local M = {}

--- String append operation.
-- @param s string
-- @param c character (1-character string)
-- @return `s .. c`
local function __append (s, c)
  return s .. c
end

--- String concatenation operation.
-- @param s string
-- @param o object
-- @return s .. tostring (o)
local function __concat (s, o)
  return M.tostring (s) .. M.tostring (o)
end

--- String subscript operation.
-- @param s string
-- @param i index
-- @return `s:sub (i, i)` if i is a number, otherwise
--   fall back to a `std.string` metamethod (if any).
local function __index (s, i)
  if type (i) == "number" then
    return s:sub (i, i)
  else
    -- Fall back to module metamethods
    return M[i]
  end
end



--- Extend to work better with one argument.
-- If only one argument is passed, no formatting is attempted.
-- @param f format
-- @param arg1 first argument to format
-- @param ... arguments to format
-- @return formatted string
local function format (f, arg1, ...)
  if arg1 == nil then
    return f
  else
    return _format (f, arg1, ...)
  end
end

--- Extend to allow formatted arguments.
-- @param v value to assert
-- @param f format
-- @param ... arguments to format
-- @return value
local function assert (v, f, ...)
  if not v then
    if f == nil then
      f = ""
    end
    error (format (f, ...), 2)
  end
  return v
end

--- Do find, returning captures as a list.
-- @param s target string
-- @param p pattern
-- @param init start position (default: 1)
-- @param plain inhibit magic characters (default: nil)
-- @return start of match, end of match, table of captures
local function tfind (s, p, init, plain)
  assert (type (s) == "string",
          "bad argument #1 to 'tfind' (string expected, got " .. type (s) .. ")")
  assert (type (p) == "string",
          "bad argument #2 to 'tfind' (string expected, got " .. type (p) .. ")")
  local function pack (from, to, ...)
    return from, to, {...}
  end
  return pack (p.find (s, p, init, plain))
end

--- Do multiple `find`s on a string.
-- @param s target string
-- @param p pattern
-- @param init start position (default: 1)
-- @param plain inhibit magic characters (default: nil)
-- @return list of `{from, to; capt = {captures}}`
local function finds (s, p, init, plain)
  init = init or 1
  local l = {}
  local from, to, r
  repeat
    from, to, r = tfind (s, p, init, plain)
    if from ~= nil then
      l[#l + 1] = {from, to, capt = r}
      init = to + 1
    end
  until not from
  return l
end

--- Split a string at a given separator.
-- Separator is a Lua pattern, so you have to escape active characters,
-- `^$()%.[]*+-?` with a `%` prefix to match a literal character in `s`.
-- @string s to split
-- @string[opt="%s*"] sep separator pattern
-- @return list of strings
-- @return list of strings
local function split (s, sep)
  assert (type (s) == "string",
          "bad argument #1 to 'split' (string expected, got " .. type (s) .. ")")
  local b, len, t, patt = 0, #s, {}, "(.-)" .. sep
  if sep == "" then patt = "(.)"; t[#t + 1] = "" end
  while b <= len do
    local e, n, m = string.find (s, patt, b + 1)
    t[#t + 1] = m or s:sub (b + 1, len)
    b = n or len + 1
  end
  return t
end

--- Require a module with a particular version.
-- @param module module to require
-- @param min lowest acceptable version (default: any)
-- @param too_big lowest version that is too big (default: none)
-- @param pattern to match version in `module.version` or
-- `module.VERSION` (default: `".*[%.%d]+"`)
local function require_version (module, min, too_big, pattern)
  local function version_to_list (v)
    return List (split (v, "%."))
  end
  local function module_version (module, pattern)
    return version_to_list (string.match (module.version or module._VERSION,
                                          pattern or ".*[%.%d]+"))
  end
  local m = require (module)
  if min then
    assert (module_version (m, pattern) >= version_to_list (min))
  end
  if too_big then
    assert (module_version (m, pattern) < version_to_list (too_big))
  end
  return m
end


-- Write pretty-printing based on:
--
--   John Hughes's and Simon Peyton Jones's Pretty Printer Combinators
--
--   Based on "The Design of a Pretty-printing Library in Advanced
--   Functional Programming", Johan Jeuring and Erik Meijer (eds), LNCS 925
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


--- Turn tables into strings with recursion detection.
-- N.B. Functions calling render should not recurse, or recursion
-- detection will not work.
-- @see render_OpenRenderer, render_CloseRenderer
-- @see render_ElementRenderer, render_PairRenderer
-- @see render_SeparatorRenderer
-- @param x object to convert to string
-- @param open open table renderer
-- @param close close table renderer
-- @param elem element renderer
-- @param pair pair renderer
-- @param sep separator renderer
-- @param roots accumulates table references to detect recursion
-- @return string representation
local function render (x, open, close, elem, pair, sep, roots)
  local function stop_roots (x)
    return roots[x] or render (x, open, close, elem, pair, sep, table.clone (roots))
  end
  roots = roots or {}
  if type (x) ~= "table" or metamethod (x, "__tostring") then
    return elem (x)
  else
    local s = StrBuf {}
    s = s .. open (x)
    roots[x] = elem (x)

    -- create a sorted list of keys
    local ord = {}
    for k, _ in pairs (x) do ord[#ord + 1] = k end
    table.sort (ord, function (a, b) return tostring (a) < tostring (b) end)

    -- render x elements in order
    local i, v = nil, nil
    for _, j in ipairs (ord) do
      local w = x[j]
      s = s .. sep (x, i, v, j, w) .. pair (x, j, w, stop_roots (j), stop_roots (w))
      i, v = j, w
    end
    s = s .. sep (x, i, v, nil, nil) .. close (x)
    return s:tostring ()
  end
end

---
-- @function render_OpenRenderer
-- @param t table
-- @return open table string

---
-- @function render_CloseRenderer
-- @param t table
-- @return close table string

---
-- @function render_ElementRenderer
-- @param e element
-- @return element string

--- NB. the function should not try to render i and v, or treat them recursively.
-- @function render_PairRenderer
-- @param t table
-- @param i index
-- @param v value
-- @param is index string
-- @param vs value string
-- @return element string

---
-- @function render_SeparatorRenderer
-- @param t table
-- @param i preceding index (nil on first call)
-- @param v preceding value (nil on first call)
-- @param j following index (nil on last call)
-- @param w following value (nil on last call)
-- @return separator string

--- Extend `tostring` to work better on tables.
-- @function tostring
-- @param x object to convert to string
-- @return string representation
local function tostring (x)
  return render (x,
                 function () return "{" end,
                 function () return "}" end,
                 _tostring,
                 function (t, _, _, i, v)
                   return i .. "=" .. v
                 end,
                 function (_, i, _, j)
                   if i and j then
                     return ","
                   end
                   return ""
                 end)
end


--- Pretty-print a table.
-- @param t table to print
-- @param indent indent between levels ["\t"]
-- @param spacing space before every line
-- @return pretty-printed string
local function prettytostring (t, indent, spacing)
  indent = indent or "\t"
  spacing = spacing or ""
  return render (t,
                 function ()
                   local s = spacing .. "{"
                   spacing = spacing .. indent
                   return s
                 end,
                 function ()
                   spacing = string.gsub (spacing, indent .. "$", "")
                   return spacing .. "}"
                 end,
                 function (x)
                   if type (x) == "string" then
                     return format ("%q", x)
                   else
                     return tostring (x)
                   end
                 end,
                 function (x, i, v, is, vs)
                   local s = spacing
		   if type (i) ~= "string" or i:match "[^%w_]" then
		     s = s .. "["
                     if type (i) == "table" then
                       s = s .. "\n"
                     end
                     s = s .. is
                     if type (i) == "table" then
                       s = s .. "\n"
                     end
                     s = s .. "]"
		   else
		     s = s .. i
		   end
		   s = s .. " ="
                   if type (v) == "table" then
                     s = s .. "\n"
                   else
                     s = s .. " "
                   end
                   s = s .. vs
                   return s
                 end,
                 function (_, i)
                   local s = "\n"
                   if i then
                     s = "," .. s
                   end
                   return s
                 end)
end


--- Overwrite core methods and metamethods with `std` enhanced versions.
--
-- Adds auto-stringification to `..` operator on core strings, and
-- integer indexing of strings with `[]` dereferencing.
--
-- Also replaces core `assert` and `tostring` functions with
-- `std.string` versions.
-- @tparam[opt=_G] table namespace where to install global functions
-- @treturn table the module table
local function monkey_patch (namespace)
  namespace = namespace or _G

  assert (type (namespace) == "table",
          "bad argument #1 to 'monkey_patch' (table expected, got " .. type (namespace) .. ")")

  namespace.assert, namespace.tostring = assert, tostring

  local string_metatable = getmetatable ""
  string_metatable.__append = __append
  string_metatable.__concat = __concat
  string_metatable.__index = __index

  return M
end


--- Convert a value to a string.
-- The string can be passed to dostring to retrieve the value.
-- @todo Make it work for recursive tables.
-- @param x object to pickle
-- @return string such that eval (s) is the same value as x
local function pickle (x)
  if type (x) == "string" then
    return format ("%q", x)
  elseif type (x) == "number" or type (x) == "boolean" or
    type (x) == "nil" then
    return tostring (x)
  else
    x = totable (x) or x
    if type (x) == "table" then
      local s, sep = "{", ""
      for i, v in pairs (x) do
        s = s .. sep .. "[" .. pickle (i) .. "]=" .. pickle (v)
        sep = ","
      end
      s = s .. "}"
      return s
    else
      die ("cannot pickle " .. tostring (x))
    end
  end
end


--- Capitalise each word in a string.
-- @param s string
-- @return capitalised string
local function caps (s)
  return (string.gsub (s, "(%w)([%w]*)",
                      function (l, ls)
                        return string.upper (l) .. ls
                      end))
end

--- Remove any final newline from a string.
-- @param s string to process
-- @return processed string
local function chomp (s)
  return (string.gsub (s, "\n$", ""))
end

--- Escape a string to be used as a pattern.
-- @param s string to process
-- @return processed string
local function escape_pattern (s)
  return (string.gsub (s, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

--- Escape a string to be used as a shell token.
-- Quotes spaces, parentheses, brackets, quotes, apostrophes and
-- whitespace.
-- @param s string to process
-- @return processed string
local function escape_shell (s)
  return (string.gsub (s, "([ %(%)%\\%[%]\"'])", "\\%1"))
end

--- Return the English suffix for an ordinal.
-- @param n number of the day
-- @return suffix
local function ordinal_suffix (n)
  n = math.abs (n) % 100
  local d = n % 10
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

--- Justify a string.
-- When the string is longer than w, it is truncated (left or right
-- according to the sign of w).
-- @param s string to justify
-- @param w width to justify to (-ve means right-justify; +ve means
-- left-justify)
-- @param p string to pad with (default: `" "`)
-- @return justified string
local function pad (s, w, p)
  p = string.rep (p or " ", math.abs (w))
  if w < 0 then
    return string.sub (p .. s, w)
  end
  return string.sub (s .. p, 1, w)
end

--- Wrap a string into a paragraph.
-- @param s string to wrap
-- @param w width to wrap to (default: 78)
-- @param ind indent (default: 0)
-- @param ind1 indent of first line (default: ind)
-- @return wrapped paragraph
local function wrap (s, w, ind, ind1)
  w = w or 78
  ind = ind or 0
  ind1 = ind1 or ind
  assert (ind1 < w and ind < w,
          "the indents must be less than the line width")
  assert (type (s) == "string",
          "bad argument #1 to 'wrap' (string expected, got " .. type (s) .. ")")
  local r = StrBuf { string.rep (" ", ind1) }
  local i, lstart, len = 1, ind1, #s
  while i <= #s do
    local j = i + w - lstart
    while #s[j] > 0 and s[j] ~= " " and j > i do
      j = j - 1
    end
    local ni = j + 1
    while s[j] == " " do
      j = j - 1
    end
    r:concat (s:sub (i, j))
    i = ni
    if i < #s then
      r:concat ("\n" .. string.rep (" ", ind))
      lstart = ind
    end
  end
  return r:tostring ()
end

--- Write a number using SI suffixes.
-- The number is always written to 3 s.f.
-- @param n number
-- @return string
local function numbertosi (n)
  local SIprefix = {
    [-8] = "y", [-7] = "z", [-6] = "a", [-5] = "f",
    [-4] = "p", [-3] = "n", [-2] = "mu", [-1] = "m",
    [0] = "", [1] = "k", [2] = "M", [3] = "G",
    [4] = "T", [5] = "P", [6] = "E", [7] = "Z",
    [8] = "Y"
  }
  local t = format("% #.2e", n)
  local _, _, m, e = t:find(".(.%...)e(.+)")
  local man, exp = tonumber (m), tonumber (e)
  local siexp = math.floor (exp / 3)
  local shift = exp - siexp * 3
  local s = SIprefix[siexp] or "e" .. tostring (siexp)
  man = man * (10 ^ shift)
  return tostring (man) .. s
end

--- Remove leading matter from a string.
-- @param s string
-- @param r leading pattern (default: `"%s+"`)
-- @return string without leading r
local function ltrim (s, r)
  r = r or "%s+"
  return (string.gsub (s, "^" .. r, ""))
end

--- Remove trailing matter from a string.
-- @param s string
-- @param r trailing pattern (default: `"%s+"`)
-- @return string without trailing r
local function rtrim (s, r)
  r = r or "%s+"
  return (string.gsub (s, r .. "$", ""))
end

--- Remove leading and trailing matter from a string.
-- @param s string
-- @param r leading/trailing pattern (default: `"%s+"`)
-- @return string without leading/trailing r
local function trim (s, r)
  return rtrim (ltrim (s, r), r)
end


--- @export
M = {
  __append        = __append,
  __concat        = __concat,
  __index         = __index,
  assert          = assert,
  caps            = caps,
  chomp           = chomp,
  escape_pattern  = escape_pattern,
  escape_shell    = escape_shell,
  finds           = finds,
  format          = format,
  ltrim           = ltrim,
  monkey_patch    = monkey_patch,
  numbertosi      = numbertosi,
  ordinal_suffix  = ordinal_suffix,
  pad             = pad,
  pickle          = pickle,
  prettytostring  = prettytostring,
  render          = render,
  require_version = require_version,
  rtrim           = rtrim,
  split           = split,
  tfind           = tfind,
  tostring        = tostring,
  trim            = trim,
  wrap            = wrap,
}

for k, v in pairs (string) do
  M[k] = M[k] or v
end

return M
