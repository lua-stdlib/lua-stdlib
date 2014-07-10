--[[--
 Functional programming.

 A selection of higher-order functions to enable a functional style of
 programming in Lua.

 Of special note is the `lambda` function: when calling other stdlib apis
 that accept a function argument, the call to `lambda` itself is not
 required.  The following are equivalent:

    std.table.sort (t, lambda '|a,b| a<b')
    std.table.sort (t, '|a,b| a<b')

 In the latter case, `sort` will recognize and expand a valid "lambda
 string" without an explicit `lambda` invocation.  If argument checking is
 not disabled (see @{debug._DEBUG}), invalid lambda strings passed in lieu
 of a Lua function raise a "function expected, got string" error.

 @module std.functional
]]


local base     = require "std.base"

local export, lambda, nop = base.export, base.lambda, base.nop

local M = { "std.functional" }



--- Partially apply a function.
-- @function bind
-- @func f function to apply partially
-- @tparam table t {p1=a1, ..., pn=an} table of parameters to bind to given arguments
-- @return function with *pi* already bound
-- @usage
-- > cube = bind (math.pow, {[2] = 3})
-- > =cube (2)
-- 8
local bind = export (M, "bind (func, any?*)", function (f, ...)
  local fix = {...} -- backwards compatibility with old API; DEPRECATED: remove in first release after 2015-04-21
  if type (fix[1]) == "table" and fix[2] == nil then
    fix = fix[1]
  end
  f = type (f) == "string" and lambda (f) or f

  return function (...)
           local arg = {}
           for i, v in pairs (fix) do
             arg[i] = v
           end
           local i = 1
           for _, v in pairs {...} do
             while arg[i] ~= nil do i = i + 1 end
             arg[i] = v
           end
           return f (unpack (arg))
         end
end)


--- A rudimentary case statement.
-- Match `with` against keys in `branches` table, and return the result
-- of running the function in the table value for the matching key, or
-- the first non-key value function if no key matches.
-- @function case
-- @param with expression to match
-- @tparam table branches map possible matches to functions
-- @return the return value from function with a matching key, or nil.
-- @usage
-- return case (type (object), {
--   table  = function ()  return something end,
--   string = function ()  return something else end,
--            function (s) error ("unhandled type: "..s) end,
-- })
export (M, "case (any?, #table)", function (with, branches)
  local f = branches[with] or branches[1]
  f = type (f) == "string" and lambda (f) or f
  if f then return f (with) end
end)


--- Collect the results of an iterator.
-- @function collect
-- @func i iterator
-- @param ... iterator arguments
-- @return results of running the iterator on *arguments*
-- @see filter
-- @see map
-- @usage
-- > =collect (std.list.relems, List {"a", "b", "c"})
-- {"c", "b", "a"}
export (M, "collect (func, any*)", function (i, ...)
  i = type (i) == "string" and lambda (i) or i

  local t = {}
  for e in i (...) do
    t[#t + 1] = e
  end
  return t
end)


--- Compose functions.
-- @function compose
-- @func ... functions to compose
-- @treturn function composition of fn (... (f1) ...): note that this is the
-- reverse of what you might expect, but means that code like:
--
--     functional.compose (function (x) return f (x) end,
--                         function (x) return g (x) end))
--
-- can be read from top to bottom.
-- @usage
-- > vpairs = compose (table.invert, pairs)
-- > for v in vpairs {"a", "b", "c"} do print (v) end
-- b
-- c
-- a
export (M, "compose (func*)", function (...)
  local arg = {...}
  local fns, n = arg, #arg
  for i = 1, n do
    local f = fns[i]
    fns[i] = type (f) == "string" and lambda (f) or f
  end

  return function (...)
           local arg = {...}
           for i = 1, n do
             arg = {fns[i] (unpack (arg))}
           end
           return unpack (arg)
         end
end)


--- Curry a function.
-- @function curry
-- @func f function to curry
-- @int n number of arguments
-- @treturn function curried version of *f*
-- @usage
-- > add = curry (function (x, y) return x + y end, 2)
-- > incr, decr = add (1), add (-1)
-- > =incr (99), decr (99)
-- 100     98
local curry
curry = export (M, "curry (func, int)", function (f, n)
  f = type (f) == "string" and lambda (f) or f

  if n <= 1 then
    return f
  else
    return function (x)
             return curry (bind (f, x), n - 1)
           end
  end
end)


--- Evaluate a string.
-- @function eval
-- @string s string of Lua code
-- @return result of evaluating `s`
-- @usage eval "math.pow (2, 10)"
local eval = export (M, "eval (string)", function (s)
  return loadstring ("return " .. s)()
end)


--- Filter an iterator with a predicate.
-- @function filter
-- @func p predicate
-- @func i iterator
-- @param ... iterator arguments
-- @treturn table elements e for which `p (e)` is not falsey.
-- @see collect
-- @usage
-- > filter ("|e| e%2==0", std.list.elems, List {1, 2, 3, 4})
-- {2, 4}
export (M, "filter (func, func, any*)", function (p, i, ...)
  p = type (p) == "string" and lambda (p) or p
  i = type (i) == "string" and lambda (i) or i

  local t = {}
  for e in i (...) do
    if p (e) then
      table.insert (t, e)
    end
  end
  return t
end)


--- Fold a binary function into an iterator.
-- @function fold
-- @func f function
-- @param d initial first argument
-- @func i iterator
-- @param ... iterator arguments
-- @return result
-- @see std.list.foldl
-- @see std.list.foldr
-- @usage fold (math.pow, 1, std.list.elems, List {2, 3, 4})
export (M, "fold (func, any, func, any*)", function (f, d, i, ...)
  f = type (f) == "string" and lambda (f) or f
  i = type (i) == "string" and lambda (i) or i

  local r = d
  for e in i (...) do
    r = f (r, e)
  end
  return r
end)


--- Identity function.
-- @function id
-- @param ...
-- @return the arguments passed to the function
function M.id (...)
  return ...
end


--- Map a function over an iterator.
-- @function map
-- @func f function
-- @func i iterator
-- @param ... iterator arguments
-- @treturn table results
-- @see filter
-- @usage
-- > map (function (e) return e % 2 end, std.list.elems, List {1, 2, 3, 4})
-- {1, 0, 1, 0}
export (M, "map (func, func, any*)", function (f, i, ...)
  f = type (f) == "string" and lambda (f) or f
  i = type (i) == "string" and lambda (i) or i

  local t = {}
  for e in i (...) do
    local r = f (e)
    if r ~= nil then
      table.insert (t, r)
    end
  end
  return t
end)


--- Memoize a function, by wrapping it in a functable.
--
-- To ensure that memoize always returns the same results for the same
-- arguments, it passes arguments to `normalize` (std.string.tostring
-- by default). You can specify a more sophisticated function if memoize
-- should handle complicated argument equivalencies.
-- @function memoize
-- @func fn function with no side effects
-- @func normalize[opt] function to normalize arguments
-- @treturn functable memoized function
-- @usage
-- local fast = memoize (function (...) --[[ slow code ]] end)
local memoize = export (M, "memoize (func, func?)", function (fn, normalize)
  fn = type (fn) == "string" and lambda (fn) or fn
  normalize = type (normalize) == "string" and lambda (normalize) or normalize

  if normalize == nil then
    -- Call require here, to avoid pulling in all of 'std.string'
    -- even when memoize is never called.
    local stringify = require "std.string".tostring
    normalize = function (...) return stringify {...} end
  end

  return setmetatable ({}, {
    __call = function (self, ...)
               local k = normalize (...)
               local t = self[k]
               if t == nil then
                 t = {fn (...)}
                 self[k] = t
               end
               return unpack (t)
             end
  })
end)


--- Signature of memoize `normalize` functions.
-- @function memoize_normalize
-- @param ... arguments
-- @treturn string normalized arguments


--- A compiled lambda string returned by @{lambda}.
--
-- @{lambda} returns a functable with this signature, which has a
-- metatable that returns `value` when passed to @{tostring} and
-- can be called like any other function.
-- @table Lambda
-- @func call compiled Lua function
-- @string value original lambda string
-- @see string.tostring
-- @see object.prototype
-- @usage
-- -- Core Lua apis accept a function, but not a functable
-- table.sort (t, (lambda "<").call)


--- Compile a lambda string into a Lua function.
--
-- A valid lambda string takes one of the following forms:
--
--   1. `operator`: where *op* is a key in @{std.operator}, equivalent to that operation
--   1. `"=expression"`: equivalent to `function (...) return (expression) end`
--   1. `"|args|expression"`: equivalent to `function (args) return (expression) end`
--
-- The second form (starting with `=`) automatically assigns the first
-- nine arguments to parameters `_1` through `_9` for use within the
-- expression body.
-- @function lambda
-- @string s a lambda string
-- @treturn table compiled lambda string, can be called like a function
-- @usage
-- -- The following are all equivalent:
-- lambda "<"
-- lambda "= _1 < _2"
-- lambda "|a,b| a<b"
export (M, "lambda (string)", memoize (lambda, function (s) return s end))


--- No operation.
-- This function ignores all arguments, and returns no values.
-- @function nop
-- @usage
-- if unsupported then vtable["memrmem"] = nop end
M.nop = nop


-- For backwards compatibility.
M.op = require "std.operator"


return M
