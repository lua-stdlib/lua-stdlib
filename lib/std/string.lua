--[[--
 Additions to the core string module.

 The module table returned by `std.string` also contains all of the entries
 from the core string table.  An hygienic way to import this module, then, is
 simply to override the core `string` locally:

    local string = require "std.string"

 @module std.string
]]

local base   = require "std.base"
local debug  = require "std.debug"

local StrBuf = require "std.strbuf" {}

local copy          = base.copy
local getmetamethod = base.getmetamethod
local insert, len   = base.insert, base.len
local pairs         = base.pairs
local render        = base.render

local M



local _tostring = base.tostring

local function __concat (s, o)
  return _tostring (s) .. _tostring (o)
end


local function __index (s, i)
  if type (i) == "number" then
    return s:sub (i, i)
  else
    -- Fall back to module metamethods
    return M[i]
  end
end


local _format   = string.format

local function format (f, arg1, ...)
  return (arg1 ~= nil) and _format (f, arg1, ...) or f
end


local function tpack (from, to, ...)
  return from, to, {...}
end

local function tfind (s, ...)
  return tpack (s:find (...))
end


local function finds (s, p, i, ...)
  i = i or 1
  local l = {}
  local from, to, r
  repeat
    from, to, r = tfind (s, p, i, ...)
    if from ~= nil then
      insert (l, {from, to, capt = r})
      i = to + 1
    end
  until not from
  return l
end


local function monkey_patch (namespace)
  namespace = namespace or _G
  namespace.string = base.copy (namespace.string or {}, M)

  local string_metatable = getmetatable ""
  string_metatable.__concat = M.__concat
  string_metatable.__index = M.__index

  return M
end


local function caps (s)
  return (s:gsub ("(%w)([%w]*)", function (l, ls) return l:upper () .. ls end))
end


local function escape_shell (s)
  return (s:gsub ("([ %(%)%\\%[%]\"'])", "\\%1"))
end


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


local function pad (s, w, p)
  p = string.rep (p or " ", math.abs (w))
  if w < 0 then
    return string.sub (p .. s, w)
  end
  return string.sub (s .. p, 1, w)
end


local function wrap (s, w, ind, ind1)
  w = w or 78
  ind = ind or 0
  ind1 = ind1 or ind
  assert (ind1 < w and ind < w,
          "the indents must be less than the line width")
  local r = StrBuf { string.rep (" ", ind1) }
  local i, lstart, lens = 1, ind1, len (s)
  while i <= lens do
    local j = i + w - lstart
    while len (s[j]) > 0 and s[j] ~= " " and j > i do
      j = j - 1
    end
    local ni = j + 1
    while s[j] == " " do
      j = j - 1
    end
    r:concat (s:sub (i, j))
    i = ni
    if i < lens then
      r:concat ("\n" .. string.rep (" ", ind))
      lstart = ind
    end
  end
  return r:tostring ()
end


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
  return format ("%0.f", man) .. s
end


local function trim (s, r)
  r = r or "%s+"
  return (s:gsub ("^" .. r, ""):gsub (r .. "$", ""))
end


local function prettytostring (x, indent, spacing)
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
                 function (x, k, v, ks, vs)
                   local s = spacing
		   if type (k) ~= "string" or k:match "[^%w_]" then
		     s = s .. "["
                     if type (k) == "table" then
                       s = s .. "\n"
                     end
                     s = s .. ks
                     if type (k) == "table" then
                       s = s .. "\n"
                     end
                     s = s .. "]"
		   else
		     s = s .. k
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
                 function (_, k)
                   local s = "\n"
                   if k then
                     s = "," .. s
                   end
                   return s
                 end)
end


local function pickle (x)
  if type (x) == "string" then
    return format ("%q", x)
  elseif type (x) == "number" or type (x) == "boolean" or
    type (x) == "nil" then
    return tostring (x)
  else
    x = copy (x) or x
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



--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


local function X (decl, fn)
  return debug.argscheck ("std.string." .. decl, fn)
end

M = {
  --- String concatenation operation.
  -- @string s initial string
  -- @param o object to stringify and concatenate
  -- @return s .. tostring (o)
  -- @usage
  -- local string = require "std.string".monkey_patch ()
  -- concatenated = "foo" .. {"bar"}
  __concat = __concat,

  --- String subscript operation.
  -- @string s string
  -- @tparam int|string i index or method name
  -- @return `s:sub (i, i)` if i is a number, otherwise
  --   fall back to a `std.string` metamethod (if any).
  -- @usage
  -- getmetatable ("").__index = require "std.string".__index
  -- third = ("12345")[3]
  __index = __index,

  --- Capitalise each word in a string.
  -- @function caps
  -- @string s any string
  -- @treturn string *s* with each word capitalized
  -- @usage userfullname = caps (input_string)
  caps = X ("caps (string)", caps),

  --- Remove any final newline from a string.
  -- @function chomp
  -- @string s any string
  -- @treturn string *s* with any single trailing newline removed
  -- @usage line = chomp (line)
  chomp = X ("chomp (string)", function (s) return (s:gsub ("\n$", "")) end),

  --- Escape a string to be used as a pattern.
  -- @function escape_pattern
  -- @string s any string
  -- @treturn string *s* with active pattern characters escaped
  -- @usage substr = inputstr:match (escape_pattern (literal))
  escape_pattern = X ("escape_pattern (string)", base.escape_pattern),

  --- Escape a string to be used as a shell token.
  -- Quotes spaces, parentheses, brackets, quotes, apostrophes and
  -- whitespace.
  -- @function escape_shell
  -- @string s any string
  -- @treturn string *s* with active shell characters escaped
  -- @usage os.execute ("echo " .. escape_shell (outputstr))
  escape_shell = X ("escape_shell (string)", escape_shell),

  --- Repeatedly `string.find` until target string is exhausted.
  -- @function finds
  -- @string s target string
  -- @string pattern pattern to match in *s*
  -- @int[opt=1] init start position
  -- @bool[opt] plain inhibit magic characters
  -- @return list of `{from, to; capt = {captures}}`
  -- @see std.string.tfind
  -- @usage
  -- for t in std.elems (finds ("the target string", "%S+")) do
  --   print (tostring (t.capt))
  -- end
  finds = X ("finds (string, string, ?int, ?boolean|:plain)", finds),

  --- Extend to work better with one argument.
  -- If only one argument is passed, no formatting is attempted.
  -- @function format
  -- @string f format string
  -- @param[opt] ... arguments to format
  -- @return formatted string
  -- @usage print (format "100% stdlib!")
  format = X ("format (string, [any...])", format),

  --- Remove leading matter from a string.
  -- @function ltrim
  -- @string s any string
  -- @string[opt="%s+"] r leading pattern
  -- @treturn string *s* with leading *r* stripped
  -- @usage print ("got: " .. ltrim (userinput))
  ltrim = X ("ltrim (string, ?string)",
             function (s, r) return (s:gsub ("^" .. (r or "%s+"), "")) end),

  --- Overwrite core `string` methods with `std` enhanced versions.
  --
  -- Also adds auto-stringification to `..` operator on core strings, and
  -- integer indexing of strings with `[]` dereferencing.
  -- @function monkey_patch
  -- @tparam[opt=_G] table namespace where to install global functions
  -- @treturn table the module table
  -- @usage local string = require "std.string".monkey_patch ()
  monkey_patch = X ("monkey_patch (?table)", monkey_patch),

  --- Write a number using SI suffixes.
  -- The number is always written to 3 s.f.
  -- @function numbertosi
  -- @tparam number|string n any numeric value
  -- @treturn string *n* simplifed using largest available SI suffix.
  -- @usage print (numbertosi (bitspersecond) .. "bps")
  numbertosi = X ("numbertosi (number|string)", numbertosi),

  --- Return the English suffix for an ordinal.
  -- @function ordinal_suffix
  -- @tparam int|string n any integer value
  -- @treturn string English suffix for *n*
  -- @usage
  -- local now = os.date "*t"
  -- print ("%d%s day of the week", now.day, ordinal_suffix (now.day))
  ordinal_suffix = X ("ordinal_suffix (int|string)", ordinal_suffix),

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
  pad = X ("pad (string, int, ?string)", pad),

  --- Convert a value to a string.
  -- The string can be passed to `functional.eval` to retrieve the value.
  -- @todo Make it work for recursive tables.
  -- @param x object to pickle
  -- @treturn string reversible string rendering of *x*
  -- @see std.eval
  -- @usage
  -- function slow_identity (x) return functional.eval (pickle (x)) end
  pickle = pickle,

  --- Pretty-print a table, or other object.
  -- @function prettytostring
  -- @param x object to convert to string
  -- @string[opt="\t"] indent indent between levels
  -- @string[opt=""] spacing space before every line
  -- @treturn string pretty string rendering of *x*
  -- @usage print (prettytostring (std, "  "))
  prettytostring = X ("prettytostring (?any, ?string, ?string)", prettytostring),

  --- Turn tables into strings with recursion detection.
  -- N.B. Functions calling render should not recurse, or recursion
  -- detection will not work.
  -- @function render
  -- @param x object to convert to string
  -- @tparam opentablecb open open table rendering function
  -- @tparam closetablecb close close table rendering function
  -- @tparam elementcb elem element rendering function
  -- @tparam paircb pair pair rendering function
  -- @tparam separatorcb sep separator rendering function
  -- @tparam[opt] table roots accumulates table references to detect recursion
  -- @return string representation of *x*
  -- @usage
  -- function tostring (x)
  --   return render (x, lambda '="{"', lambda '="}"', tostring,
  --                  lambda '=_4.."=".._5', lambda '= _4 and "," or ""',
  --                  lambda '=","')
  -- end
  render = X ("render (?any, func, func, func, func, func, ?table)", render),

  --- Remove trailing matter from a string.
  -- @function rtrim
  -- @string s any string
  -- @string[opt="%s+"] r trailing pattern
  -- @treturn string *s* with trailing *r* stripped
  -- @usage print ("got: " .. rtrim (userinput))
  rtrim = X ("rtrim (string, ?string)",
             function (s, r) return (s:gsub ((r or "%s+") .. "$", "")) end),

  --- Split a string at a given separator.
  -- Separator is a Lua pattern, so you have to escape active characters,
  -- `^$()%.[]*+-?` with a `%` prefix to match a literal character in *s*.
  -- @function split
  -- @string s to split
  -- @string[opt="%s+"] sep separator pattern
  -- @return list of strings
  -- @usage words = split "a very short sentence"
  split = X ("split (string, ?string)", base.split),

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
  tfind = X ("tfind (string, string, ?int, ?boolean|:plain)", tfind),

  --- Remove leading and trailing matter from a string.
  -- @function trim
  -- @string s any string
  -- @string[opt="%s+"] r trailing pattern
  -- @treturn string *s* with leading and trailing *r* stripped
  -- @usage print ("got: " .. trim (userinput))
  trim = X ("trim (string, ?string)", trim),

  --- Wrap a string into a paragraph.
  -- @function wrap
  -- @string s a paragraph of text
  -- @int[opt=78] w width to wrap to
  -- @int[opt=0] ind indent
  -- @int[opt=ind] ind1 indent of first line
  -- @treturn string *s* wrapped to *w* columns
  -- @usage
  -- print (wrap (copyright, 72, 4))
  wrap = X ("wrap (string, ?int, ?int, ?int)", wrap),
}



--[[ ============= ]]--
--[[ Deprecations. ]]--
--[[ ============= ]]--


local DEPRECATED = debug.DEPRECATED


M.assert = DEPRECATED ("41", "'std.string.assert'",
  "use 'std.assert' instead", base.assert)


M.require_version = DEPRECATED ("41", "'std.string.require_version'",
  "use 'std.require' instead", base.require)


M.tostring = DEPRECATED ("41", "'std.string.tostring'",
  "use 'std.tostring' instead", base.tostring)



return base.merge (M, string)



--- Types
-- @section Types

--- Signature of @{render} open table callback.
-- @function opentablecb
-- @tparam table t table about to be rendered
-- @treturn string open table rendering
-- @see render
-- @usage function open (t) return "{" end


--- Signature of @{render} close table callback.
-- @function closetablecb
-- @tparam table t table just rendered
-- @treturn string close table rendering
-- @see render
-- @usage function close (t) return "}" end


--- Signature of @{render} element callback.
-- @function elementcb
-- @param x element to render
-- @treturn string element rendering
-- @see render
-- @usage function element (e) return require "std".tostring (e) end


--- Signature of @{render} pair callback.
-- Trying to re-render *key* or *value* here will break recursion
-- detection, use *strkey* and *strvalue* pre-rendered values instead.
-- @function paircb
-- @tparam table t table containing pair being rendered
-- @param key key part of key being rendered
-- @param value value part of key being rendered
-- @string keystr prerendered *key*
-- @string valuestr prerendered *value*
-- @treturn string pair rendering
-- @see render
-- @usage
-- function pair (_, _, _, key, value) return key .. "=" .. value end


--- Signature of @{render} separator callback.
-- @function separatorcb
-- @tparam table t table currently being rendered
-- @param pk *t* key preceding separator, or `nil` for first key
-- @param pv *t* value preceding separator, or `nil` for first value
-- @param fk *t* key following separator, or `nil` for last key
-- @param fv *t* value following separator, or `nil` for last value
-- @treturn string separator rendering
-- @usage
-- function separator (_, _, _, fk) return fk and "," or "" end
