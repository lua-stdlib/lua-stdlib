-- Code

require "std/patch40.lua"


-- pack: Turn a tuple into a list
--   ...: tuple
-- returns
--   l: list
function pack (...)
  return arg
end

-- curry: Partially apply a function
--   f: function to apply partially
--   a1 ... an: arguments to fix
-- returns
--   g: function with ai fixed
function curry (f, ...)
  local fix = arg
  return function (...)
           return call (%f, %fix .. arg)
         end
end

-- compose: Compose some functions
--   f1 ... fn: functions to compose
-- returns
--   g: composition of f1 ... fn
--     args: arguments
--   returns
--     f1(...fn (args)...)
function compose (...)
  local fns, n = arg, getn (arg)
  if getn (fns) == 0 then
    return id
  end
  return function (...)
           for i = %n, 1, -1 do
             arg = pack (call (%fns[i], arg))
           end
           return unpack (arg)
         end
end

-- listable: Make a function which can take its arguments as a list
--   f: function (if it only takes one argument, it must not be a
--     table)
-- returns
--   g: function that can take its arguments either as normal or in a
--     list
function listable (f)
  return function (...)
           if getn (arg) == 1 and type (arg[1]) == "table" then
             return call (%f, arg[1])
           else
             return call (%f, arg)
           end
         end
end

-- eval: Evaluate a string
--   s: string
-- returns
--   v: value of string
function eval (s)
  return dostring ("return " .. s)
end

-- id: Identity
--   x: object
-- returns
--   x: same object
function id (x)
  return x
end

-- loop: Call a function with values 1..n, returning a list of results
--   n: upper limit of parameter to function
--   f: function
-- returns
--   l: list {f (1) .. f (n)}
function loop (n, f)
  local l = {}
  for i = 1, n do
    tinsert (l, f (i))
  end
  return l
end


-- Iterators

-- Iterators are functions with the following type:
--   o: object being iterated over
--   c1,...,cn: control data
--   f: function to be iterated
--     i1,...,im: indices
--     v1,...,vl: values
--     u: accumulator (initialised to u below)
--     o: object being iterated over (same as o above)
--   u: result accumulator
-- returns
--   u: result accumulator (same as u argument)

-- For example, a typical table iterator has n=0, m=1, l=1, and i1 and
-- v1 are the index and value for each table element


-- Iterator: Make an index-value-output-input table iterator
-- Mainly used to generalise the built-in index-value table iterators
--   it: index-value table iterator (e.g. foreach, foreachi)
--     t: table
--     g:
--       i, v: index, value
-- returns
--   it_: index-value-output-input iterator
function Iterator (it)
  return function (t, f, u)
           u = u or {}
           %it (t,
                function (i, v) -- (this is g)
                  %f (i, v, %u, %t)
                end)
           return u
         end
end

-- Generalise foreach and foreachi (backwards compatibly, with the
-- caveat that the function is now passed four arguments, as above)
foreach = Iterator (foreach)
foreachi = Iterator (foreachi)
