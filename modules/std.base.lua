-- @module Base

import "std.table"
import "std.list"
import "std.string.string"
import "std.string.regex"


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

-- @func tostring: Extend tostring to work better on tables
--   @param x: object to convert to string
-- @returns
--   @param s: string representation
local _tostring = tostring
function tostring (x)
  if type (x) == "table" and (not metamethod (x, "__tostring")) then
    local s, sep = "{", ""
    for i, v in pairs (x) do
      s = s .. sep .. tostring (i) .. "=" .. tostring (v)
      sep = ","
    end
    s = s .. "}"
    return s
  else
    return _tostring (x)
  end
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
-- Does not work for recursive tables
--   @param x: object to pickle
-- @returns
--   @param s: string such that eval (s) is the same value as x
function pickle (x)
  if type (x) == "nil" then
    return "nil"
  elseif type (x) == "number" then
    return tostring (x)
  elseif type (x) == "string" then
    return format ("%q", x)
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
      die ("can't pickle " .. tostring (x))
    end
  end
end

-- @func id: Identity
--   @param x: object
-- @returns
--   @param x: same object
function id (x)
  return x
end

-- @func pack: Turn a tuple into a list
--   @param ...: tuple
-- @returns
--   @param l: list
function pack (...)
  return arg
end

-- @func curry: Partially apply a function
--   @param f: function to apply partially
--   @param a1 ... an: arguments to fix
-- @returns
--   @param g: function with ai fixed
function curry (f, ...)
  local fix = arg
  return function (...)
           return f (unpack (list.concat (fix, arg)))
         end
end

-- @func compose: Compose some functions
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
             arg = pack (fns[i] (unpack (arg)))
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
