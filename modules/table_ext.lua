-- @module table

module ("table", package.seeall)

--require "list" FIXME: allow require loops

-- FIXME: use consistent name for result table: t_? (currently r and
-- u)


-- @func sort: Make table.sort return its result
--   @param t: table
--   @param c: comparator function
-- @returns
--   @param t: sorted table
local _sort = sort
function sort (t, c)
  _sort (t, c)
  return t
end

-- @func subscript: Expose [] as a function
--   @param t: table
--   @param s: subscript
-- @returns
--   @param v: t[s]
function subscript (t, s)
  return t[s]
end

-- @func lookup: Do a late-bound table lookup
--   @param t: table to look up in
--   @param l: list of indices {l1 ... ln}
-- @returns
--   @param u: t[l1]...[ln]
function lookup (t, l)
  return list.foldl (subscript, t, l)
end

-- @func pathSubscript: Subscript a table with a string containing
-- dots
--   @param t: table
--   @param s: subscript of the form s1.s2. ... .sn
-- @returns
--   @param v: t.s1.s2. ... .sn
function subscripts (t, s)
  return lookup (t, string.split ("%.", s))
end

-- @func empty: Say whether table is empty
--   @param t: table
-- @returns
--   @param f: true if empty or false otherwise
function empty (t)
  for _ in pairs (t) do
    return false
  end
  return true
end

-- @func size: Find the number of elements in a table
--   @param t: table
-- @returns
--   @param n: number of elements in t
function size (t)
  local n = 0
  for _ in pairs (t) do
    n = n + 1
  end
  return n
end

-- @func indices: Make the list of indices of a table
--   @param t: table
-- @returns
--   @param u: list of indices
function indices (t)
  local u = {}
  for i, v in pairs (t) do
    insert (u, i)
  end
  return u
end

-- @func values: Make the list of values of a table
--   @param t: table
-- @returns
--   @param u: list of values
function values (t)
  local u = {}
  for i, v in pairs (t) do
    insert (u, v)
  end
  return u
end

-- @func invert: Invert a table
--   @param t: table {i=v...}
-- @returns
--   @param u: inverted table {v=i...}
function invert (t)
  local u = {}
  for i, v in pairs (t) do
    u[v] = i
  end
  return u
end

-- @func rearrange: Rearrange some indices of a table
--   @param m: table {oldindex=newindex...}
--   @param t: table to rearrange
-- @returns
--   @param r: rearranged table
function rearrange (m, t)
  local r = clone (t)
  for i, v in pairs (m) do
    r[v] = t[i]
    r[i] = nil
  end
  return r
end

-- @func process: map a function over a table using an iterator
--   @param it: iterator
--   @param f: function
--     @param a: accumulator
--     @param i: index
--     @param v: value
--   @returns
--     @param b: updated accumulator
--   @param a: initial value of the accumulator
--   @param t: table to iterate over
-- @returns
--   @param a: final value of the accumulator
function process (it, f, a, t)
  for i, v in it (t) do
    a = f (a, i, v)
  end
  return a
end

-- @func mapItem: map primitive for table.process
--   @f: function
-- @returns
--   @g: function to pass to process to map a single item
function mapItem (f)
  return function (a, i, v)
           a[i] = f (v)
           return a
         end
end

-- @func filterItem: filter primitive for table.process
--   @f: predicate
-- @returns
--   @g: function to pass to process to filter a single item
function filterItem (p)
  return function (a, i, v)
           if p (v) then
             a[i] = v
           end
           return a
         end
end

-- @func foldlItem: foldl primitive for table.process
--   @f: function
-- @returns
--   @g: function to pass to process to foldl a single item
function foldlItem (f)
  return function (a, i, v)
           return f (a, v)
         end
end

-- @func foldrItem: foldr primitive for table.process
--   @f: function
-- @returns
--   @g: function to pass to process to foldr a single item
function foldrItem (f)
  return function (a, i, v)
           return f (v, a)
         end
end

-- @func map: Map a function over a table
--   @param f: function
--   @param t: table
-- @returns
--   @param m: result table {f (t[i1])...}
function map (f, t)
  return process (pairs, mapItem (f), {}, t)
end

-- @func filter: Filter a table with a predicate
--   @param p: predicate
--   @param t: table
-- @returns
--   @param m: result table containing elements e of t for which p (e)
function filter (p, t)
  return process (pairs, filterItem (p), {}, t)
end

-- @func clone: Make a shallow copy of a table, including any
-- metatable
--   @param t: table
-- @returns
--   @param u: copy of table
function clone (t)
  local u = setmetatable ({}, getmetatable (t))
  for i, v in pairs (t) do
    u[i] = v
  end
  return u
end

-- @func deepclone: Make a deep copy of a table, including any
--  metatable
--   @param t: table
-- @returns
--   @param u: copy of table
function deepclone (t)
  local r = {}
  local d = {[t] = r}
  local function copy (o, x)
    for i, v in pairs (x) do
      if type (v) == "table" then
        if not d[v] then
          d[v] = {}
          local q = copy (d[v], v)
          o[i] = q
        else
          o[i] = d[v]
        end
      else
        o[i] = v
      end
    end
    return o
  end
  return copy (r, t)
end

-- @func merge: Merge two tables
-- If there are duplicate fields, u's will be used. The metatable of
-- the returned table is that of t
--   @param t, u: tables
-- @returns
--   @param r: the merged table
function merge (t, u)
  local r = clone (t)
  for i, v in pairs (u) do
    r[i] = v
  end
  return r
end

-- @func newDefault: Make a table with a default value
--   @param x: default value
--   @param [t]: initial table [{}]
-- @returns
--   @param u: table for which u[i] is x if u[i] does not exist
function newDefault (x, t)
  return setmetatable (t or {},
                       {__index = function (t, i)
                                    return x
                                  end})
end
