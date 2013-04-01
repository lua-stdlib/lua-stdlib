--- Adds to the existing global functions
module ("base", package.seeall)

--- Functional forms of infix operators.
-- Defined here so that other modules can write to it.
-- @class table
-- @name _G.op
_G.op = {}

local table = require "std.table_ext"
--local list = require "std.list"
--require "std.io_ext" FIXME: allow loops
local strbuf  = require "std.strbuf"


--- Return given metamethod, if any, or nil.
-- @param x object to get metamethod of
-- @param n name of metamethod to get
-- @return metamethod function or nil if no metamethod or not a
-- function
function _G.metamethod (x, n)
  local _, m = pcall (function (x)
                        return getmetatable (x)[n]
                      end,
                      x)
  if type (m) ~= "function" then
    m = nil
  end
  return m
end

--- Turn an object into a table according to __totable metamethod.
-- @param x object to turn into a table
-- @return table or nil
function _G.totable (x)
  local m = metamethod (x, "__totable")
  if m then
    return m (x)
  elseif type (x) == "table" then
    return x
  else
    return nil
  end
end

--- Identity function.
-- @param ...
-- @return the arguments passed to the function
function _G.id (...)
  return ...
end

--- Turn a tuple into a list.
-- @param ... tuple
-- @return list
function _G.pack (...)
  return {...}
end

--- Partially apply a function.
-- @param f function to apply partially
-- @param ... arguments to bind
-- @return function with ai already bound
function _G.bind (f, ...)
  local fix = {...}
  return function (...)
           return f (unpack (list.concat (fix, {...})))
         end
end

--- Curry a function.
-- @param f function to curry
-- @param n number of arguments
-- @return curried version of f
function _G.curry (f, n)
  if n <= 1 then
    return f
  else
    return function (x)
             return curry (bind (f, x), n - 1)
           end
  end
end

--- Compose functions.
-- @param f1...fn functions to compose
-- @return composition of f1 ... fn
function _G.compose (...)
  local arg = {...}
  local fns, n = arg, #arg
  return function (...)
           local arg = {...}
           for i = n, 1, -1 do
             arg = {fns[i] (unpack (arg))}
           end
           return unpack (arg)
         end
end

--- Memoize a function, by wrapping it in a functable.
-- @param fn function that returns a single result
-- @return memoized function
function _G.memoize (fn)
  return setmetatable ({}, {
    __call = function (self, ...)
               local k = tostring ({...})
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
-- @param s string
-- @return value of string
function _G.eval (s)
  return loadstring ("return " .. s)()
end

--- An iterator like ipairs, but in reverse.
-- @param t table to iterate over
-- @return iterator function
-- @return the table, as above
-- @return #t + 1
function _G.ripairs (t)
  return function (t, n)
           n = n - 1
           if n > 0 then
             return n, t[n]
           end
         end,
  t, #t + 1
end

---
-- @class function
-- @name tree_Iterator
-- @param n current node
-- @return type ("leaf", "branch" (pre-order) or "join" (post-order))
-- @return path to node ({i1...ik})
-- @return node
local function _nodes (it, tr)
  local p = {}
  local function visit (n)
    if type (n) == "table" then
      coroutine.yield ("branch", p, n)
      for i, v in it (n) do
        table.insert (p, i)
        visit (v)
        table.remove (p)
      end
      coroutine.yield ("join", p, n)
    else
      coroutine.yield ("leaf", p, n)
    end
  end
  return coroutine.wrap (visit), tr
end

--- Tree iterator.
-- @see tree_Iterator
-- @param tr tree to iterate over
-- @return iterator function
-- @return the tree, as above
function _G.nodes (tr)
  return _nodes (pairs, tr)
end

--- Tree iterator over numbered nodes, in order.
-- @see tree_Iterator
-- @param tr tree to iterate over
-- @return iterator function
-- @return the tree, as above
function _G.inodes (tr)
  return _nodes (ipairs, tr)
end

--- Collect the results of an iterator.
-- @param i iterator
-- @return results of running the iterator on its arguments
function _G.collect (i, ...)
  local t = {}
  for e in i (...) do
    table.insert (t, e)
  end
  return t
end

--- Map a function over an iterator.
-- @param f function
-- @param i iterator
-- @return result table
function _G.map (f, i, ...)
  local t = {}
  for e in i (...) do
    local r = f (e)
    if r then
      table.insert (t, r)
    end
  end
  return t
end

--- Filter an iterator with a predicate.
-- @param p predicate
-- @param i iterator
-- @return result table containing elements e for which p (e)
function _G.filter (p, i, ...)
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
-- @return result
function _G.fold (f, d, i, ...)
  local r = d
  for e in i (...) do
    r = f (r, e)
  end
  return r
end

--- Give warning with the name of program and file (if any).
-- @param ... arguments for format
function _G.warn (...)
  if prog.name then
    io.stderr:write (prog.name .. ":")
  end
  if prog.file then
    io.stderr:write (prog.file .. ":")
  end
  if prog.line then
    io.stderr:write (tostring (prog.line) .. ":")
  end
  if prog.name or prog.file or prog.line then
    io.stderr:write (" ")
  end
  io.writelines (io.stderr, string.format (...))
end

--- Die with error.
-- @param ... arguments for format
function _G.die (...)
  warn (...)
  error ()
end

-- Function forms of operators.
-- FIXME: Make these visible in LuaDoc (also list.concat in list)
_G.op["[]"] = function (t, s)
  return t[s]
end
_G.op["+"] = function (a, b)
  return a + b
end
_G.op["-"] = function (a, b)
  return a - b
end
_G.op["*"] = function (a, b)
  return a * b
end
_G.op["/"] = function (a, b)
  return a / b
end
_G.op["and"] = function (a, b)
  return a and b
end
_G.op["or"] = function (a, b)
  return a or b
end
_G.op["not"] = function (a)
  return not a
end
_G.op["=="] = function (a, b)
  return a == b
end
_G.op["~="] = function (a, b)
  return a ~= b
end
