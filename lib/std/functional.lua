--[[--
 Functional programming.
 @module std.functional
]]


local _ARGCHECK = require "std.debug_init"._ARGCHECK

local base = require "std.base"

local argcheck, argscheck = base.argcheck, base.argscheck

local functional -- forward declaration


--- Identity function.
-- @param ...
-- @return the arguments passed to the function
local function id (...)
  return ...
end


--- Partially apply a function.
-- @param f function to apply partially
-- @tparam t table {p1=a1, ..., pn=an} table of parameters to bind to given arguments
-- @return function with pi already bound
-- @usage
-- > cube = bind (math.pow, {[2] = 3})
-- > =cube (2)
-- 8
local function bind (f, ...)
  argscheck ("std.functional.bind", "function", f)

  local fix = {...} -- backwards compatibility with old API; DEPRECATED: remove in first release after 2015-04-21
  if type (fix[1]) == "table" and fix[2] == nil then
    fix = fix[1]
  end
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
end


--- A rudimentary case statement.
-- Match `with` against keys in `branches` table, and return the result
-- of running the function in the table value for the matching key, or
-- the first non-key value function if no key matches.
-- @param with expression to match
-- @tparam table branches map possible matches to functions
-- @return the return value from function with a matching key, or nil.
-- @usage
-- return case (type (object), {
--   table  = function ()  return something end,
--   string = function ()  return something else end,
--            function (s) error ("unhandled type: "..s) end,
-- })
local function case (with, branches)
  argcheck ("std.functional.case", 2, "#table", branches)

  local fn = branches[with] or branches[1]
  if fn then return fn (with) end
end


--- Curry a function.
-- @param f function to curry
-- @param n number of arguments
-- @return curried version of f
-- @usage
-- > add = curry (function (x, y) return x + y end, 2)
-- > incr, decr = add (1), add (-1)
-- > =incr (99), decr (99)
-- 100     98
local function curry (f, n)
  argscheck ("std.functional.curry", {"function", "int"}, {f, n})

  if n <= 1 then
    return f
  else
    return function (x)
             return curry (bind (f, x), n - 1)
           end
  end
end


--- Compose functions.
-- @tparam function ... functions to compose
-- @return composition of fn (... (f1) ...): note that this is the reverse
-- of what you might expect, but means that code like:
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
local function compose (...)
  local arg = {...}
  if _ARGCHECK then
    if #arg < 1 then
      argcheck ("std.functional.compose", 1, "function", nil)
    end
    for i in ipairs (arg) do
      argcheck ("std.functional.compose", i, "function", arg[i])
    end
  end

  local fns, n = arg, #arg
  return function (...)
           local arg = {...}
           for i = 1, n do
             arg = {fns[i] (unpack (arg))}
           end
           return unpack (arg)
         end
end


--- Signature of memoize `normalize` functions.
-- @function memoize_normalize
-- @param ... arguments
-- @treturn string normalized arguments


--- Memoize a function, by wrapping it in a functable.
--
-- To ensure that memoize always returns the same object for the same
-- arguments, it passes arguments to `normalize` (std.string.tostring
-- by default). You may need a more sophisticated function if memoize
-- should handle complicated argument equivalencies.
-- @param fn function that returns a single result
-- @param normalize[opt] function to normalize arguments
-- @return memoized function
-- @usage
-- local fast = memoize (function (...) --[[ slow code ]] end)
local function memoize (fn, normalize)
  argscheck ("std.functional.memoize", {"function", "function?"},
             {fn, normalize})

  if normalize == nil then
    -- Call require here, to avoid pulling in all of 'std.string'
    -- even when memoize is never called.
    local stringify = require "std.string".tostring
    normalize = function (...) return stringify {...} end
  end

  return setmetatable ({}, {
    __call = function (self, ...)
               local k = normalize (...)
               local v = self[k]
               if v == nil then
                 v = fn (...)
                 self[k] = v
               end
               return v
             end
  })
end


--- Evaluate a string.
-- @string s string of Lua code
-- @return result of evaluating `s`
-- @usage eval "math.pow (2, 10)"
local function eval (s)
  argscheck ("std.functional.eval", "string", s)
  return loadstring ("return " .. s)()
end


--- Collect the results of an iterator.
-- @tparam function i iterator
-- @param ... arguments
-- @return results of running the iterator on *arguments
-- @see filter
-- @see map
-- @usage
-- > =collect (std.list.relems, List {"a", "b", "c"})
-- {"c", "b", "a"}
local function collect (i, ...)
  argcheck ("std.functional.collect", 1, "function", i)

  local t = {}
  for e in i (...) do
    t[#t + 1] = e
  end
  return t
end


--- Map a function over an iterator.
-- @tparam function f function
-- @tparam function i iterator
-- @return result table
-- @see filter
-- @usage
-- > map (function (e) return e % 2 end, std.list.elems, List {1, 2, 3, 4})
-- {1, 0, 1, 0}
local function map (f, i, ...)
  argscheck ("std.functional.map", {"function", "function"}, {f, i})

  local t = {}
  for e in i (...) do
    local r = f (e)
    if r ~= nil then
      table.insert (t, r)
    end
  end
  return t
end


--- Filter an iterator with a predicate.
-- @param p predicate
-- @param i iterator
-- @return result table containing elements e for which p (e)
-- @see collect
-- @usage
-- > filter (function (e) return e % 2 == 0 end, std.list.elems, List {1, 2, 3, 4})
-- {2, 4}
local function filter (p, i, ...)
  argscheck ("std.functional.filter", {"function", "function"}, {p, i})

  local t = {}
  for e in i (...) do
    if p (e) then
      table.insert (t, e)
    end
  end
  return t
end


--- Fold a binary function into an iterator.
-- @param f function
-- @param d initial first argument
-- @param i iterator
-- @param ... iterator arguments
-- @return result
-- @see std.list.foldl
-- @see std.list.foldr
-- @usage fold (math.pow, 1, std.list.elems, List {2, 3, 4})
local function fold (f, d, i, ...)
  argscheck ("std.functional.fold", {"function", "any", "function"}, {f, d, i})

  local r = d
  for e in i (...) do
    r = f (r, e)
  end
  return r
end

--- @export
functional = {
  bind       = bind,
  case       = case,
  collect    = collect,
  compose    = compose,
  curry      = curry,
  eval       = eval,
  filter     = filter,
  fold       = fold,
  id         = id,
  map        = map,
  memoize    = memoize,
}

--- Functional forms of infix operators.
-- Defined here so that other modules can write to it.
-- @table op
-- @field [] dereference table index
-- @field + addition
-- @field - subtraction
-- @field * multiplication
-- @field / division
-- @field and logical and
-- @field or logical or
-- @field not logical not
-- @field == equality
-- @field ~= inequality
functional.op = {
  ["[]"]  = function (t, s) return t and t[s] or nil end,
  ["+"]   = function (a, b) return a + b   end,
  ["-"]   = function (a, b) return a - b   end,
  ["*"]   = function (a, b) return a * b   end,
  ["/"]   = function (a, b) return a / b   end,
  ["and"] = function (a, b) return a and b end,
  ["or"]  = function (a, b) return a or b  end,
  ["not"] = function (a)    return not a   end,
  ["=="]  = function (a, b) return a == b  end,
  ["~="]  = function (a, b) return a ~= b  end,
}

return functional
