-- Lists

require "std/data/code.lua"
require "std/data/table.lua"


-- max: Extend to work on lists
--   (l: list
--   ( or
--   (v1 ... vn: values
-- returns
--   m: max value
max = listable (max)

-- min: Extend to work on lists
--   (l: list
--   ( or
--   (v1 ... vn: values
-- returns
--   m: min value
min = listable (min)

-- map: Map a function over a list
--   f: function
--   l: list
-- returns
--   m: result list {f (l[1]) ... f (l[getn (l)])}
function map (f, l)
  local m = mapIter (foreachi, f, l)
  m.n = getn (m)
  return m
end

-- mapWith: Map a function over a list of lists
--   f: function
--   ls: list of lists
-- returns
--   m: result list {call (f, ls[1]) ... call (f, ls[getn (ls)])}
function mapWith (f, l)
  return map (curry (call, f), l)
end

-- filter: Filter a list according to a predicate
--   p: predicate
--     a: argument
--   returns
--     f: flag (nil for false, non-nil for true)
--   l: list
-- returns
--   m: result list containing elements e of l for which p (e) is true
function filter (p, l)
  local m = {}
  for i = 1, getn (l) do
    if p (l[i]) then
      tinsert (m, l[i])
    end
  end
  return m
end

-- mapjoin: Map a function over a list and concatenate the results
--   f: function returning a list
--   l: list
-- returns
--   m: result list {f (l[1]) .. f (l[getn (l)])}
function mapjoin (f, l)
  local m = {}
  for i = 1, getn (l) do
    local r = f (l[i])
    for j = 1, getn (r) do
      tinsert (m, r[j])
    end
  end
  return m
end

-- slice: Slice a list
--   l: list
--   p, q: start and end of slice
-- returns
--   m: {l[p] ... l[q]}
function slice (l, p, q)
  local m = {}
  local len = getn (l)
  if p < 0 then
    p = p + len + 1
  end
  if q < 0 then
    q = q + len + 1
  end
  for i = p, q do
    tinsert (m, l[i])
  end
  return m
end

-- foldl: Fold a binary function through a list left associatively
--   f: function
--   e: element to place in left-most position
--   l: list
-- returns
--   r: result
function foldl (f, e, l)
  local r = e
  for i = 1, getn (l) do
    r = f (r, l[i])
  end
  return r
end

-- foldr: Fold a binary function through a list right associatively
--   f: function
--   e: element to place in right-most position
--   l: list
-- returns
--   r: result
function foldr (f, e, l)
  local r = e
  for i = getn (l), 1, -1 do
    r = f (l[i], r)
  end
  return r
end

-- behead: Remove elements from the front of a list
--   l: list
--   [n]: number of elements to remove [1]
function behead (l, n)
  n = n or 1
  for i = 1, getn (l) do
    l[i] = l[i + n]
  end
end

-- concat: Concatenate two lists
--   l: list
--   m: list
-- returns
--   n: result {l[1] ... l[getn (l)], m[1] ... m[getn (m)]}
function concat (l, m)
  local n = {}
  for i = 1, getn (l) do
    tinsert (n, l[i])
  end
  for i = 1, getn (m) do
    tinsert (n, m[i])
  end
  return n
end

-- reverse: Reverse a list
--   l: list
-- returns
--   m: list {l[getn (l)] ... l[1]}
function reverse (l)
  local m = {}
  for i = getn (l), 1, -1 do
    tinsert (m, l[i])
  end
  return m
end

-- rep: Repeat a list
-- The argument order is designed to make rep usable as a tag method,
-- and to be compatible with strrep
--   l: list
--   n: number of repetitions
-- returns
--   m: list {l[1] ... l[getn (l)] ... (n times)}
function rep (l, n)
  return mapjoin (function () return %l end, {n=n})
end

-- transpose: Transpose a list of lists
--   ls: {{l11 ... l1c} ... {lr1 ... lrc}}
-- returns
--   ms: {{l11 ... lr1} ... {l1c ... lrc}}
-- Also give aliases zip and unzip
function transpose (ls)
  local ms, len = {}, getn (ls)
  for i = 1, max (map (getn, ls)) do
    ms[i] = {}
    for j = 1, len do
      ms[i][j] = ls[j][i]
    end
    ms[i].n = getn (ms[i])
  end
  return ms
end
zip = transpose
unzip = transpose

-- zipWith: Zip lists together with a function
--   f: function
--   ls: list of lists
-- returns
--   m: {f (ls[1][1] ... ls[getn (ls)][1]) ...
--         f (ls[1][N] ... ls[getn (ls)][N])
--   where N = max {map (getn, ls)}
function zipWith (f, ls)
  return mapWith (f, zip (ls))
end

-- project: Project a list of fields from a list of tables
--   f: field to project
--   l: list of tables
-- returns
--   m: list of f fields
function project (f, l)
  return map (function (t) return t[%f] end, l)
end

-- enpair: Turn a table into a list of pairs
--   t: table {i1=v1 ... in=vn}
-- returns
--   ls: list {{i1, v1} ... {in, vn}}
function enpair (t)
  local ls = {}
  for i, v in t do
    tinsert (ls, {i, v})
  end
  return ls
end

-- depair: Turn a list of pairs into a table
--   ls: list {{i1, v1} ... {in, vn}}
-- returns
--   t: table {i1=v1 ... in=vn}
function depair (ls)
  local t = {}
  for i = 1, getn (ls) do
    t[ls[i][1]] = ls[i][2]
  end
  return t
end

-- flatten: Turn a list of lists into a list
--   ls: list {{...} ... {...}}
-- returns
--   l: list {...}
function flatten (ls)
  return foldr (concat, {},
                filter (function (x)
                          return x ~= nil
                        end,
                        ls))
end

-- indexKey: Make an index of a list of tables on a given field
--   f: field
--   l: list of tables {t1 ... tn}
-- returns
--   ind: index {t1[f]=1 ... tn[f]=n}
indexKey = curry (indexKeyIter, foreachi)

-- indexValue: Copy a list of tables, indexed on a given field
--   f: field whose value should be used as key
--   l: list of tables {i1=t1 ... in=tn}
-- returns
--   m: index {t1[f]=t1 ... tn[f]=tn}
indexValue = curry (indexValueIter, foreachi)
permuteOn = indexValue

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

-- Tag methods for lists
settagmethod (_TableTag, "unm", reverse) -- - list = reverse
settagmethod (_TableTag, "mul", rep) -- list * number = rep
settagmethod (_TableTag, "concat", concat) -- list .. list = concat
