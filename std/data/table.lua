-- Tables

-- TODO: Make more combinators take iterators (e.g. indices, values)
-- TODO: Write filterIter, mapWithIter
-- TODO: Write listify which passes foreachi as the first argument of
--   an iterator combinator, and nify which makes a function that adds
--   an n field to the result of another function. Use these to make
--   list versions of combinators more easily.

require "std/patch40.lua"
require "std/data/code.lua"
require "std/data/list.lua"
require "std/text/regex.lua"


-- Vanilla table tag
_TableTag = tag ({})

-- subscript: expose [] as a function
--   t: table
--   s: subscript
-- returns
--   v: t[s]
function subscript (t, s)
  return t[s]
end

-- pathSubscript: subscript a table with a string containing dots
--   t: table
--   s: subscript of the form s1.s2. ... .sn
-- returns
--   v: t.s1.s2. ... .sn
function pathSubscript (t, s)
  return foldl (subscript, t, split ("%.", s))
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

-- mapIter: Map a function over a table
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

-- assign: Execute the elements of a table as assignments
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
                      return t[t._getset[i]]
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

-- lookup: Do a late-bound table lookup
--   t: table to look up in
--   l: list of indices {l1 ... ln}
-- returns
--   u: t[l1]...[ln]
function lookup (t, l)
  for i = 1, getn (l) do
    t = t[l[i]]
  end
  return t
end
