-- Tables


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
  for _, _ in pairs (t) do
    return false
  end
  return true
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
                       {index = function (t, i)
                                  return x
                                end})
end
