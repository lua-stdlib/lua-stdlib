-- @module Base

require "std.table"
require "std.list"
require "std.string.string"
require "std.string.regex"


-- @func metamethod: Return given metamethod, if any, or nil
--   @param x: object to get metamethod of
--   @param n: name of metamethod to get
-- @returns
--   @param m: metamethod function or nil if no metamethod or not a
--     function
function metamethod (x, n)
  local _, m = pcall (function (x)
                        return getmetatable (x)[n]
                      end,
                      x)
  if type (m) ~= "function" then
    m = nil
  end
  return m
end

-- @func render: Turn tables into strings with recursion detection
-- N.B. Functions calling render should not recurse, or recursion
-- detection will not work
--   @param x: object to convert to string
--   @param open: open table renderer
--     @t: table
--   @returns
--     @s: open table string
--   @param close: close table renderer
--     @t: table
--   @returns
--     @s: close table string
--   @param elem: element renderer
--     @e: element
--   @returns
--     @s: element string
--   @param pair: pair renderer
--     N.B. this function should not try to render i and v, or treat
--     them recursively
--     @t: table
--     @i: index
--     @v: value
--     @is: index string
--     @vs: value string
--   @returns
--     @s: element string
--   @param sep: separator renderer
--     @t: table
--     @i: preceding index (nil on first call)
--     @v: preceding value (nil on first call)
--     @j: following index (nil on last call)
--     @w: following value (nil on last call)
--   @returns
--     @s: separator string
-- @returns
--   @param s: string representation
function render (x, open, close, elem, pair, sep, roots)
  local function stopRoots (x)
    if roots[x] then
      return roots[x]
    else
      return render (x, open, close, elem, pair, sep, table.clone (roots))
    end
  end
  roots = roots or {}
  local s
  if type (x) ~= "table" or metamethod (x, "__tostring") then
    s = elem (x)
  else
    s = open (x)
    roots[x] = elem (x)
    local i, v = nil, nil
    for j, w in pairs (x) do
      s = s .. sep (x, i, v, j, w) .. pair (x, j, w, stopRoots (j), stopRoots (w))
      i, v = j, w
    end
    s = s .. sep(x, i, v, nil, nil) .. close (x)
  end
  return s
end

-- @func tostring: Extend tostring to work better on tables
--   @param x: object to convert to string
-- @returns
--   @param s: string representation
local _tostring = tostring
function tostring (x)
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

-- @func print: Make print use tostring, so that improvements to tostring
-- are picked up
--   @param arg: objects to print
local _print = print
function print (...)
  for i, v in ipairs (arg) do
    arg[i] = tostring (v)
  end
  _print (unpack (arg))
end

-- @func prettytostring: pretty-print a table
--   @t: table to print
--   @indent: indent between levels ["\t"]
--   @spacing: space before every line
-- @returns
--   @s: pretty-printed string
function prettytostring (t, indent, spacing)
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
                     return string.format ("%q", x)
                   else
                     return tostring (x)
                   end
                 end,
                 function (x, i, v, is, vs)
                   local s = spacing .. "["
                   if type (i) == "table" then
                     s = s .. "\n"
                   end
                   s = s .. is
                   if type (i) == "table" then
                     s = s .. "\n"
                   end
                   s = s .. "] ="
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

-- @func totable: Turn an object into a table according to __totable
-- metamethod
--   @param x: object to turn into a table
-- @returns
--   @param t: table or nil
function totable (x)
  local m = metamethod (x, "__totable")
  if m then
    return m (x)
  elseif type (x) == "table" then
    return x
  else
    return nil
  end
end

-- @func pickle: Convert a value to a string
-- The string can be passed to dostring to retrieve the value
-- FIXME: Make it work for recursive tables
--   @param x: object to pickle
-- @returns
--   @param s: string such that eval (s) is the same value as x
function pickle (x)
  if type (x) == "string" then
    return string.format ("%q", x)
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

-- @func id: Identity
--   @param ...
-- @returns
--   @param ...: the arguments passed to the function
function id (...)
  return unpack (arg)
end

-- @func pack: Turn a tuple into a list
--   @param ...: tuple
-- @returns
--   @param l: list
function pack (...)
  return arg
end

-- @func bind: Partially apply a function
--   @param f: function to apply partially
--   @param a1 ... an: arguments to bind
-- @returns
--   @param g: function with ai already bound
function bind (f, ...)
  local fix = arg
  return function (...)
           return f (unpack (list.concat (fix, arg)))
         end
end

-- @func curry: Curry a function
--   @param f: function to curry
--   @param n: number of arguments
-- @returns
--   @param g: curried version of f
function curry (f, n)
  if n <= 1 then
    return f
  else
    return function (x)
             return curry (bind (f, x), n - 1)
           end
  end
end

-- @func compose: Compose functions
--   @param f1 ... fn: functions to compose
-- @returns
--   @param g: composition of f1 ... fn
--     @param args: arguments
--   @returns
--     @param f1 (...fn (args)...)
function compose (...)
  local fns, n = arg, table.getn (arg)
  return function (...)
           for i = n, 1, -1 do
             arg = {fns[i] (unpack (arg))}
           end
           return unpack (arg)
         end
end

-- @func eval: Evaluate a string
--   @param s: string
-- @returns
--   @param v: value of string
function eval (s)
  return loadstring ("return " .. s)()
end

-- @func ripairs: An iterator like ipairs, but in reverse
--   @param t: table to iterate over
-- @returns
--   @param f: iterator function
--     @param t: table
--     @param n: index
--   @returns
--     @param i: index (n - 1)
--     @param v: value (t[n - 1))
--   @param t: the table, as above
--   @param n: table.getn (t) + 1
function ripairs (t)
  return function (t, n)
           n = n - 1
           if n == 0 then
             n = nil
           else
             return n, t[n]
           end
         end,
  t, table.getn (t) + 1
end

-- TODO: Fix this to allow rebuilding the table (currently flattens
-- it)
-- @func deepipairs: Like ipairs, but recurse into nested tables
--   @param t: table to iterate over
-- @returns
--   @param f: iterator function
--     @param t: table
--     @param n: index
--   @returns
--     @param i: index (n - 1)
--     @param v: value (t[n - 1))
--   @param t: the table, as above
--   @param n: table.getn (t) + 1
function deepipairs (t)
  return coroutine.wrap (function ()
                           for i, v in ipairs (t) do
                             if type (v) ~= "table" then
                               coroutine.yield (i, v)
                             else
                               for j, w in deepipairs (v) do
                                 coroutine.yield (j, w)
                               end
                             end
                           end
                         end)
end

-- @func listable: Make a function which can take its arguments
-- as a list
--   @param f: function (if it only takes one argument, it must not be
--     a table)
-- @returns
--   @param g: function that can take its arguments either as normal
--     or in a list
function listable (f)
  return function (...)
           if table.getn (arg) == 1 and type (arg[1]) == "table" then
             return f (unpack (arg[1]))
           else
             return f (unpack (arg))
           end
         end
end

-- @func pathSubscript: Subscript a table with a string containing
-- dots
--   @param t: table
--   @param s: subscript of the form s1.s2. ... .sn
-- @returns
--   @param v: t.s1.s2. ... .sn
function pathSubscript (t, s)
  return lookup (t, string.split ("%.", s))
end

-- @func lookup: Do a late-bound table lookup
--   @param t: table to look up in
--   @param l: list of indices {l1 ... ln}
-- @returns
--   @param u: t[l1] ... [ln]
function lookup (t, l)
  return list.foldl (table.subscript, t, l)
end
