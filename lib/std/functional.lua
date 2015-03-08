--[[--
 Functional programming.

 A selection of higher-order functions to enable a functional style of
 programming in Lua.

 @module std.functional
]]


local base     = require "std.base"
local debug    = require "std.debug"

local ielems, ipairs, ireverse, npairs, pairs =
  base.ielems, base.ipairs, base.ireverse, base.npairs, base.pairs
local callable, copy, len, reduce, unpack =
  base.callable, base.copy, base.len, base.reduce, base.unpack
local loadstring = loadstring or load


local function bind (fn, ...)
  local bound = {...}
  if type (bound[1]) == "table" and bound[2] == nil then
    bound = bound[1]
  else
    io.stderr:write (debug.DEPRECATIONMSG ("39",
                       "multi-argument 'std.functional.bind'",
                       "use a table of arguments as the second parameter instead", 2))
  end

  return function (...)
    local argt, i = copy (bound), 1
    for _, v in npairs {...} do
      while argt[i] ~= nil do i = i + 1 end
      argt[i], i = v, i + 1
    end
    return fn (unpack (argt))
  end
end


local function case (with, branches)
  local match = branches[with] or branches[1]
  if callable (match) then
    return match (with)
  end
  return match
end


local function compose (...)
  local fns = {...}

  return function (...)
    local argt = {...}
    for _, fn in npairs (fns) do
      argt = {fn (unpack (argt))}
    end
    return unpack (argt)
  end
end


local function cond (expr, branch, ...)
  if branch == nil and select ("#", ...) == 0 then
    expr, branch = true, expr
  end
  if expr then
    if callable (branch) then
      return branch (expr)
    end
    return branch
  end
  return cond (...)
end


local function curry (fn, n)
  if n <= 1 then
    return fn
  else
    return function (x)
             return curry (bind (fn, x), n - 1)
           end
  end
end


local function filter (pfn, ifn, ...)
  local argt, r = {...}, {}
  if not callable (ifn) then
    ifn, argt = pairs, {ifn, ...}
  end

  local nextfn, state, k = ifn (unpack (argt))

  local t = {nextfn (state, k)}	-- table of iteration 1
  local arity = #t		-- How many return values from ifn?

  if arity == 1 then
    local v = t[1]
    while v ~= nil do		-- until iterator returns nil
      if pfn (unpack (t)) then	-- pass all iterator results to p
        r[#r + 1] = v
      end

      t = {nextfn (state, v)}	-- maintain loop invariant
      v = t[1]

      if #t > 1 then		-- unless we discover arity is not 1 after all
        arity, r = #t, {} break
      end
    end
  end

  if arity > 1 then
    -- No need to start over here, because either:
    --   (i) arity was never 1, and the original value of t is correct
    --  (ii) arity used to be 1, but we only consumed nil values, so the
    --       current t with arity > 1 is the correct next value to use
    while t[1] ~= nil do
      local k = t[1]
      if pfn (unpack (t)) then r[k] = t[2] end
      t = {nextfn (state, k)}
    end
  end

  return r
end


local function foldl (fn, d, t)
  if t == nil then
    local tail = {}
    for i = 2, len (d) do tail[#tail + 1] = d[i] end
    d, t = d[1], tail
  end
  return reduce (fn, d, ielems, t)
end


local function foldr (fn, d, t)
  if t == nil then
    local u, last = {}, len (d)
    for i = 1, last - 1 do u[#u + 1] = d[i] end
    d, t = d[last], u
  end
  return reduce (function (x, y) return fn (y, x) end, d, ielems, ireverse (t))
end


local function id (...)
  return ...
end


local function memoize (fn, normalize)
  if normalize == nil then
    normalize = function (...) return base.tostring {...} end
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
end


local lambda = memoize (function (s)
  local expr

  -- Support "|args|expression" format.
  local args, body = s:match "^%s*|%s*([^|]*)|%s*(.+)%s*$"
  if args and body then
    expr = "return function (" .. args .. ") return " .. body .. " end"
  end

  -- Support "expression" format.
  if not expr then
    body = s:match "^%s*(_.*)%s*$" or s:match "^=%s*(.+)%s*$"
    if body then
      expr = [[
        return function (...)
          local unpack = table.unpack or unpack
          local _1,_2,_3,_4,_5,_6,_7,_8,_9 = unpack {...}
	  local _ = _1
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
end, id)


local function map (mapfn, ifn, ...)
  local argt, r = {...}, {}
  if not callable (ifn) or not next (argt) then
    ifn, argt = pairs, {ifn, ...}
  end

  local nextfn, state, k = ifn (unpack (argt))
  local mapargs = {nextfn (state, k)}

  local arity = 1
  while mapargs[1] ~= nil do
    local d, v = mapfn (unpack (mapargs))
    if v ~= nil then
      arity, r = 2, {} break
    end
    r[#r + 1] = d
    mapargs = {nextfn (state, mapargs[1])}
  end

  if arity > 1 then
    -- No need to start over here, because either:
    --   (i) arity was never 1, and the original value of mapargs is correct
    --  (ii) arity used to be 1, but we only consumed nil values, so the
    --       current mapargs with arity > 1 is the correct next value to use
    while mapargs[1] ~=  nil do
      local k, v = mapfn (unpack (mapargs))
      r[k] = v
      mapargs = {nextfn (state, mapargs[1])}
    end
  end
  return r
end


local function map_with (mapfn, tt)
  local r = {}
  for k, v in pairs (tt) do
    r[k] = mapfn (unpack (v))
  end
  return r
end


local function zip (tt)
  local r = {}
  for outerk, inner in pairs (tt) do
    for k, v in pairs (inner) do
      r[k] = r[k] or {}
      r[k][outerk] = v
    end
  end
  return r
end


local function zip_with (fn, tt)
  return map_with (fn, zip (tt))
end



--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


local function X (decl, fn)
  return debug.argscheck ("std.functional." .. decl, fn)
end

local M = {
  --- Partially apply a function.
  -- @function bind
  -- @func fn function to apply partially
  -- @tparam table argt table of *fn* arguments to bind
  -- @return function with *argt* arguments already bound
  -- @usage
  -- cube = bind (std.operator.pow, {[2] = 3})
  bind = X ("bind (func, ?any...)", bind),

  --- Identify callable types.
  -- @function callable
  -- @param x an object or primitive
  -- @return `true` if *x* can be called, otherwise `false`
  -- @usage
  -- if callable (functable) then functable (args) end
  callable = X ("callable (?any)", callable),

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
  case = X ("case (?any, #table)", case),

  --- Collect the results of an iterator.
  -- @function collect
  -- @func[opt=std.npairs] ifn iterator function
  -- @param ... *ifn* arguments
  -- @treturn table of results from running *ifn* on *args*
  -- @see filter
  -- @see map
  -- @usage
  -- --> {"a", "b", "c"}
  -- collect {"a", "b", "c", x=1, y=2, z=5}
  collect = X ("collect ([func], any...)", base.collect),

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
  compose = X ("compose (func...)", compose),

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
  cond = cond, -- any number of any type arguments!

  --- Curry a function.
  -- @function curry
  -- @func fn function to curry
  -- @int n number of arguments
  -- @treturn function curried version of *fn*
  -- @usage
  -- add = curry (function (x, y) return x + y end, 2)
  -- incr, decr = add (1), add (-1)
  curry = X ("curry (func, int)", curry),

  --- Filter an iterator with a predicate.
  -- @function filter
  -- @tparam predicate pfn predicate function
  -- @func[opt=std.pairs] ifn iterator function
  -- @param ... iterator arguments
  -- @treturn table elements e for which `pfn (e)` is not "falsey".
  -- @see collect
  -- @see map
  -- @usage
  -- --> {2, 4}
  -- filter (lambda '|e|e%2==0', std.elems, {1, 2, 3, 4})
  filter = X ("filter (func, [func], any...)", filter),

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
  -- foldl (std.operator.quot, {10000, 100, 10}) == (10000 / 100) / 10
  foldl = X ("foldl (function, [any], table)", foldl),

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
  -- foldr (std.operator.quot, {10000, 100, 10}) == 10000 / (100 / 10)
  foldr = X ("foldr (function, [any], table)", foldr),

  --- Identity function.
  -- @function id
  -- @param ... arguments
  -- @return *arguments*
  id = id,  -- any number of any type arguments!

  --- Compile a lambda string into a Lua function.
  --
  -- A valid lambda string takes one of the following forms:
  --
  --   1. `'=expression'`: equivalent to `function (...) return expression end`
  --   1. `'|args|expression'`: equivalent to `function (args) return expression end`
  --
  -- The first form (starting with `'='`) automatically assigns the first
  -- nine arguments to parameters `'_1'` through `'_9'` for use within the
  -- expression body.  The parameter `'_1'` is aliased to `'_'`, and if the
  -- first non-whitespace of the whole expression is `'_'`, then the
  -- leading `'='` can be omitted.
  --
  -- The results are memoized, so recompiling a previously compiled
  -- lambda string is extremely fast.
  -- @function lambda
  -- @string s a lambda string
  -- @treturn functable compiled lambda string, can be called like a function
  -- @usage
  -- -- The following are equivalent:
  -- lambda '= _1 < _2'
  -- lambda '|a,b| a<b'
  lambda = X ("lambda (string)", lambda),

  --- Map a function over an iterator.
  -- @function map
  -- @func fn map function
  -- @func[opt=std.pairs] ifn iterator function
  -- @param ... iterator arguments
  -- @treturn table results
  -- @see filter
  -- @see map_with
  -- @see zip
  -- @usage
  -- --> {1, 4, 9, 16}
  -- map (lambda '=_1*_1', std.ielems, {1, 2, 3, 4})
  map = X ("map (func, [func], any...)", map),

  --- Map a function over a table of argument lists.
  -- @function map_with
  -- @func fn map function
  -- @tparam table tt a table of *fn* argument lists
  -- @treturn table new table of *fn* results
  -- @see map
  -- @see zip_with
  -- @usage
  -- --> {"123", "45"}, {a="123", b="45"}
  -- conc = bind (map_with, {lambda '|...|table.concat {...}'})
  -- conc {{1, 2, 3}, {4, 5}}, conc {a={1, 2, 3, x="y"}, b={4, 5, z=6}}
  map_with = X ("map_with (function, table of tables)", map_with),

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
  memoize = X ("memoize (func, ?func)", memoize),

  --- No operation.
  -- This function ignores all arguments, and returns no values.
  -- @function nop
  -- @see id
  -- @usage
  -- if unsupported then vtable["memrmem"] = nop end
  nop = base.nop, -- ignores all arguments

  --- Fold a binary function into an iterator.
  -- @function reduce
  -- @func fn reduce function
  -- @param d initial first argument
  -- @func[opt=std.pairs] ifn iterator function
  -- @param ... iterator arguments
  -- @return result
  -- @see foldl
  -- @see foldr
  -- @usage
  -- --> 2 ^ 3 ^ 4 ==> 4096
  -- reduce (std.operator.pow, 2, std.ielems, {3, 4})
  reduce = X ("reduce (func, any, [func], any...)", reduce),

  --- Zip a table of tables.
  -- Make a new table, with lists of elements at the same index in the
  -- original table. This function is effectively its own inverse.
  -- @function zip
  -- @tparam table tt a table of tables
  -- @treturn table new table with lists of elements of the same key
  --   from *tt*
  -- @see map
  -- @see zip_with
  -- @usage
  -- --> {{1, 3, 5}, {2, 4}}, {a={x=1, y=3, z=5}, b={x=2, y=4}}
  -- zip {{1, 2}, {3, 4}, {5}}, zip {x={a=1, b=2}, y={a=3, b=4}, z={a=5}}
  zip = X ("zip (table of tables)", zip),

  --- Zip a list of tables together with a function.
  -- @function zip_with
  -- @tparam function fn function
  -- @tparam table tt table of tables
  -- @treturn table a new table of results from calls to *fn* with arguments
  --   made from all elements the same key in the original tables; effectively
  --   the "columns" in a simple list
  -- of lists.
  -- @see map_with
  -- @see zip
  -- @usage
  -- --> {"135", "24"}, {a="1", b="25"}
  -- conc = bind (zip_with, {lambda '|...|table.concat {...}'})
  -- conc {{1, 2}, {3, 4}, {5}}, conc {{a=1, b=2}, x={a=3, b=4}, {b=5}}
  zip_with = X ("zip_with (function, table of tables)", zip_with),
}



--[[ ============= ]]--
--[[ Deprecations. ]]--
--[[ ============= ]]--


local DEPRECATED = debug.DEPRECATED


M.eval = DEPRECATED ("41", "'std.functional.eval'",
  "use 'std.eval' instead", base.eval)


local function fold (fn, d, ifn, ...)
  local nextfn, state, k = ifn (...)
  local t = {nextfn (state, k)}

  local r = d
  while t[1] ~= nil do
    r = fn (r, t[#t])
    t = {nextfn (state, t[1])}
  end
  return r
end

M.fold = DEPRECATED ("41", "'std.functional.fold'",
  "use 'std.functional.reduce' instead", fold)


local operator = require "std.operator"

local function DEPRECATEOP (old, new)
  return DEPRECATED ("41", "'std.functional.op[" .. old .. "]'",
    "use 'std.operator." .. new .. "' instead", operator[new])
end

M.op = {
  ["[]"]  = DEPRECATEOP ("[]",  "get"),
  ["+"]   = DEPRECATEOP ("+",   "sum"),
  ["-"]   = DEPRECATEOP ("-",   "diff"),
  ["*"]   = DEPRECATEOP ("*",   "prod"),
  ["/"]   = DEPRECATEOP ("/",   "quot"),
  ["and"] = DEPRECATEOP ("and", "conj"),
  ["or"]  = DEPRECATEOP ("or",  "disj"),
  ["not"] = DEPRECATEOP ("not", "neg"),
  ["=="]  = DEPRECATEOP ("==",  "eq"),
  ["~="]  = DEPRECATEOP ("~=",  "neq"),
}

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
