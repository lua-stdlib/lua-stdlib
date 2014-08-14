--[[--
 Functional programming.

 A selection of higher-order functions to enable a functional style of
 programming in Lua.

 @module std.functional
]]


local base     = require "std.base"
local operator = require "std.operator"

local export, ireverse, len, pairs =
  base.export, base.ireverse, base.len, base.pairs

local M = { "std.functional" }



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


local function iscallable (x)
  if type (x) == "function" then return true end
  return type ((getmetatable (x) or {}).__call) == "function"
end



--[[ ================= ]]--
--[[ Module Functions. ]]--
--[[ ================= ]]--


--- Partially apply a function.
-- @function bind
-- @func fn function to apply partially
-- @tparam table argt {p1=a1, ..., pn=an} table of arguments to bind
-- @return function with *argt* arguments already bound
-- @usage
-- cube = bind (lambda "^", {[2] = 3})
local bind
bind = export (M, "bind (func, any?*)", function (fn, ...)
  local argt = {...}
  if type (argt[1]) == "table" and argt[2] == nil then
    argt = argt[1]
  else
    if not base.getcompat (bind) then
      io.stderr:write (base.DEPRECATIONMSG ("39",
                         "multi-argument 'std.functional.bind'",
                         "use a table of arguments as the second parameter instead", 2))
      base.setcompat (bind)
    end
  end

  return function (...)
           local arg = {}
           for i, v in pairs (argt) do
             arg[i] = v
           end
           local i = 1
           for _, v in pairs {...} do
             while arg[i] ~= nil do i = i + 1 end
             arg[i] = v
           end
           return fn (unpack (arg))
         end
end)


--- A rudimentary case statement.
-- Match *with* against keys in *branches* table.
-- @function case
-- @param with expression to match
-- @tparam table branches map possible matches to functions
-- @return the value associated with a matching key, or the first non-key
--   value if no key matches. Function or functable valued matches are
--   called using *with* as the sole argument, and the result of that call
--   returned; otherwise the matching value associated with the matching
--   key is returned directly; or else `nil` if there is no match and no
--   default.
-- @see cond
-- @usage
-- return case (type (object), {
--   table  = "table",
--   string = function ()  return "string" end,
--            function (s) error ("unhandled type: " .. s) end,
-- })
export (M, "case (any?, #table)", function (with, branches)
  local match = branches[with] or branches[1]
  if iscallable (match) then
    return match (with)
  end
  return match
end)


--- Collect the results of an iterator.
-- @function collect
-- @func ifn iterator function
-- @param ... iterator function arguments
-- @return results of running *ifn* on *arguments*
-- @see filter
-- @see map
-- @usage
-- --> {"c", "b", "a"}
-- collect (compose (std.ireverse, std.ielems), {"a", "b", "c"})
export (M, "collect (func, any*)", function (ifn, ...)
  local r = {}
  for k, v in ifn (...) do
    if v == nil then k, v = #r + 1, k end
    r[k] = v
  end
  return r
end)


--- Compose functions.
-- @function compose
-- @func ... functions to compose
-- @treturn function composition of fnN .. fn1: note that this is the
-- reverse of what you might expect, but means that code like:
--
--     functional.compose (function (x) return f (x) end,
--                         function (x) return g (x) end))
--
-- can be read from top to bottom.
-- @usage
-- vpairs = compose (table.invert, ipairs)
-- for v, i in vpairs {"a", "b", "c"} do process (v, i) end
local compose = export (M, "compose (func*)", function (...)
  local arg = {...}
  local fns, n = arg, #arg
  for i = 1, n do
    local f = fns[i]
  end

  return function (...)
           local arg = {...}
           for i = 1, n do
             arg = {fns[i] (unpack (arg))}
           end
           return unpack (arg)
         end
end)


--- A rudimentary condition-case statement.
-- If *expr* is "truthy" return *branch* if given, otherwise *expr*
-- itself. If the return value is a function or functable, then call it
-- with *expr* as the sole argument and return the result; otherwise
-- return it explicitly.  If *expr* is "falsey", then recurse with the
-- first two arguments stripped.
-- @function cond
-- @param expr a Lua expression
-- @param branch a function, functable or value to use if *expr* is
--   "truthy"
-- @param ... additional arguments to retry if *expr* is "falsey"
-- @see case
-- @usage
-- -- recursively calculate the nth triangular number
-- function triangle (n)
--   return cond (
--     n <= 0, 0,
--     n == 1, 1,
--             function () return n + triangle (n - 1) end)
-- end
M.cond = function (expr, branch, ...)
  if branch == nil and select ("#", ...) == 0 then
    expr, branch = true, expr
  end
  if expr then
    if iscallable (branch) then
      return branch (expr)
    end
    return branch
  end
  return M.cond (...)
end


--- Curry a function.
-- @function curry
-- @func fn function to curry
-- @int n number of arguments
-- @treturn function curried version of *fn*
-- @usage
-- add = curry (function (x, y) return x + y end, 2)
-- incr, decr = add (1), add (-1)
local curry
curry = export (M, "curry (func, int)", function (fn, n)
  if n <= 1 then
    return fn
  else
    return function (x)
             return curry (bind (fn, x), n - 1)
           end
  end
end)


--- Filter an iterator with a predicate.
-- @function filter
-- @tparam predicate pfn predicate function
-- @func ifn iterator function
-- @param ... iterator arguments
-- @treturn table elements e for which `pfn (e)` is not "falsey".
-- @see collect
-- @see map
-- @usage
-- --> {2, 4}
-- filter (lambda '|e|e%2==0', std.elems, {1, 2, 3, 4})
export (M, "filter (func, func, any*)", function (pfn, ifn, ...)
  local r = {}			-- new results table
  local nextfn, state, k = ifn (...)
  local t = {nextfn (state, k)}	-- table of iteration 1

  while t[1] ~= nil do		-- until iterator returns nil
    k = t[1]
    if pfn (unpack (t)) then	-- pass all iterator results to p
      if t[2] ~= nil then
	r[k] = t[2]		-- k,v = t[1],t[2]
      else
	r[#r + 1] = k		-- k,v = #r + 1,t[1]
      end
    end
    t = {nextfn (state, k)}	-- maintain loop invariant
  end
  return r
end)


--- Fold a binary function left associatively.
-- If parameter *d* is omitted, the first element of *t* is used,
-- and *t* treated as if it had been passed without that element.
-- @function foldl
-- @func fn binary function
-- @param[opt=t[1]] d initial left-most argument
-- @tparam table t a table
-- @return result
-- @see foldr
-- @see reduce
-- @usage
-- foldl (lambda "/", {10000, 100, 10}) == (10000 / 100) / 10
export (M, "foldl (function, [any], table)", base.functional.foldl)


--- Fold a binary function right associatively.
-- If parameter *d* is omitted, the last element of *t* is used,
-- and *t* treated as if it had been passed without that element.
-- @function foldr
-- @func fn binary function
-- @param[opt=t[1]] d initial right-most argument
-- @tparam table t a table
-- @return result
-- @see foldl
-- @see reduce
-- @usage
-- foldr (lambda "/", {10000, 100, 10}) == 10000 / (100 / 10)
export (M, "foldr (function, [any], table)", base.functional.foldr)


--- Identity function.
-- @function id
-- @param ... arguments
-- @return *arguments*
function M.id (...)
  return ...
end


--- Compile a lambda string into a Lua function.
--
-- A valid lambda string takes one of the following forms:
--
--   1. `'operator'`: where *op* is a key in @{std.operator}, equivalent to that operation
--   1. `'=expression'`: equivalent to `function (...) return (expression) end`
--   1. `'|args|expression'`: equivalent to `function (args) return (expression) end`
--
-- The second form (starting with `=`) automatically assigns the first
-- nine arguments to parameters `_1` through `_9` for use within the
-- expression body.
--
-- The results are memoized, so recompiling an previously compiled
-- lambda string is extremely fast.
-- @function lambda
-- @string s a lambda string
-- @treturn table compiled lambda string, can be called like a function
-- @usage
-- -- The following are all equivalent:
-- lambda '<'
-- lambda '= _1 < _2'
-- lambda '|a,b| a<b'
export (M, "lambda (string)", base.functional.memoize (function (s)
  local expr

  -- Support operator table lookup.
  if operator[s] then
    return operator[s]
  end

  -- Support "|args|expression" format.
  local args, body = s:match "^|([^|]*)|%s*(.+)$"
  if args and body then
    expr = "return function (" .. args .. ") return " .. body .. " end"
  end

  -- Support "=expression" format.
  if not expr then
    body = s:match "^=%s*(.+)$"
    if body then
      expr = [[
        return function (...)
          local _1,_2,_3,_4,_5,_6,_7,_8,_9 = unpack {...}
	  return ]] .. body .. [[
        end
      ]]
    end
  end

  local ok, fn
  if expr then
    ok, fn = pcall (loadstring (expr))
  end

  -- Diagnose invalid input.
  if not ok then
    return nil, "invalid lambda string '" .. s .. "'"
  end

  return fn
end, M.id))


--- Map a function over an iterator.
-- @function map
-- @func fn map function
-- @func ifn iterator function
-- @param ... iterator arguments
-- @treturn table results
-- @see filter
-- @see map_with
-- @usage
-- --> {1, 0, 1, 0}
-- map (lambda '=_1,_2%2', pairs, {1, 2, 3, 4})
local map = export (M, "map (func, func, any*)", function (fn, ifn, ...)
  local nextfn, state, k = ifn (...)
  local t = {nextfn (state, k)}

  local r = {}
  while t[1] ~= nil do
    k = t[1]
    local d, v = fn (unpack (t))
    if v == nil then d, v = #r + 1, d end
    if v ~= nil then
      r[d] = v
    end
    t = {nextfn (state, k)}
  end
  return r
end)


--- Map a function over a table of tables.
-- @function map_with
-- @func fn map function
-- @tparam table tt a table of tabulated *fn* arguments
-- @treturn table new table of *fn* results
-- @see map
-- @usage
-- --> {123, 45}
-- map_with (lambda '|...|table.concat {...}', {{1, 2, 3}, {4, 5}})
export (M, "map_with (function, table of tables)", function (fn, tt)
  local r = {}
  for k, v in pairs (tt) do
    r[k] = fn (unpack (v))
  end
  return r
end)


--- Memoize a function, by wrapping it in a functable.
--
-- To ensure that memoize always returns the same results for the same
-- arguments, it passes arguments to *fn*. You can specify a more
-- sophisticated function if memoize should handle complicated argument
-- equivalencies.
-- @function memoize
-- @func fn pure function: a function with no side effects
-- @tparam[opt=std.tostring] normalize normfn function to normalize arguments
-- @treturn functable memoized function
-- @usage
-- local fast = memoize (function (...) --[[ slow code ]] end)
export (M, "memoize (func, func?)", base.functional.memoize)


--- No operation.
-- This function ignores all arguments, and returns no values.
-- @function nop
-- @usage
-- if unsupported then vtable["memrmem"] = nop end
M.nop = base.functional.nop


--- Fold a binary function into an iterator.
-- @function reduce
-- @func fn reduce function
-- @param d initial first argument
-- @func ifn iterator function
-- @param ... iterator arguments
-- @return result
-- @see foldl
-- @see foldr
-- @usage
-- --> 2 ^ 3 ^ 4 ==> 4096
-- reduce (lambda '^', 2, std.ipairs, {3, 4})
export (M, "reduce (func, any, func, any*)", base.functional.reduce)


-- For backwards compatibility.
M.op = operator



--[[ ============= ]]--
--[[ Deprecations. ]]--
--[[ ============= ]]--


local DEPRECATED = base.DEPRECATED


M.eval = DEPRECATED ("41", "'std.functional.eval'",
  "use 'std.eval' instead", base.eval)


M.fold = DEPRECATED ("41", "'std.functional.fold'",
  "use 'std.functional.reduce' instead", base.functional.reduce)


return M



--- Types
-- @section Types


--- Signature of a @{memoize} argument normalization callback function.
-- @function normalize
-- @param ... arguments
-- @treturn string normalized arguments
-- @usage
-- local normalize = function (name, value, props) return name end
-- local intern = std.functional.memoize (mksymbol, normalize)


--- Signature of a @{filter} predicate callback function.
-- @function predicate
-- @param ... arguments
-- @treturn boolean "truthy" if the predicate condition succeeds,
--   "falsey" otherwise
-- @usage
-- local predicate = lambda '|k,v|type(v)=="string"'
-- local strvalues = filter (predicate, std.pairs, {name="Roberto", id=12345})
