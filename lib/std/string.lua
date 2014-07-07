--[[--
 Additions to the core string module.

 The module table returned by `std.string` also contains all of the entries
 from the core string table.  An hygienic way to import this module, then, is
 simply to override the core `string` locally:

    local string = require "std.string"

 @module std.string
]]

local base   = require "std.base"
local list   = require "std.list"
local strbuf = require "std.strbuf"
local table  = require "std.table"

local List   = list {}
local StrBuf = strbuf {}

local export, getmetamethod, lambda, split =
  base.export, base.getmetamethod, base.lambda, base.split

local _format   = string.format
local _tostring = _G.tostring

local M = { "std.string" }

local render -- forward declaration



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


--- Pack return arguments for `tfind`.
-- @int from start of match
-- @int to end of match
-- @param ... captures
-- @treturn int from
-- @treturn int to
-- @treturn table captures
-- @usage return tfind_pack (string.find
local function tpack (from, to, ...)
  return from, to, {...}
end


--- Return a List object by splitting version string on periods.
-- @string version a period delimited version string
-- @treturn List a list of version components
local function version_to_list (version)
  return List (split (version, "%."))
end


--- Extract a list of period delimited integer version components.
-- @tparam table module returned from a `require` call
-- @string pattern to capture version number from a string
--   (default: `"%D*([%.%d]+)"`)
-- @treturn List a list of version components
local function module_version (module, pattern)
  local version = module.version or module._VERSION
  return version_to_list (version:match (pattern or "%D*([%.%d]+)"))
end



--[[ ============ ]]--
--[[ Metamethods. ]]--
--[[ ============ ]]--


--- String concatenation operation.
-- @string s initial string
-- @param o object to stringify and concatenate
-- @return s .. tostring (o)
-- @usage
-- local string = require "std.string".monkey_patch ()
-- concatenated = "foo" .. {"bar"}
function M.__concat (s, o)
  return M.tostring (s) .. M.tostring (o)
end


--- String subscript operation.
-- @string s string
-- @tparam int|string i index or method name
-- @return `s:sub (i, i)` if i is a number, otherwise
--   fall back to a `std.string` metamethod (if any).
-- @usage
-- getmetatable ("").__index = require "std.string".__index
-- third = ("12345")[3]
function M.__index (s, i)
  if type (i) == "number" then
    return s:sub (i, i)
  else
    -- Fall back to module metamethods
    return M[i]
  end
end



--[[ ================= ]]--
--[[ Module Functions. ]]--
--[[ ================= ]]--


--- Extend to work better with one argument.
-- If only one argument is passed, no formatting is attempted.
-- @function format
-- @string f format string
-- @param[opt] ... arguments to format
-- @return formatted string
-- @usage print (format "100% stdlib!")
local format = export (M, "format (string, any?*)", function (f, arg1, ...)
  return (arg1 ~= nil) and _format (f, arg1, ...) or f
end)


--- Extend to allow formatted arguments.
-- @function assert
-- @param expect expression, expected to be *truthy*
-- @string[opt=""] f format string
-- @param[opt] ... arguments to format
-- @return value of *expect*, if *truthy*
-- @usage assert (expected == actual, "100% unexpected!")
export (M, "assert (any?, string?, any?*)", function (expect, f, ...)
  return expect or error (format (f or "", ...), 2)
end)


--- Do `string.find`, returning a table of captures.
-- @function tfind
-- @string s target string
-- @string pattern pattern to match in *s*
-- @int[opt=1] init start position
-- @bool[opt] plain inhibit magic characters
-- @treturn int start of match
-- @treturn int end of match
-- @treturn table list of captured strings
-- @see std.string.finds
-- @usage b, e, captures = tfind ("the target string", "%s", 10)
local tfind = export (M, "tfind (string, string, int?, boolean|:plain?)", function (s, ...)
  return tpack (s:find (...))
end)


--- Repeatedly `string.find` until target string is exhausted.
-- @function finds
-- @string s target string
-- @string pattern pattern to match in *s*
-- @int[opt=1] init start position
-- @bool[opt] plain inhibit magic characters
-- @return list of `{from, to; capt = {captures}}`
-- @see std.string.tfind
-- @usage
-- for t in list.elems (finds ("the target string", "%S+")) do
--   print (tostring (t.capt))
-- end
export (M, "finds (string, string, int?, boolean|:plain?)", function (s, p, i, ...)
  i = i or 1
  local l = {}
  local from, to, r
  repeat
    from, to, r = tfind (s, p, i, ...)
    if from ~= nil then
      l[#l + 1] = {from, to, capt = r}
      i = to + 1
    end
  until not from
  return l
end)


--- Split a string at a given separator.
-- Separator is a Lua pattern, so you have to escape active characters,
-- `^$()%.[]*+-?` with a `%` prefix to match a literal character in *s*.
-- @function split
-- @string s to split
-- @string[opt="%s+"] sep separator pattern
-- @return list of strings
-- @usage words = split "a very short sentence"
export (M, "split (string, string?)", split)


--- Require a module with a particular version.
-- @function require
-- @string module module to require
-- @string[opt] min lowest acceptable version
-- @string[opt] too_big lowest version that is too big
-- @string[opt] pattern to match version in `module.version` or
--  `module._VERSION` (default: `"%D*([%.%d]+)"`)
-- @usage std = require ("std", "41")
export (M, "require (string, string?, string?, string?)",
function (module, min, too_big, pattern)
  local m = require (module)
  if min then
    assert (module_version (m, pattern) >= version_to_list (min))
  end
  if too_big then
    assert (module_version (m, pattern) < version_to_list (too_big))
  end
  return m
end)


-- DEPRECATED: Remove in first release following 2015-06-30.
M.require_version = base.deprecate (M.require, nil,
  "string.require_version is deprecated, use string.require instead")


--- Overwrite core methods and metamethods with `std` enhanced versions.
--
-- Adds auto-stringification to `..` operator on core strings, and
-- integer indexing of strings with `[]` dereferencing.
--
-- Also replaces core `assert`, `require` and `tostring` functions with
-- `std.string` versions.
-- @function monkey_patch
-- @tparam[opt=_G] table namespace where to install global functions
-- @treturn table the module table
-- @usage local string = require "std.string".monkey_patch ()
export (M, "monkey_patch (table?)", function (namespace)
  namespace = namespace or _G
  namespace.assert, namespace.require, namespace.tostring =
    M.assert, M.require, M.tostring

  local string_metatable = getmetatable ""
  string_metatable.__concat = M.__concat
  string_metatable.__index = M.__index

  return M
end)


--- Capitalise each word in a string.
-- @function caps
-- @string s any string
-- @treturn string *s* with each word capitalized
-- @usage userfullname = caps (input_string)
export (M, "caps (string)", function (s)
  return s:gsub ("(%w)([%w]*)", function (l, ls) return l:upper () .. ls end)
end)


--- Remove any final newline from a string.
-- @function chomp
-- @string s any string
-- @treturn string *s* with any single trailing newline removed
-- @usage line = chomp (line)
export (M, "chomp (string)", function (s)
  return s:gsub ("\n$", "")
end)


--- Escape a string to be used as a pattern.
-- @function escape_pattern
-- @string s any string
-- @treturn string *s* with active pattern characters escaped
-- @usage substr = inputstr:match (escape_pattern (literal))
export (M, "escape_pattern (string)", function (s)
  return s:gsub ("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
end)


--- Escape a string to be used as a shell token.
-- Quotes spaces, parentheses, brackets, quotes, apostrophes and
-- whitespace.
-- @function escape_shell
-- @string s any string
-- @treturn string *s* with active shell characters escaped
-- @usage os.execute ("echo " .. escape_shell (outputstr))
export (M, "escape_shell (string)", function (s)
  return (string.gsub (s, "([ %(%)%\\%[%]\"'])", "\\%1"))
end)


--- Return the English suffix for an ordinal.
-- @function ordinal_suffix
-- @tparam int|string n any integer value
-- @treturn string English suffix for *n*
-- @usage
-- local now = os.date "*t"
-- print ("%d%s day of the week", now.day, ordinal_suffix (now.day))
export (M, "ordinal_suffix (int|string)", function (n)
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
end)


--- Justify a string.
-- When the string is longer than w, it is truncated (left or right
-- according to the sign of w).
-- @function pad
-- @string s a string to justify
-- @int w width to justify to (-ve means right-justify; +ve means
--   left-justify)
-- @string[opt=" "] p string to pad with
-- @treturn string *s* justified to *w* characters wide
-- @usage print (pad (trim (outputstr, 78)) .. "\n")
export (M, "pad (string, int, string?)", function (s, w, p)
  p = string.rep (p or " ", math.abs (w))
  if w < 0 then
    return string.sub (p .. s, w)
  end
  return string.sub (s .. p, 1, w)
end)


--- Wrap a string into a paragraph.
-- @function wrap
-- @string s a paragraph of text
-- @int[opt=78] w width to wrap to
-- @int[opt=0] ind indent
-- @int[opt=ind] ind1 indent of first line
-- @treturn string *s* wrapped to *w* columns
-- @usage
-- print (wrap (copyright, 72, 4))
export (M, "wrap (string, int?, int?, int?)", function (s, w, ind, ind1)
  w = w or 78
  ind = ind or 0
  ind1 = ind1 or ind
  assert (ind1 < w and ind < w,
          "the indents must be less than the line width")
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
end)


--- Write a number using SI suffixes.
-- The number is always written to 3 s.f.
-- @function numbertosi
-- @tparam number|string n any numeric value
-- @treturn string *n* simplifed using largest available SI suffix.
-- @usage print (numbertosi (bitspersecond) .. "bps")
export (M, "numbertosi (number|string)", function (n)
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
end)


--- Remove leading matter from a string.
-- @function ltrim
-- @string s any string
-- @string[opt="%s+"] r leading pattern
-- @treturn string *s* with leading *r* stripped
-- @usage print ("got: " .. ltrim (userinput))
export (M, "ltrim (string, string?)", function (s, r)
  r = r or "%s+"
  return s:gsub ("^" .. r, "")
end)


--- Remove trailing matter from a string.
-- @function rtrim
-- @string s any string
-- @string[opt="%s+"] r trailing pattern
-- @treturn string *s* with trailing *r* stripped
-- @usage print ("got: " .. rtrim (userinput))
export (M, "rtrim (string, string?)", function (s, r)
  r = r or "%s+"
  return s:gsub (r .. "$", "")
end)


--- Remove leading and trailing matter from a string.
-- @function trim
-- @string s any string
-- @string[opt="%s+"] r trailing pattern
-- @treturn string *s* with leading and trailing *r* stripped
-- @usage print ("got: " .. trim (userinput))
export (M, "trim (string, string?)", function (s, r)
  r = r or "%s+"
  return s:gsub ("^" .. r, ""):gsub (r .. "$", "")
end)


--- Stringification Functions
-- @section Stringification

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
-- @function render
-- @param x object to convert to string
-- @tparam render_open_table open open table rendering function
-- @tparam render_close_table close close table rendering function
-- @tparam render_element elem element rendering function
-- @tparam render_pair pair pair rendering function
-- @tparam render_separator sep separator rendering function
-- @tparam[opt] table roots accumulates table references to detect recursion
-- @return string representation of *x*
-- @usage
-- function tostring (x)
--   return render (x, mkterminal "{", mkterminal "}", string.tostring,
--                  function (_, _, _, i, v) return i .. "=" .. v end,
--                  mkterminal ",")
-- end
render = export (M, "render (any?, func, func, func, func, func, table?)",
function (x, open, close, elem, pair, sep, roots)
  open  = type (open)  == "string" and lambda (open)  or open
  close = type (close) == "string" and lambda (close) or close
  elem  = type (elem)  == "string" and lambda (elem)  or elem
  pair  = type (pair)  == "string" and lambda (pair)  or pair
  sep   = type (sep)   == "string" and lambda (sep)   or sep

  local function stop_roots (x)
    return roots[x] or render (x, open, close, elem, pair, sep, table.clone (roots))
  end
  roots = roots or {}
  if type (x) ~= "table" or getmetamethod (x, "__tostring") then
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
end)


--- Signature of render open table callback.
-- @function render_open_table
-- @tparam table t table about to be rendered
-- @treturn string open table rendering
-- @usage function open (t) return "{" end


--- Signature of render close table callback.
-- @function render_close_table
-- @tparam table t table just rendered
-- @treturn string close table rendering
-- @usage function close (t) return "}" end


--- Signature of render element callback.
-- @function render_element
-- @param x element to render
-- @treturn string element rendering
-- @usage function element (e) return require "string".tostring (e) end


--- Signature of render pair callback.
-- Trying to re-render *key* or *value* here will break recursion
-- detection, use *strkey* and *strvalue* pre-rendered values instead.
-- @function render_pair
-- @tparam table t table containing pair being rendered
-- @param key key part of key being rendered
-- @param value value part of key being rendered
-- @string keystr prerendered *key*
-- @string valuestr prerendered *value*
-- @treturn string pair rendering
-- @usage
-- function pair (_, _, _, key, value) return key .. "=" .. value end


--- Signature of render separator callback.
-- @function render_separator
-- @tparam table t table currently being renedered
-- @param pk *t* key preceding separator, or `nil` for first key
-- @param pv *t* value preceding separator, or `nil` for first value
-- @param fk *t* key following separator, or `nil` for last key
-- @param fv *t* value following separator, or `nil` for last value
-- @treturn string separator rendering
-- @usage function separator (t) return fk and "," or "" end


--- Extend `tostring` to render table contents as a string.
-- @function tostring
-- @param x object to convert to string
-- @treturn string compact string rendering of *x*
-- @usage
-- local tostring = require "std.string".tostring
-- print {foo="bar","baz"} --> {1=baz,foo=bar}
function M.tostring (x)
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


--- Pretty-print a table, or other object.
-- @param x object to convert to string
-- @string[opt="\t"] indent indent between levels
-- @string[opt=""] spacing space before every line
-- @treturn string pretty string rendering of *x*
-- @usage print (prettytostring (std, "  "))
export (M, "prettytostring (any?, string?, string?)",
function (x, indent, spacing)
  indent = indent or "\t"
  spacing = spacing or ""
  return render (x,
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
end)


--- Convert a value to a string.
-- The string can be passed to `functional.eval` to retrieve the value.
-- @todo Make it work for recursive tables.
-- @param x object to pickle
-- @treturn string reversible string rendering of *x*
-- @see functional.eval
-- @usage
-- function slow_identity (x) return functional.eval (pickle (x)) end
function M.pickle (x)
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
        s = s .. sep .. "[" .. M.pickle (i) .. "]=" .. M.pickle (v)
        sep = ","
      end
      s = s .. "}"
      return s
    else
      die ("cannot pickle " .. tostring (x))
    end
  end
end


for k, v in pairs (string) do
  M[k] = M[k] or v
end

return M
