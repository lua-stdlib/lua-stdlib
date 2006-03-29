-- Tables

module ("table_ext", package.seeall)

-- @func table.sort: Make table.sort return its result
--   @param t: table
--   @param c: comparator function
-- @returns
--   @param t: sorted table
local sort = table.sort
function table.sort (t, c)
  sort (t, c)
  return t
end

-- @func table.subscript: Expose [] as a function
--   @param t: table
--   @param s: subscript
-- @returns
--   @param v: t[s]
function table.subscript (t, s)
  return t[s]
end

-- @func table.empty: Say whether table is empty
--   @param t: table
-- @returns
--   @param f: true if empty or false otherwise
function table.empty (t)
  for _ in pairs (t) do
    return false
  end
  return true
end

-- @func table.size: Find the number of elements in a table
--   @param t: table
-- @returns
--   @param n: number of elements in t
function table.size (t)
  local n = 0
  for _ in pairs (t) do
    n = n + 1
  end
  return n
end

-- @func table.indices: Make the list of indices of a table
--   @param t: table
-- @returns
--   @param u: list of indices
function table.indices (t)
  local u = {}
  for i, v in pairs (t) do
    table.insert (u, i)
  end
  return u
end

-- @func table.values: Make the list of values of a table
--   @param t: table
-- @returns
--   @param u: list of values
function table.values (t)
  local u = {}
  for i, v in pairs (t) do
    table.insert (u, v)
  end
  return u
end

-- @func table.invert: Invert a table
--   @param t: table {i=v ...}
-- @returns
--   @param u: inverted table {v=i ...}
function table.invert (t)
  local u = {}
  for i, v in pairs (t) do
    u[v] = i
  end
  return u
end

-- @func table.permute: Permute some indices of a table
--   @param p: table {oldindex=newindex ...}
--   @param t: table to permute
-- @returns
--   @param u: permuted table
function table.permute (p, t)
  local u = {}
  for i, v in pairs (t) do
    if p[i] ~= nil then
      u[p[i]] = v
    else
      u[i] = v
    end
  end
  return u
end

-- @func table.process: map a function over a table using an iterator
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
function table.process (it, f, a, t)
  for i, v in it (t) do
    a = f (a, i, v)
  end
  return a
end

-- @func table.mapItem: map primitive for table.process
--   @f: function
-- @returns
--   @g: function to pass to process to map a single item
function table.mapItem (f)
  return function (a, i, v)
           a[i] = f (v)
           return a
         end
end

-- @func table.foldlItem: foldl primitive for table.process
--   @f: function
-- @returns
--   @g: function to pass to process to foldl a single item
function table.foldlItem (f)
  return function (a, i, v)
           return f (a, v)
         end
end

-- @func table.foldrItem: foldr primitive for table.process
--   @f: function
-- @returns
--   @g: function to pass to process to foldr a single item
function table.foldrItem (f)
  return function (a, i, v)
           return f (v, a)
         end
end

-- @func table.map: Map a function over a table
--   @param f: function
--   @param t: table
-- @returns
--   @param m: result table {f (t[i1])...}
function table.map (f, t)
  return table.process (pairs, table.mapItem (f), {}, t)
end

-- @func table.clone: Make a shallow copy of a table, including any
-- metatable
--   @param t: table
-- @returns
--   @param u: copy of table
function table.clone (t)
  local u = setmetatable ({}, getmetatable (t))
  for i, v in pairs (t) do
    u[i] = v
  end
  return u
end

-- @func table.merge: Merge two tables
-- If there are duplicate fields, u's will be used. The metatable of
-- the returned table is that of t
--   @param t, u: tables
-- @returns
--   @param r: the merged table
function table.merge (t, u)
  local r = table.clone (t)
  for i, v in pairs (u) do
    r[i] = v
  end
  return r
end

-- @func table.newDefault: Make a table with a default value
--   @param x: default value
--   @param [t]: initial table [{}]
-- @returns
--   @param u: table for which u[i] is x if u[i] does not exist
function table.newDefault (x, t)
  return setmetatable (t or {},
                       {__index = function (t, i)
                                    return x
                                  end})
end
