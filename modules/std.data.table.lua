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

-- subscript: Expose [] as a function
--   t: table
--   s: subscript
-- returns
--   v: t[s]
function subscript (t, s)
  return t[s]
end

-- Table: Make a new table of the given tag type
--   tTag: tag
-- returns
--   t: table with tag tTag
function Table (tTag)
  local t = {}
  if tTag ~= _TableTag then
    settag (t, tTag)
  end
  return t
end

-- indices: Make the list of indices of a table
--   t: table
-- returns
--   u: table of indices
function indices (t)
  return foreach (t,
                  function (i, _, u)
                    tinsert (u, i)
                  end)
end

-- values: Make the list of values of a table
--   t: table
-- returns
--   u: table of values
function values (t)
  return foreach (t,
                  function (_, v, u)
                    tinsert (u, v)
                  end)
end

-- permuteIter: Permute some keys of a table
--   it: iterator
--   p: table of oldkey=newkey
--   t: table to permute
-- returns
--   u: permuted table
function permuteIter (it, p, t)
  return it (t,
             function (i, v, u)
               u[%p[i] or i] = v
             end)
end

-- permute: Permute some keys of a table
--   p: table of oldkey=newkey
--   t: table to permute
-- returns
--   u: permuted table
permute = curry (permuteIter, foreach)

-- indexKeyIter: Make an index of a table of tables on a given field
--   it: iterator
--   f: field
--   t: table of tables {i1=t1 ... in=tn}
-- returns
--   ind: index {t1[f]=i1 ... tn[f]=in}
function indexKeyIter (it, f, t)
  return it (t,
             function (i, v, u)
               local k = v[%f]
               if k then
                 u[k] = i
               end
             end)
end

-- indexValueIter: Copy a table of tables, reindexed on a given field
--   it: iterator
--   f: field
--   t: table of tables {i1=t1 ... in=tn}
-- returns
--   ind: index {t1[f]=t1 ... tn[f]=tn}
function indexValueIter (it, f, t)
  return it (t,
             function (_, v, u)
               local k = v[%f]
               if k then
                 u[k] = v
               end
             end)
end

-- mapIter: Map a function over a table according to an iterator
--   it: iterator
--   f: function
--   t: table {i1=v1 ... in=vn}
-- returns
--   u: result table {i1=f (v1) ... in=f (vn)}
function mapIter (it, f, t)
  return it (t,
             function (i, v, u)
               u[i] = %f (v)
             end)
end

-- assign: Execute the elements of a table as global assignments
-- Assumes the keys are strings
--   t: table
function assign (t)
  foreach (t, setglobal)
end

-- clone: Make a shallow copy of a table, including any tag
--   t: table
-- returns
--   u: copy of table
function clone (t)
  local u = Table (tag (t))
  for i, v in t do
    u[i] = v
  end
  return u
end

-- merge: Merge two tables
-- If there are duplicate fields, u's will be used. The tag of the
-- returned table is that of t
--   t, u: tables
-- returns
--   r: the merged table
function merge (t, u)
  local r = clone (t)
  for i, v in u do
    r[i] = v
  end
  return r
end

-- methodify: Make a table type use custom per-field get/set methods
-- The settable and gettable methods of the given tag are modified so
-- that fields can have get and set methods added by putting an entry
-- in the _getset member of a table of that type. If the entry is a
-- table, it is assumed to be a table of the form {get = get tag method,
-- set = set tag method}, and the relevant method is called, just like
-- an ordinary tag method. Otherwise, the entry is used as an index to
-- the table; in this way, one table member can easily be made an
-- alias for another, allowing shorter names to be used. If there is
-- no entry, the previous tag method is used.
--   tTag: tag to methodify
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

-- defaultTable: Make a table with a different default value
--   x: default value
--   [t]: initial table
-- returns
--   u: table for which u[i] is x if u[i] does not exist
function defaultTable (x, t)
  t = t or {}
  local tTag = newtag ()
  settagmethod (tTag, "index",
                function (t, i)
                  return %x
                end)
  return settag (t, tTag)
end
