-- @module List

require "std.data.code"
require "std.data.table"


-- @func max: Extend to work on lists
--   @param (l: list
--          ( or
--   @param (v1 ... @param vn: values
-- returns
--   @param m: max value
max = listable (max)

-- @func min: Extend to work on lists
--   @param (l: list
--          ( or
--   @param (v1 ... @param vn: values
-- returns
--   @param m: min value
min = listable (min)

-- @func map: Map a function over a list
--   @param f: function
--   @param l: list
-- returns
--   @param m: result list {f (l[1]) ... f (l[getn (l)])}
function map (f, l)
  local m = {}
  for i, v in ipairs (l) do
    m[i] = f (v)
  end
  table.setn (m, table.getn (l))
  return m
end

-- @func mapWith: Map a function over a list of lists
--   @param f: function
--   @param ls: list of lists
-- returns
--   @param m: result list {call (f, ls[1]) ... call (f, ls[getn
--     (ls)])}
function mapWith (f, l)
  return map (curry (call, f), l)
end

-- @func filter: Filter a list according to a predicate
--   @param p: predicate
--     @param a: argument
--   returns
--     @param f: flag (nil for false, non-nil for true)
--   @param l: list
-- returns
--   @param m: result list containing elements e of l for which p (e)
--     is true
function filter (p, l)
  local m = {}
  for i = 1, getn (l) do
    if p (l[i]) then
      tinsert (m, l[i])
    end
  end
  return m
end

-- @func mapjoin: Map a function over a list and concatenate the results
--   @param f: function returning a list
--   @param l: list
-- returns
--   @param m: result list {f (l[1]) .. f (l[getn (l)])}
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

-- @func slice: Slice a list
--   @param l: list
--   @param p, @param q: start and end of slice
-- returns
--   @param m: {l[p] ... l[q]}
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

-- @func foldl: Fold a binary function through a list left associatively
--   @param f: function
--   @param e: element to place in left-most position
--   @param l: list
-- returns
--   @param r: result
function foldl (f, e, l)
  local r = e
  for i = 1, getn (l) do
    r = f (r, l[i])
  end
  return r
end

-- @func foldr: Fold a binary function through a list right associatively
--   @param f: function
--   @param e: element to place in right-most position
--   @param l: list
-- returns
--   @param r: result
function foldr (f, e, l)
  local r = e
  for i = getn (l), 1, -1 do
    r = f (l[i], r)
  end
  return r
end

-- @func behead: Remove elements from the front of a list
--   @param l: list
--   @param [n]: number of elements to remove [1]
function behead (l, n)
  n = n or 1
  for i = 1, getn (l) do
    l[i] = l[i + n]
  end
end

-- @func concat: Concatenate two lists
--   @param l: list
--   @param m: list
-- returns
--   @param n: result {l[1] ... l[getn (l)], m[1] ... m[getn (m)]}
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

-- @func reverse: Reverse a list
--   @param l: list
-- returns
--   @param m: list {l[getn (l)] ... l[1]}
function reverse (l)
  local m = {}
  for i = getn (l), 1, -1 do
    tinsert (m, l[i])
  end
  return m
end

-- @func rep: Repeat a list
-- The argument order is designed to make rep usable as a tag method,
-- and to be compatible with strrep
--   @param l: list
--   @param n: number of repetitions
-- returns
--   @param m: list {l[1] ... l[getn (l)] ... (n times)}
function rep (l, n)
  return mapjoin (function () return l end, {n=n})
end

-- @func transpose: Transpose a list of lists
--   @param ls: {{l11 ... l1c} ... {lr1 ... lrc}}
-- returns
--   @param ms: {{l11 ... lr1} ... {l1c ... lrc}}
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

-- @func zipWith: Zip lists together with a function
--   @param f: function
--   @param ls: list of lists
-- returns
--   @param m: {f (ls[1][1] ... ls[getn (ls)][1]) ...
--              f (ls[1][N] ... ls[getn (ls)][N])
--     where N = max {map (getn, ls)}
function zipWith (f, ls)
  return mapWith (f, zip (ls))
end

-- @func project: Project a list of fields from a list of tables
--   @param f: field to project
--   @param l: list of tables
-- returns
--   @param m: list of f fields
function project (f, l)
  return map (function (t) return t[f] end, l)
end

-- @func enpair: Turn a table into a list of pairs
--   @param t: table {i1=v1 ... in=vn}
-- returns
--   @param ls: list {{i1, v1} ... {in, vn}}
function enpair (t)
  local ls = {}
  for i, v in t do
    tinsert (ls, {i, v})
  end
  return ls
end

-- @func depair: Turn a list of pairs into a table
--   @param ls: list {{i1, v1} ... {in, vn}}
-- returns
--   @param t: table {i1=v1 ... in=vn}
function depair (ls)
  local t = {}
  for i = 1, getn (ls) do
    t[ls[i][1]] = ls[i][2]
  end
  return t
end

-- @func flatten: Turn a list of lists into a list
--   @param ls: list {{...} ... {...}}
-- returns
--   @param l: list {...}
function flatten (ls)
  return foldr (concat, {},
                filter (function (x)
                          return x ~= nil
                        end,
                        ls))
end

-- @func indexKey: Make an index of a list of tables on a given field
--   @param f: field
--   @param l: list of tables {t1 ... tn}
-- returns
--   @param ind: index {t1[f]=1 ... tn[f]=n}
function indexKey (f, t)
  return table.foreachi (t,
                         function (i, v, u)
                           local k = v[f]
                           if k then
                             u[k] = i
                           end
                         end)
end

-- @func indexValue: Copy a list of tables, indexed on a given field
--   @param f: field whose value should be used as index
--   @param l: list of tables {i1=t1 ... in=tn}
-- returns
--   @param m: index {t1[f]=t1 ... tn[f]=tn}
function indexValue (f, t)
  return table.foreachi (t,
                         function (_, v, u)
                           local k = v[f]
                           if k then
                             u[k] = v
                           end
                         end)
end
permuteOn = indexValue

-- @head Tag methods for lists
-- TODO: Have a List type that uses these
-- - list = reverse
-- settagmethod (_TableTag, "unm", reverse)
-- list * number = rep
-- settagmethod (_TableTag, "mul", rep)
-- list .. list = concat
-- settagmethod (_TableTag, "concat", concat)
