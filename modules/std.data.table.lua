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
                          tinsert (u, i)
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
-- If there are duplicate fields, u's will be used. The tag of the
-- returned table is that of t
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

-- @func methodify: Make a table type use custom per-field get/set methods
-- The settable and gettable methods of the given tag are modified so
-- that fields can have get and set methods added by putting an entry
-- in the _getset member of a table of that type. If the entry is a
-- table, it is assumed to be a table of the form {get = get tag method,
-- set = set tag method}, and the relevant method is called, just like
-- an ordinary tag method. Otherwise, the entry is used as an index to
-- the table; in this way, one table member can easily be made an
-- alias for another, allowing shorter names to be used. If there is
-- no entry, the previous tag method is used.
--   @param tTag: tag to methodify
function methodify (tTag)
  local gettm = gettagmethod (tTag, "gettable")
  settagmethod (tTag, "gettable",
                function (t, i)
                  if t._getset[i] then
                    if type (t._getset[i]) == "table" then
                      return t._getset[i].get (t, i)
                    else
                      return pathSubscript (t, t._getset[i])
                    end
                  end
                  if gettm then
                    return gettm (t, i)
                  else
                    return t[i]
                  end
                end)
  local settm = gettagmethod (tTag, "settable")
  settagmethod (tTag, "settable",
                function (t, i, v)
                  if t._getset[i] then
                    if type (t._getset[i]) == "table" then
                      t._getset[i].set (t, i, v)
                    else
                      t[t._getset[i]] = v
                    end
                  end
                  if settm then
                    settm (t, i, v)
                  else
                    t[i] = v
                  end
                end)
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
