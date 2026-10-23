--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 Functional programming.

 This is the 41.x `std.functional` API.  The std.functional package
 has a new design, with its data first, and its function last, as
 `table.sort` and `string.gsub` do, that is not compatible with it; so
 when stdlib is installed, `require 'std.functional'` gives you this
 module, and the new one is

      local functional = require 'std.functional.init'

 Where the two do the same thing, this module calls the new one.

 @module std.functional
]]


local _ = require 'std._base'

local DEPRECATED = require 'std._deprecation'.DEPRECATED
local DEPRECATIONMSG = require 'std._deprecation'.DEPRECATIONMSG
local argscheck = _.typecheck and _.typecheck.argscheck
local functional = require 'std.functional.init'

_ = nil


local loadstring = rawget(_G, 'loadstring') or load


local _ENV = require 'std.normalize' {
   floor = 'math.floor',
   stderr = 'io.stderr',
}



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


-- The 41.x callable returns the function that calls *x*, where the
-- functional.init one returns *x* itself.
local function callable(x)
   if type(x) == 'function' then
      return x
   end
   return getmetamethod(x, '__call')
end


local function bind(fn, ...)
   local bound = {...}
   if type(bound[1]) == 'table' and bound[2] == nil then
      bound = bound[1]
   else
      stderr:write(DEPRECATIONMSG('39',
         "multi-argument 'std.functional.bind'",
         'use a table of arguments as the second parameter instead', 2))
   end
   return functional.bind(fn, bound)
end


local function case(with, branches)
   local match = branches[with] or branches[1]
   if callable(match) then
      return match(with)
   end
   return match
end


local function compose(...)
   local fns = pack(...)

   return function(...)
      local argt = pack(...)
      for i = 1, fns.n do
         argt = pack(fns[i](unpack(argt, 1, argt.n)))
      end
      return unpack(argt, 1, argt.n)
   end
end


local function cond(expr, branch, ...)
   if branch == nil and select('#', ...) == 0 then
      expr, branch = true, expr
   end
   if expr then
      if callable(branch) then
         return branch(expr)
      end
      return branch
   end
   return cond(...)
end


local function curry(fn, n)
   if n <= 1 then
      return fn
   end
   return function(x)
      return curry(bind(fn, {x}), n - 1)
   end
end


-- The 41.x foldl and foldr took the function first, and used the first,
-- or the last, element for the initial value that was elided, where the
-- new ones start from an empty table.
local function foldl(fn, d, t)
   if t == nil then
      t, d = d, nil
   end
   if d == nil then
      local tail = {}
      for i = 2, len(t) do
         tail[#tail + 1] = t[i]
      end
      d, t = t[1], tail
   end
   return functional.foldl(t, d, fn)
end


local function foldr(fn, d, t)
   if t == nil then
      t, d = d, nil
   end
   if d == nil then
      local u, last = {}, len(t)
      for i = 1, last - 1 do
         u[#u + 1] = t[i]
      end
      d, t = t[last], u
   end
   return functional.foldr(t, d, fn)
end


local function map_with(fn, tt)
   return functional.map_with(tt, fn)
end


local function zip_with(fn, tt)
   return functional.zip_with(tt, fn)
end


-- The generic iterator functions of 41.x, whose *ifn* and its arguments
-- the new design leaves to the caller to wrap with `iter`.

-- The highest integer key of *t*, which `len` and `#` stop short of when
-- there are holes.
local function maxn(t)
   local n = 0
   for k in next, t do
      if type(k) == 'number' and k > n and k == floor(k) then
         n = k
      end
   end
   return n
end


local function npairs(t)
   local m = getmetamethod(t, '__len')
   local i, n = 0, m and m(t) or maxn(t)
   return function(t)
      i = i + 1
      if i <= n then
         return i, t[i]
      end
   end, t, i
end


local function collect(ifn, ...)
   local argt, r = pack(...), {}
   if not callable(ifn) then
      ifn, argt = npairs, pack(ifn, ...)
   end

   -- How many return values from ifn?
   local arity = 1
   for e, v in ifn(unpack(argt, 1, argt.n)) do
      if v then
         arity, r = 2, {}
         break
      end
      -- Build an arity-1 result table on first pass...
      r[#r + 1] = e
   end

   if arity == 2 then
      -- ...and start over for arity-2 results.
      for k, v in ifn(unpack(argt, 1, argt.n)) do
         r[k] = v
      end
   end
   return r
end


local function filter(pfn, ifn, ...)
   local argt, r = pack(...), {}
   if not callable(ifn) then
      ifn, argt = pairs, pack(ifn, ...)
   end

   local nextfn, state, k = ifn(unpack(argt, 1, argt.n))

   local t = pack(nextfn(state, k))   -- table of iteration 1
   local arity = t.n                  -- How many return values from ifn?

   if arity == 1 then
      local v = t[1]
      while v ~= nil do               -- until iterator returns nil
         if pfn(unpack(t, 1, t.n)) then  -- pass all iterator results to pfn
            r[#r + 1] = v
         end

         t = pack(nextfn(state, v))   -- maintain loop invariant
         v = t[1]

         if t.n > 1 then              -- unless we discover arity is not 1
            arity, r = t.n, {}
            break
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
         if pfn(unpack(t, 1, t.n)) then
            r[k] = t[2]
         end
         t = pack(nextfn(state, k))
      end
   end

   return r
end


local function map(mapfn, ifn, ...)
   local argt, r = pack(...), {}
   if not callable(ifn) or argt.n == 0 then
      ifn, argt = pairs, pack(ifn, ...)
   end

   local nextfn, state, k = ifn(unpack(argt, 1, argt.n))
   local mapargs = pack(nextfn(state, k))

   local arity = 1
   while mapargs[1] ~= nil do
      local d, v = mapfn(unpack(mapargs, 1, mapargs.n))
      if v ~= nil then
         arity, r = 2, {}
         break
      end
      r[#r + 1] = d
      mapargs = pack(nextfn(state, mapargs[1]))
   end

   if arity > 1 then
      -- No need to start over here, because either:
      --   (i) arity was never 1, and the original value of mapargs is correct
      --  (ii) arity used to be 1, but we only consumed nil values, so the
      --       current mapargs with arity > 1 is the correct next value to use
      while mapargs[1] ~= nil do
         local k, v = mapfn(unpack(mapargs, 1, mapargs.n))
         r[k] = v
         mapargs = pack(nextfn(state, mapargs[1]))
      end
   end
   return r
end


local function reduce(fn, d, ifn, ...)
   local argt = pack(...)
   if not callable(ifn) then
      ifn, argt = pairs, pack(ifn, ...)
   end

   local nextfn, state, k = ifn(unpack(argt, 1, argt.n))
   local t = pack(nextfn(state, k))  -- table of iteration 1

   local r = d                       -- initialise accumulator
   while t[1] ~= nil do              -- until iterator returns nil
      k = t[1]
      r = fn(r, unpack(t, 1, t.n))   -- pass all iterator results to fn
      t = pack(nextfn(state, k))     -- maintain loop invariant
   end
   return r
end


local function fold(fn, d, ifn, ...)
   local nextfn, state, k = ifn(...)
   local t = pack(nextfn(state, k))

   local r = d
   while t[1] ~= nil do
      r = fn(r, t[t.n])
      t = pack(nextfn(state, t[1]))
   end
   return r
end


local function eval(s)
   return loadstring('return ' .. s)()
end



--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


local function X(decl, fn)
   return argscheck and argscheck('std.functional.' .. decl, fn) or fn
end


local M = {
   --- Partially apply a function.
   -- @function bind
   -- @func fn function to apply partially
   -- @tparam table argt table of *fn* arguments to bind
   -- @return function with *argt* arguments already bound
   -- @usage
   --    cube = bind(std.operator.pow, {[2] = 3})
   bind = X('bind(func, [?any...])', bind),

   --- Identify callable types.
   -- @function callable
   -- @param x an object or primitive
   -- @return the function that calls *x* if *x* can be called, otherwise
   --    `nil`
   -- @usage
   --    if callable(functable) then functable(args) end
   callable = X('callable([?any])', callable),

   --- Extend `case` with a default.
   -- @function case
   -- @param with expression to match
   -- @tparam table branches map possible values to functions or values
   -- @return the value of a matching branch, or the default branch
   --    `branches[1]`, called with *with* if it is callable
   -- @usage
   --    return case(type(object), {
   --       table = 'table', string = 'string', 'other'})
   case = X('case(?any, #table)', case),

   --- Collect the results of an iterator.
   -- @function collect
   -- @tparam[opt=pairs] function ifn iterator function
   -- @param ... *ifn* arguments
   -- @treturn table results of running *ifn* on those arguments
   -- @usage
   --    --> {'a', 'b', 'c'}
   --    collect(ipairs, {'a', 'b', 'c'})
   collect = X('collect([func], any...)', collect),

   --- Compose functions, applying them in the order given.
   -- @function compose
   -- @tparam function ... functions to compose
   -- @treturn function composition of fnN .. fn1
   -- @usage
   --    vpairs = compose(table.invert, ipairs)
   --    for v, i in vpairs {'a', 'b', 'c'} do process(v, i) end
   compose = X('compose(func...)', compose),

   --- A rudimentary case statement.
   -- @function cond
   -- @param expr a Lua expression
   -- @param branch a Lua expression to evaluate if *expr* is true,
   --    or a function to call with *expr* if it is callable
   -- @param ... more `expr, branch` pairs and a final default
   -- @return the value of the first true branch
   -- @usage
   --    cond(math.pi > 3, 'ok', 'not ok')
   cond = cond,  -- any number of any type arguments!

   --- Curry a function.
   -- @function curry
   -- @tparam function fn function to curry
   -- @int n number of arguments
   -- @treturn function curried version of *fn*
   -- @usage
   --    add = curry(function(x, y) return x + y end, 2)
   --    incr, decr = add(1), add(-1)
   curry = X('curry(func, int)', curry),

   --- Evaluate a string.
   -- @function eval
   -- @string s string of Lua code
   -- @return result of evaluating `s`
   -- @usage
   --    --> 2
   --    eval 'math.min(2, 10)'
   eval = DEPRECATED('41', "'std.functional.eval'",
      "use 'std.eval' instead", X('eval(string)', eval)),

   --- Filter an iterator with a predicate.
   -- @function filter
   -- @tparam predicate pfn predicate function
   -- @tparam[opt=pairs] function ifn iterator function
   -- @param ... iterator arguments
   -- @treturn table elements e for which `pfn(e)` is not falsey.
   -- @usage
   --    --> {2, 4}
   --    filter(function(e) return e % 2 == 0 end, ipairs, {1, 2, 3, 4})
   filter = X('filter(func, [func], any...)', filter),

   --- Fold a binary function into an iterator.
   -- @function fold
   -- @tparam function fn binary function
   -- @param d initial first argument
   -- @tparam function ifn iterator function
   -- @param ... iterator arguments
   -- @return result
   fold = DEPRECATED('41', "'std.functional.fold'",
      "use 'std.functional.reduce' instead", fold),

   --- Fold a binary function left associatively.
   -- If parameter *d* is omitted, the first element of *t* is used,
   -- and *t* treated as if it had been passed without that element.
   -- @function foldl
   -- @tparam function fn binary function
   -- @param[opt=t[1]] d initial left-most argument
   -- @tparam table t a table
   -- @return result
   -- @usage
   --    foldl(math.pow, {2, 3, 4})   --> (2^3)^4
   foldl = X('foldl(func, [any], table)', foldl),

   --- Fold a binary function right associatively.
   -- If parameter *d* is omitted, the last element of *t* is used,
   -- and *t* treated as if it had been passed without that element.
   -- @function foldr
   -- @tparam function fn binary function
   -- @param[opt=t[#t]] d initial right-most argument
   -- @tparam table t a table
   -- @return result
   -- @usage
   --    foldr(math.pow, {2, 3, 4})   --> 2^(3^4)
   foldr = X('foldr(func, [any], table)', foldr),

   --- Identity function.
   -- @function id
   -- @param ... arguments
   -- @return *...*
   id = functional.id,

   --- Compile a lambda string into a Lua function.
   --
   -- A valid lambda string takes one of the forms:
   --
   --   1. `'=expression'`: an expression using `_1`, `_2`, etc as
   --      parameters, with `_` for `_1`.
   --   2. `'|args|expression'`: an expression using the named *args*.
   -- @function lambda
   -- @string s a lambda string
   -- @treturn table|nil the compiled function, or `nil` and an error
   --    message if *s* is invalid
   -- @usage
   --    table.sort(subjects, lambda '|a, b| a.name < b.name')
   lambda = X('lambda(string)', functional.lambda),

   --- Map a function over an iterator.
   -- @function map
   -- @tparam function mapfn map function
   -- @tparam[opt=pairs] function ifn iterator function
   -- @param ... iterator arguments
   -- @treturn table results
   -- @usage
   --    --> {1, 4, 9, 16}
   --    map(function(e) return e * e end, ipairs, {1, 2, 3, 4})
   map = X('map(func, [func], any...)', map),

   --- Map a function over a table of argument lists.
   -- @function map_with
   -- @tparam function fn map function
   -- @tparam table tt table of *fn* argument lists
   -- @treturn table new table of *fn* results
   -- @usage
   --    --> {'a1', 'b2'}
   --    map_with(function(a, b) return a .. b end, {{'a', 1}, {'b', 2}})
   map_with = X('map_with(func, table of tables)', map_with),

   --- Memoize a function, by wrapping it in a functable.
   -- @function memoize
   -- @tparam function fn function that returns a single result
   -- @tparam[opt] function normalize function to normalize arguments
   -- @treturn functable memoized function
   -- @usage
   --    memofactorial = memoize(factorial)
   memoize = X('memoize(func, [?func])', functional.memoize),

   --- No operation.
   -- @function nop
   -- @param ... arguments
   -- @return nothing
   nop = functional.nop,

   --- Functional forms of Lua operators.
   -- @table op
   -- @see std.operator
   op = nil,  -- set below

   --- Fold a binary function into an iterator.
   -- @function reduce
   -- @tparam function fn binary function
   -- @param d initial first argument
   -- @tparam[opt=pairs] function ifn iterator function
   -- @param ... iterator arguments
   -- @return result
   -- @usage
   --    --> 2 ^ 3 ^ 4 ==> 4096
   --    reduce(std.operator.pow, 2, std.ipairs, {3, 4})
   reduce = X('reduce(func, any, [func], any...)', reduce),

   --- Zip a table of tables.
   -- Make a new table, with lists of elements at the same index in the
   -- original table.
   -- @function zip
   -- @tparam table tt a table of tables
   -- @treturn table new table with lists of elements of the same key
   --    from *tt*
   -- @usage
   --    --> {{1, 3, 5}, {2, 4}}
   --    zip {{1, 2}, {3, 4}, {5}}
   zip = X('zip(table of tables)', functional.zip),

   --- Zip a table of tables, and map a function over the result.
   -- @function zip_with
   -- @tparam function fn function
   -- @tparam table tt table of tables
   -- @treturn table a new table of results from calls to *fn* with
   --    arguments made from all the values of the same key in *tt*
   -- @usage
   --    --> {'ac', 'bd'}
   --    zip_with(function(a, b) return a .. b end, {{'a', 'b'}, {'c', 'd'}})
   zip_with = X('zip_with(func, table of tables)', zip_with),
}


local operator = require 'std.functional.operator'

local function DEPRECATEOP(old, new)
   return DEPRECATED('41', "'std.functional.op[" .. old .. "]'",
      "use 'std.operator." .. new .. "' instead", operator[new])
end

M.op = {
   ['[]']  = DEPRECATEOP('[]',  'get'),
   ['+']   = DEPRECATEOP('+',   'sum'),
   ['-']   = DEPRECATEOP('-',   'diff'),
   ['*']   = DEPRECATEOP('*',   'prod'),
   ['/']   = DEPRECATEOP('/',   'quot'),
   ['and'] = DEPRECATEOP('and', 'conj'),
   ['or']  = DEPRECATEOP('or',  'disj'),
   ['not'] = DEPRECATEOP('not', 'neg'),
   ['==']  = DEPRECATEOP('==',  'eq'),
   ['~=']  = DEPRECATEOP('~=',  'neq'),
}

return M
