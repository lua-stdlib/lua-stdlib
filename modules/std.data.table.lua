-- Tables

-- TODO: Make more combinators take iterators (e.g. indices, values)
-- TODO: Write filterIter, mapWithIter
-- TODO: Write listify which passes foreachi as the first argument of
--   an iterator combinator, and nify which makes a function that adds
--   an n field to the result of another function. Use these to make
--   list versions of combinators more easily.

require "std.patch40"
require "std.data.code"


-- Vanilla table tag
_TableTag = tag ({})

-- @func subscript: Expose [] as a function
--   @param t: table
--   @param s: subscript
-- returns
--   @param v: t[s]
function subscript (t, s)
  return t[s]
end

-- @func Table: Make a new table of the given tag type
--   @param tTag: tag
-- returns
--   @param t: table with tag tTag
function Table (tTag)
  local t = {}
  if tTag ~= _TableTag then
    settag (t, tTag)
  end
  return t
end

-- @func empty: say whether table is empty
--   @param t: table
-- returns
--   @param f: 1 if empty or nil otherwise
function empty (t)
  for _, _ in t do
    return nil
  end
  return 1
end

-- @func indices: Make the list of indices of a table
--   @param t: table
-- returns
--   @param u: list of indices
function indices (t)
  return foreach (t,
                  function (i, _, u)
                    tinsert (u, i)
                  end)
end

-- @func values: Make the list of values of a table
--   @param t: table
-- returns
--   @param u: list of values
function values (t)
  return foreach (t,
                  function (_, v, u)
                    tinsert (u, v)
                  end)
end

-- @func tinvert: Invert a table
--   @param t: table {i=v ...}
-- returns
--   @param u: inverted table {v=i ...}
function tinvert (t)
  return foreach (t,
                  function (i, v, u)
                    u[v] = i
                  end)
end

-- @func permuteIter: Permute some indices of a table
--   @param it: iterator
--   @param p: table {oldindex=newindex ...}
--   @param t: table to permute
-- returns
--   @param u: permuted table
function permuteIter (it, p, t)
  return it (t,
             function (i, v, u)
               u[%p[i] or i] = v
             end)
end

-- @func permute: Permute some indices of a table
--   @param p: table {oldindex=newindex ...}
--   @param t: table to permute
-- returns
--   @param u: permuted table
permute = curry (permuteIter, foreach)

-- @func indexKeyIter: Make an index of a table of tables on a given field
--   @param it: iterator
--   @param f: field
--   @param t: table of tables {i1=t1 ... in=tn}
-- returns
--   @param ind: index {t1[f]=i1 ... tn[f]=in}
function indexKeyIter (it, f, t)
  return it (t,
             function (i, v, u)
               local k = v[%f]
               if k then
                 u[k] = i
               end
             end)
end

-- @func indexValueIter: Copy a table of tables, reindexed on a given field
--   @param it: iterator
--   @param f: field
--   @param t: table of tables {i1=t1 ... in=tn}
-- returns
--   @param ind: index {t1[f]=t1 ... tn[f]=tn}
function indexValueIter (it, f, t)
  return it (t,
             function (_, v, u)
               local k = v[%f]
               if k then
                 u[k] = v
               end
             end)
end

-- @func mapIter: Map a function over a table according to an iterator
--   @param it: iterator
--   @param f: function
--   @param t: table {i1=v1 ... in=vn}
-- returns
--   @param u: result table {i1=f (v1) ... in=f (vn)}
function mapIter (it, f, t)
  return it (t,
             function (i, v, u)
               u[i] = %f (v)
             end)
end

-- @func assign: Execute the elements of a table as global assignments
-- Assumes the indices are strings
--   @param t: table
function assign (t)
  foreach (t, setglobal)
end

-- @func clone: Make a shallow copy of a table, including any tag
--   @param t: table
-- returns
--   @param u: copy of table
function clone (t)
  local u = Table (tag (t))
  for i, v in t do
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
  for i, v in u do
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
                  if %gettm then
                    return %gettm (t, i)
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
                  if %settm then
                    %settm (t, i, v)
                  else
                    t[i] = v
                  end
                end)
end

-- Tag methods for tables
settagmethod (_TableTag, "add", merge) -- table + table = merge

-- @func defaultTable: Make a table with a different default value
--   @param x: default value
--   @param [t]: initial table
-- returns
--   @param u: table for which u[i] is x if u[i] does not exist
function defaultTable (x, t)
  t = t or {}
  local tTag = newtag ()
  settagmethod (tTag, "index",
                function (t, i)
                  return %x
                end)
  return settag (t, tTag)
end

-- Table of methods to make arbitrary objects (typically userdata)
-- into tables; used by tostring and pickle
-- Table entries are tag = function from object to table
tabulator = {}
