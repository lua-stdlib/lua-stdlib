-- @module List

require "std.base"
require "std.table"


list = {}

-- @func list.cons: Prepend an item to a list
--   @param x: item
--   @param l: list
-- @returns
--   @param r: {x, unpack (l)}
function list.cons (x, l)
  return {x, unpack (l)}
end

-- @func list.append: Append an item to a list
--   @param x: item
--   @param l: list
-- @returns
--   @param r: {unpack (l), x}
function list.append (x, l)
  return {unpack (l), x}
end

-- @func list.map: Map a function over a list
--   @param f: function
--   @param l: list
-- @returns
--   @param m: result list {f (l[1]) ... f (l[table.getn (l)])}
function list.map (f, l)
  return table.process (ipairs, table.mapItem (f), {}, l)
end

-- @func list.mapWith: Map a function over a list of lists
--   @param f: function
--   @param ls: list of lists
-- @returns
--   @param m: result list {f (unpack (ls[1]))) ...
--     f (unpack (ls[table.getn (ls)]))}
function list.mapWith (f, l)
  return list.map (compose (f, unpack), l)
end

-- @func list.filter: Filter a list according to a predicate
--   @param p: predicate
--     @param a: argument
--   @returns
--     @param f: flag
--   @param l: list of lists
-- @returns
--   @param m: result list containing elements e of l for which p (e)
--     is true
function list.filter (p, l)
  return table.process (ipairs,
                        function (p)
                          return function (a, i, v)
                                   if p (v) then
                                     table.insert (a, v)
                                   end
                                   return a
                                 end
                        end,
                        {},
                        l)
end

-- @func list.slice: Slice a list
--   @param l: list
--   @param [from], @param [to]: start and end of slice
--     from defaults to 1 and to to table.getn (l);
--     negative values count from the end
-- @returns
--   @param m: {l[from] ... l[to]}
function list.slice (l, from, to)
  local m = {}
  local len = table.getn (l)
  from = from or 1
  to = to or len
  if from < 0 then
    from = from + len + 1
  end
  if to < 0 then
    to = to + len + 1
  end
  for i = from, to do
    table.insert (m, l[i])
  end
  return m
end

-- @func list.tail: Return a list with its first element removed
--   @param l: list
-- @returns
--   @param m: {l[2] ... l[table.getn (l)]}
function list.tail (l)
  return list.slice (l, 2)
end

-- @func list.foldl: Fold a binary function through a list left
-- associatively
--   @param f: function
--   @param e: element to place in left-most position
--   @param l: list
-- @returns
--   @param r: result
function list.foldl (f, e, l)
  return table.process (ipairs, table.foldlItem (f), e, l)
end

-- @func list.foldr: Fold a binary function through a list right
-- associatively
--   @param f: function
--   @param e: element to place in right-most position
--   @param l: list
-- @returns
--   @param r: result
function list.foldr (f, e, l)
  return table.process (ripairs, table.foldrItem (f), e, l)
end

-- @func list.concat: Concatenate lists
--   @param l1, l2, ... ln: lists
-- @returns
--   @param r: result {l1[1] ... l1[table.getn (l1)], ... ,
--                     ln[1] ... ln[table.getn (ln)]}
function list.concat (...)
  local r = {}
  for _, l in ipairs (arg) do
    for _, v in ipairs (l) do
      table.insert (r, v)
    end
  end
  return r
end
list.flatten = list.concat

-- @func list.reverse: Reverse a list
--   @param l: list
-- @returns
--   @param m: list {l[table.getn (l)] ... l[1]}
function list.reverse (l)
  local m = {}
  for i = table.getn (l), 1, -1 do
    table.insert (m, l[i])
  end
  return m
end

-- @func list.transpose: Transpose a list of lists
--   @param ls: {{l11 ... l1c} ... {lr1 ... lrc}}
-- @returns
--   @param ms: {{l11 ... lr1} ... {l1c ... lrc}}
-- Also give aliases list.zip and list.unzip
function list.transpose (ls)
  local ms, len = {}, table.getn (ls)
  for i = 1, math.max (list.map (table.getn, ls)) do
    ms[i] = {}
    for j = 1, len do
      ms[i][j] = ls[j][i]
    end
    ms[i].n = table.getn (ms[i])
  end
  return ms
end
list.zip = list.transpose
list.unzip = list.transpose

-- @func list.zipWith: Zip lists together with a function
--   @param f: function
--   @param ls: list of lists
-- @returns
--   @param m: {f (ls[1][1] ... ls[table.getn (ls)][1]) ...
--              f (ls[1][N] ... ls[table.getn (ls)][N])
--     where N = max {list.map (table.getn, ls)}
function list.zipWith (f, ls)
  return list.mapWith (f, list.zip (ls))
end

-- @func list.project: Project a list of fields from a list of tables
--   @param f: field to project
--   @param l: list of tables
-- @returns
--   @param m: list of f fields
function list.project (f, l)
  return list.map (function (t) return t[f] end, l)
end

-- @func list.enpair: Turn a table into a list of pairs
--   @param t: table {i1=v1 ... in=vn}
-- @returns
--   @param ls: list {{i1, v1} ... {in, vn}}
function list.enpair (t)
  local ls = {}
  for i, v in pairs (t) do
    table.insert (ls, {i, v})
  end
  return ls
end

-- @func list.depair: Turn a list of pairs into a table
--   @param ls: list {{i1, v1} ... {in, vn}}
-- @returns
--   @param t: table {i1=v1 ... in=vn}
function list.depair (ls)
  local t = {}
  for _, v in ipairs (ls) do
    t[v[1]] = v[2]
  end
  return t
end

-- @func list.indexKey: Make an index of a list of tables on a given
-- field
--   @param f: field
--   @param l: list of tables {t1 ... tn}
-- @returns
--   @param ind: index {t1[f]=1 ... tn[f]=n}
function list.indexKey (f, l)
  return table.process (ipairs,
                        function (a, i, v)
                          local k = v[f]
                          if k then
                            a[k] = i
                          end
                        end,
                        {}, l)
end

-- @func list.indexValue: Copy a list of tables, indexed on a given
-- field
--   @param f: field whose value should be used as index
--   @param l: list of tables {i1=t1 ... in=tn}
-- @returns
--   @param m: index {t1[f]=t1 ... tn[f]=tn}
function list.indexValue (f, l)
  return table.process (ipairs,
                        function (a, _, v)
                          local k = v[f]
                          if k then
                            a[k] = v
                          end
                        end,
                        {}, l)
end
list.permuteOn = list.indexValue

-- @func list.lcs: Find the longest common subsequence of two lists
--   @param a, b: lists
-- @returns
--   @param l: LCS of a and b
function list.lcs (a, b)
  return lcs.leastCommonSeq (a, b, table.subscript, table.getn,
                             function (t, e)
                               table.insert (t, e)
                               return t
                             end,
                             {})
end

-- @head Metamethods for lists
-- TODO: Set default metamethods:
-- __unm = list.reverse
-- __mul = list.repeat
-- __concat = list.concat
