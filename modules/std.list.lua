-- @module List

require "std.base"
require "std.table"


-- @func math.max: Extend to work on lists
--   @param (l: list
--          ( or
--   @param (v1 ... @param vn: values
-- returns
--   @param m: max value
math.max = listable (math.max)

-- @func math.min: Extend to work on lists
--   @param (l: list
--          ( or
--   @param (v1 ... @param vn: values
-- returns
--   @param m: min value
math.min = listable (math.min)

-- @func map: Map a function over a list
--   @param f: function
--   @param l: list
-- returns
--   @param m: result list {f (l[1]) ... f (l[table.getn (l)])}
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
--   @param m: result list {f (unpack (ls[1]))) ...
--     f (unpack (ls[table.getn (ls)]))}
function mapWith (f, l)
  return map (compose (f, unpack), l)
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
  for _, v in ipairs (l) do
    if p (v) then
      table.insert (m, v)
    end
  end
  return m
end

-- @func mapjoin: Map a function over a list and concatenate the results
--   @param f: function returning a list
--   @param l: list
-- returns
--   @param m: result list {f (l[1]) .. f (l[table.getn (l)])}
function mapjoin (f, l)
  local m = {}
  for _, v in ipairs (l) do
    local r = f (v)
    for _, w in ipairs (r) do
      table.insert (m, w)
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
  local len = table.getn (l)
  if p < 0 then
    p = p + len + 1
  end
  if q < 0 then
    q = q + len + 1
  end
  for i = p, q do
    table.insert (m, l[i])
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
  for _, v = in ipairs (l) do
    r = f (r, v)
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
  for i = table.getn (l), 1, -1 do
    r = f (l[i], r)
  end
  return r
end

-- @func behead: Remove elements from the front of a list
--   @param l: list
--   @param [n]: number of elements to remove [1]
function behead (l, n)
  n = n or 1
  for i = 1, table.getn (l) do
    l[i] = l[i + n]
  end
end

-- @func concat: Concatenate two lists
--   @param l: list
--   @param m: list
-- returns
--   @param n: result {l[1] ... l[table.getn (l)], m[1] ...
--     m[table.getn (m)]}
function concat (l, m)
  local n = {}
  for _, v in ipairs (l) do
    table.insert (n, v)
  end
  for _, v in ipairs (m) do
    table.insert (n, v)
  end
  return n
end

-- @func reverse: Reverse a list
--   @param l: list
-- returns
--   @param m: list {l[table.getn (l)] ... l[1]}
function reverse (l)
  local m = {}
  for i = table.getn (l), 1, -1 do
    table.insert (m, l[i])
  end
  return m
end

-- @func rep: Repeat a list
-- The argument order is designed to make rep usable as a metamethod,
-- and to be compatible with string.rep
--   @param l: list
--   @param n: number of repetitions
-- returns
--   @param m: list {l[1] ... l[table.getn (l)] ... (n times)}
function rep (l, n)
  return mapjoin (function () return l end, {n=n})
end

-- @func transpose: Transpose a list of lists
--   @param ls: {{l11 ... l1c} ... {lr1 ... lrc}}
-- returns
--   @param ms: {{l11 ... lr1} ... {l1c ... lrc}}
-- Also give aliases zip and unzip
function transpose (ls)
  local ms, len = {}, table.getn (ls)
  for i = 1, math.max (map (table.getn, ls)) do
    ms[i] = {}
    for j = 1, len do
      ms[i][j] = ls[j][i]
    end
    ms[i].n = table.getn (ms[i])
  end
  return ms
end
zip = transpose
unzip = transpose

-- @func zipWith: Zip lists together with a function
--   @param f: function
--   @param ls: list of lists
-- returns
--   @param m: {f (ls[1][1] ... ls[table.getn (ls)][1]) ...
--              f (ls[1][N] ... ls[table.getn (ls)][N])
--     where N = max {map (table.getn, ls)}
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
  for i, v in pairs (t) do
    table.insert (ls, {i, v})
  end
  return ls
end

-- @func depair: Turn a list of pairs into a table
--   @param ls: list {{i1, v1} ... {in, vn}}
-- returns
--   @param t: table {i1=v1 ... in=vn}
function depair (ls)
  local t = {}
  for _, v in ipairs (ls) do
    t[v[1]] = v[2]
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

-- @func listLcs: Find the longest common subsequence of two lists
-- TODO: Rename list.lcs
--   @param a, b: lists
-- returns
--   @param l: LCS of a and b
function listLcs (a, b)
  return lcs.leastCommonSeq (a, b, table.subscript, table.getn,
                             function (t, e)
                               table.insert (t, e)
                               return t
                             end,
                             {})
end

-- listable: Make a function which can take its arguments as a list
--   f: function (if it only takes one argument, it must not be a
--     table)
-- returns
--   g: function that can take its arguments either as normal or in a
--     list
function listable (f)
  return function (...)
           if table.getn (arg) == 1 and type (arg[1]) == "table" then
             return f (unpack (arg[1]))
           else
             return f (unpack (arg))
           end
         end
end

-- @head Metamethods for lists
-- TODO: Have a List type that uses these
-- List.unm = reverse -- - list = reverse
-- List.mul = rep -- list * number = rep
-- List.concat = concat -- list .. list = concat
