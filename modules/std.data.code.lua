-- Code


-- id: Identity
--   x: object
-- returns
--   x: same object
function id (x)
  return x
end

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
           return f (unpack (fix), unpack (arg))
         end
end

-- compose: Compose some functions
--   f1 ... fn: functions to compose
-- returns
--   g: composition of f1 ... fn
--     args: arguments
--   returns
--     f1 (...fn (args)...)
function compose (...)
  local fns, n = arg, table.getn (arg)
  if n == 0 then
    return id
  else
    return function (...)
             for i = n, 1, -1 do
               arg = pack (fns[i](unpack (arg)))
             end
             return unpack (arg)
           end
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
           if table.getn (arg) == 1 and type (arg[1]) == "table" then
             return f (unpack (arg[1]))
           else
             return f (unpack (arg))
           end
         end
end

-- eval: Evaluate a string
--   s: string
-- returns
--   v: value of string
function eval (s)
  return loadstring ("return " .. s)()
end

-- constant: Return a constant value
--   x: object
-- returns
--   f: constant function returning x
--   returns
--     x: same object
function constant (x)
  return function ()
           return x
         end
end

-- loop: Call a function with values 1..n, returning a list of results
--   n: upper limit of parameter to function
--   f: function
-- returns
--   l: list {f (1) .. f (n)}
function loop (n, f)
  local l = {}
  for i = 1, n do
    table.insert (l, f (i))
  end
  return l
end
