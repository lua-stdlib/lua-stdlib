-- Tables

require "std.data.code"


-- @func subscript: Expose [] as a function
--   @param t: table
--   @param s: subscript
-- returns
--   @param v: t[s]
function subscript (t, s)
  return t[s]
end

-- @func empty: Say whether table is empty
--   @param t: table
-- returns
--   @param f: true if empty or false otherwise
function empty (t)
  for _, _ in pairs (t) do
    return false
  end
  return true
end

-- @func indices: Make the list of indices of a table
--   @param t: table
-- returns
--   @param u: list of indices
function indices (t)
  return table.foreach (t,
                        function (i, _, u)
                          table.insert (u, i)
                        end)
end

-- @func values: Make the list of values of a table
--   @param t: table
-- returns
--   @param u: list of values
function values (t)
  return table.foreach (t,
                        function (_, v, u)
                          table.insert (u, v)
                        end)
end

-- @func tinvert: Invert a table
--   @param t: table {i=v ...}
-- returns
--   @param u: inverted table {v=i ...}
function tinvert (t)
  local u = {}
  for i, v in pairs (t) do
    u[v] = i
  end
  return u
end

-- @func permute: Permute some indices of a table
--   @param p: table {oldindex=newindex ...}
--   @param t: table to permute
-- returns
--   @param u: permuted table
function permute (p, t)
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

-- @func clone: Make a shallow copy of a table, including any metatable
--   @param t: table
-- returns
--   @param u: copy of table
function clone (t)
  local u = setmetatable ({}, getmetatable (t))
  for i, v in pairs (t) do
    u[i] = v
  end
  return u
end

-- @func merge: Merge two tables
-- If there are duplicate fields, u's will be used. The metatable of
-- the returned table is that of t
--   @param t, u: tables
-- returns
--   @param r: the merged table
function merge (t, u)
  local r = clone (t)
  for i, v in pairs (u) do
    r[i] = v
  end
  return r
end

-- @func defaultTable: Make a table with a different default value
--   @param x: default value
--   @param [t]: initial table
-- returns
--   @param u: table for which u[i] is x if u[i] does not exist
function defaultTable (x, t)
  return setmetatable (t or {}, {index = function (t, i)
                                           return x
                                         end})
end

-- Table of methods to make arbitrary objects (typically userdata)
-- into tables; used by tostring and pickle
-- Table entries are tag = function from object to table
tabulator = {}

-- @func tabulate: Turn an object into a table according to tabulator
--   @param x: object to turn into a table
-- returns
--   @param t: table or nil
function tabulate (x)
  local m = tabulator[getmetatable (x)]
  if m then
    return m (x)
  elseif type (x) == "table" then
    return x
  else
    return nil
  end
end
