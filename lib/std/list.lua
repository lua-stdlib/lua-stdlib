--[[--
 Tables as lists.

 Every list is also an object, and thus inherits all of the `std.object`
 methods, particularly use of object cloning for making new list objects.

 In addition to calling methods on list objects in OO style...

     local list = require "std.list"  -- module table
     local List = list {}             -- prototype object
     local l = List {"foo", "bar"}
     for e in ielems (l:append ("baz")) do print (e) end
       => foo
       => bar
       => baz

 ... some can also be called as module functions with an explicit list
 argument in the first or last parameter, check the documentation for
 details:

     for e in ielems (list.append (l, "quux")) do print (e) end
       => foo
       => bar
       => quux

 @classmod std.list
]]


local base    = require "std.base"
local func    = require "std.functional"
local object  = require "std.object"

local Object  = object {}
local List      -- forward declaration

local ipairs, pairs = base.ipairs, base.pairs
local argerror, argscheck, export, ielems, prototype, ireverse =
  base.argerror, base.argscheck, base.export, base.ielems, base.prototype, base.ireverse
local foldl, foldr = base.functional.foldl, base.functional.foldr

local M = { "std.list" }


------
-- An Object derived List.
-- @table List

--- Append an item to a list.
-- @static
-- @function append
-- @tparam List l a list
-- @param x item
-- @treturn List new list containing `{l[1], ..., l[#l], x}`
local append = export (M, "append (List, any)", function (l, x)
  local r = l {}
  r[#r + 1] = x
  return r
end)


--- Compare two lists element-by-element, from left-to-right.
--
--     if a_list:compare (another_list) == 0 then print "same" end
-- @static
-- @function compare
-- @tparam List l a list
-- @tparam table m another list
-- @return -1 if `l` is less than `m`, 0 if they are the same, and 1
--   if `l` is greater than `m`
local compare = export (M, "compare (List, List|table)", function (l, m)
  for i = 1, math.min (#l, #m) do
    local li, mi = tonumber (l[i]), tonumber (m[i])
    if li == nil or mi == nil then
      li, mi = l[i], m[i]
    end
    if li < mi then
      return -1
    elseif li > mi then
      return 1
    end
  end
  if #l < #m then
    return -1
  elseif #l > #m then
    return 1
  end
  return 0
end)


--- Concatenate arguments into a list.
-- @static
-- @function concat
-- @tparam List l a list
-- @param ... tuple of lists
-- @treturn List new list containing
--   `{l[1], ..., l[#l], l\_1[1], ..., l\_1[#l\_1], ..., l\_n[1], ..., l\_n[#l\_n]}`
local concat = export (M, "concat (List, List|table*)", function (l, ...)
  local r = List {}
  for e in ielems {l, ...} do
    for v in ielems (e) do
      r[#r + 1] = v
    end
  end
  return r
end)


--- Prepend an item to a list.
-- @static
-- @function cons
-- @tparam List l a list
-- @param x item
-- @treturn List new list containing `{x, unpack (l)}`
M.cons = function (x, l)
  if prototype (x) == "List" and prototype (l) ~= "List" then
    if not base.getcompat (M.cons) then
      io.stderr:write (base.DEPRECATIONMSG ("41",
                       "'std.list.cons' with list argument first", 2))
      base.setcompat (M.cons)
    end
    x, l = l, x
  end
  argscheck ("std.list.cons", {"any", "List?"}, {x, l})

  return List {x, unpack (l or {})}
end


--- Turn a list of pairs into a table.
-- @todo Find a better name.
-- @static
-- @function depair
-- @tparam  table ls list of lists `{{i1, v1}, ..., {in, vn}}`
-- @treturn table a new list containing table `{i1=v1, ..., in=vn}`
-- @see enpair
local depair = export (M, "depair (List of Lists)", function (ls)
  local t = {}
  for v in ielems (ls) do
    t[v[1]] = v[2]
  end
  return t
end)


--- Turn a table into a list of pairs.
-- @todo Find a better name.
-- @static
-- @function enpair
-- @tparam  table t  a table `{i1=v1, ..., in=vn}`
-- @treturn List a new list containing `{{i1, v1}, ..., {in, vn}}`
-- @see depair
export (M, "enpair (table)", function (t)
  local ls = List {}
  for i, v in pairs (t) do
    ls[#ls + 1] = List {i, v}
  end
  return ls
end)


--- Filter a list according to a predicate.
-- @static
-- @function filter
-- @func p predicate function, of one argument returning a boolean
-- @tparam List l a list
-- @treturn List new list containing elements `e` of `l` for which
--   `p (e)` is true
-- @see std.list:filter
local filter = export (M, "filter (function, List)", function (p, l)
  return List (func.filter (p, ielems, l))
end)


--- Flatten a list.
-- @static
-- @function flatten
-- @tparam List l a list
-- @treturn List flattened list
local flatten = export (M, "flatten (List)", function (l)
  return List (func.collect (base.leaves, ipairs, l))
end)


--- Project a list of fields from a list of tables.
-- @static
-- @function project
-- @param f field to project
-- @tparam List l a list of tables
-- @treturn List list of `f` fields
-- @see std.list:project
local project = export (M, "project (any, List of tables)", function (f, l)
  return List (func.map (function (t) return t[f] end, ielems, l))
end)


--- Repeat a list.
-- @static
-- @function rep
-- @tparam List l a list
-- @int n number of times to repeat
-- @treturn List `n` copies of `l` appended together
local rep = export (M, "rep (List, int)", function (l, n)
  local r = List {}
  for i = 1, n do
    r = concat (r, l)
  end
  return r
end)


--- Shape a list according to a list of dimensions.
--
-- Dimensions are given outermost first and items from the original
-- list are distributed breadth first; there may be one 0 indicating
-- an indefinite number. Hence, `{0}` is a flat list,
-- `{1}` is a singleton, `{2, 0}` is a list of
-- two lists, and `{0, 2}` is a list of pairs.
--
-- Algorithm: turn shape into all positive numbers, calculating
-- the zero if necessary and making sure there is at most one;
-- recursively walk the shape, adding empty tables until the bottom
-- level is reached at which point add table items instead, using a
-- counter to walk the flattened original list.
--
-- @todo Use ileaves instead of flatten (needs a while instead of a
-- for in fill function)
-- @static
-- @function shape
-- @tparam table s `{d1, ..., dn}`
-- @tparam List l a list
-- @return reshaped list
-- @see std.list:shape
local shape = export (M, "shape (table, List)", function (s, l)
  l = flatten (l)
  -- Check the shape and calculate the size of the zero, if any
  local size = 1
  local zero
  for i, v in ipairs (s) do
    if v == 0 then
      if zero then -- bad shape: two zeros
        return nil
      else
        zero = i
      end
    else
      size = size * v
    end
  end
  if zero then
    s[zero] = math.ceil (#l / size)
  end
  local function fill (i, d)
    if d > #s then
      return l[i], i + 1
    else
      local r = List {}
      for j = 1, s[d] do
        local e
        e, i = fill (i, d + 1)
        r[#r + 1] = e
      end
      return r, i
    end
  end
  return (fill (1, 1))
end)


--- Return a sub-range of a list.
-- (The equivalent of `string.sub` on strings; negative list indices
-- count from the end of the list.)
-- @static
-- @function sub
-- @tparam List l a list
-- @int from start of range (default: 1)
-- @int to end of range (default: `#l`)
-- @treturn List new list containing `{l[from], ..., l[to]}`
local sub = export (M, "sub (List, int?, int?)", function (l, from, to)
  local r = List {}
  local len = #l
  from = from or 1
  to = to or len
  if from < 0 then
    from = from + len + 1
  end
  if to < 0 then
    to = to + len + 1
  end
  for i = from, to do
    r[#r + 1] = l[i]
  end
  return r
end)


--- Return a list with its first element removed.
-- @static
-- @function tail
-- @tparam List l a list
-- @treturn List new list containing `{l[2], ..., l[#l]}`
local tail = export (M, "tail (List)", function (l)
  return sub (l, 2)
end)


--- Transpose a list of lists.
-- This function in Lua is equivalent to zip and unzip in more strongly
-- typed languages.
-- @static
-- @function transpose
-- @tparam table ls
-- `{{ls<1,1>, ..., ls<1,c>}, ..., {ls&lt;r,1>, ..., ls&lt;r,c>}}`
-- @treturn List new list containing
-- `{{ls<1,1>, ..., ls&lt;r,1>}, ..., {ls<1,c>, ..., ls&lt;r,c>}}`
local transpose = export (M, "transpose (List of Lists)", function (ls)
  local rs, len, dims = List {}, base.len (ls), func.map (base.len, ielems, ls)
  if #dims > 0 then
    for i = 1, math.max (unpack (dims)) do
      rs[i] = List {}
      for j = 1, len do
        rs[i][j] = ls[j][i]
      end
    end
  end
  return rs
end)


--- Zip a list of lists together with a function.
-- @static
-- @function zip_with
-- @tparam  table    ls list of lists
-- @tparam  function fn function
-- @treturn List    a new list containing
--   `{f (ls[1][1], ..., ls[#ls][1]), ..., f (ls[1][N], ..., ls[#ls][N])`
-- where `N = max {map (function (l) return #l end, ls)}`

local function map_with (fn, ls)
  return List (func.map (func.compose (unpack, fn), ielems, ls))
end

local zip_with = export (M, "zip_with (List of Lists, function)", function (ls, fn)
  return map_with (fn, transpose (ls))
end)



--[[ ============= ]]--
--[[ Deprecations. ]]--
--[[ ============= ]]--


local DEPRECATED = base.DEPRECATED


M.elems = DEPRECATED ("41", "'std.list.elems'",
  "use 'std.ielems' instead", base.ielems)


local function relems (l) return base.ielems (base.ireverse (l)) end

M.relems = DEPRECATED ("41", "'std.list.relems'",
  "compose 'std.ielems' and 'std.ireverse' instead", relems)


M.foldl = DEPRECATED ("41", "'std.list.foldl'",
  "use 'std.functional.foldl' instead", foldl)


M.foldr = DEPRECATED ("41", "'std.list.foldr'",
  "use 'std.functional.foldr' instead", foldr)


local function index_key (f, l)
  local r = {}
  for i, v in ipairs (l) do
    local k = v[f]
    if k then
      r[k] = i
    end
  end
  return r
end

M.index_key = DEPRECATED ("41", "'std.list.index_key'",
  "compose 'std.list.filter' and 'std.table.invert' instead", index_key)


local function index_value (f, l)
  local r = {}
  for i, v in ipairs (l) do
    local k = v[f]
    if k then
      r[k] = v
    end
  end
  return r
end

M.index_value = DEPRECATED ("41", "'std.list.index_value'",
  "compose 'std.list.filter' and 'std.table.invert' instead", index_value)


local function map (fn, l) return List (func.map (fn, ielems, l)) end

M.map = DEPRECATED ("41", "'std.list.map'",
  "use 'std.functional.map' instead", map)


M.map_with = DEPRECATED ("41", "'std.list.map_with'",
   "use 'std.functional.map_with' instead", map_with)


local function reverse (l) return List (ireverse (l)) end

M.reverse = DEPRECATED ("41", "'std.list.reverse'",
  "use 'std.ireverse' instead", reverse)



List = Object {
  -- Derived object type.
  _type = "List",


  ------
  -- Concatenate lists.
  --     new = list .. table
  -- @function __concat
  -- @tparam List list a list
  -- @tparam table    table another list, hash part is ignored
  -- @see concat
  __concat = concat,

  ------
  -- Append element to list.
  --     list = list + element
  -- @function __add
  -- @tparam List list a list
  -- @param           element element to append
  -- @see append
  __add    = append,

  ------
  -- List order operator.
  --     max = list1 > list2 and list1 or list2
  -- @tparam List list1 a list
  -- @tparam List list2 another list
  -- @see std.list:compare
  __lt = function (list1, list2) return compare (list1, list2) < 0 end,

  ------
  -- List equality or order operator.
  --     min = list1 <= list2 and list1 or list2
  -- @tparam List list1 a list
  -- @tparam List list2 another list
  -- @see std.list:compare
  __le = function (list1, list2) return compare (list1, list2) <= 0 end,

  __index = {
    ------
    -- Append an item to a list.
    -- @function append
    -- @param x item
    -- @treturn List new list containing `{self[1], ..., self[#self], x}`
    append = append,

    ------
    -- Compare two lists element-by-element, from left-to-right.
    --
    --     if a_list:compare (another_list) == 0 then print "same" end
    -- @function compare
    -- @tparam table l a list
    -- @return -1 if `self` is less than `l`, 0 if they are the same, and 1
    --   if `self` is greater than `l`
    compare = compare,

    ------
    -- Concatenate arguments into a list.
    -- @function concat
    -- @param ... tuple of lists
    -- @treturn List new list containing
    --   `{self[1], ..., self[#self], l\_1[1], ..., l\_1[#l\_1], ..., l\_n[1], ..., l\_n[#l\_n]}`
    concat = concat,

    ------
    -- Prepend an item to a list.
    -- @function cons
    -- @param x item
    -- @treturn List new list containing `{x, unpack (self)}`
    cons = function (self, x) return M.cons (x, self) end,

    ------
    -- Filter a list according to a predicate.
    -- @function filter
    -- @func p predicate function, of one argument returning a boolean
    -- @treturn List new list containing elements `e` of `self` for which
    --   `p (e)` is true
    -- @see std.list.filter
    filter = function (self, p) return filter (p, self) end,

    ------
    -- Flatten a list.
    -- @function flatten
    -- @treturn List flattened list
    flatten = flatten,

    ------
    -- Map a function over a list.
    -- @function map
    -- @func fn map function
    -- @treturn List new list containing
    --   `{fn (self[1]), ..., fn (self[#self])}`
    -- @see std.list.map
    map = function (self, fn) return map (fn, self) end,

    ------
    -- Project a list of fields from a list of tables.
    -- @function project
    -- @param f field to project
    -- @treturn List list of `f` fields
    -- @see std.list.project
    project = function (self, f) return project (f, self) end,

    ------
    -- Repeat a list.
    -- @function rep
    -- @int n number of times to repeat
    -- @treturn List `n` copies of `self` appended together
    rep = rep,

    -----
    -- Shape a list according to a list of dimensions.
    -- @function shape
    -- @tparam table s `{d1, ..., dn}`
    -- @return reshaped list
    -- @see std.list.shape
    shape = function (self, s) return shape (s, self) end,

    ------
    -- Return a sub-range of a list.
    -- (The equivalent of `string.sub` on strings; negative list indices
    -- count from the end of the list.)
    -- @function sub
    -- @int from start of range (default: 1)
    -- @int to end of range (default: `#self`)
    -- @treturn List new list containing `{self[from], ..., self[to]}`
    sub = sub,

    ------
    -- Return a list with its first element removed.
    -- @function tail
    -- @treturn List new list containing `{self[2], ..., self[#self]}`
    tail = tail,

    ------
    depair    = DEPRECATED ("38", "'std.list:depair'",    depair),
    map_with  = DEPRECATED ("38", "'std.list:map_with'",
                  function (self, fn) return map_with (fn, self) end),
    transpose = DEPRECATED ("38", "'std.list:transpose'", transpose),
    zip_with  = DEPRECATED ("38", "'std.list:zip_with'",  zip_with),

    elems       = DEPRECATED ("41", "'std.list:elems'", base.ielems),
    foldl       = DEPRECATED ("41", "'std.list:foldl'",
                    "use 'std.functional.foldl' instead",
		    function (self, fn, e)
	              if e ~= nil then return foldl (fn, e, self) end
	              return foldl (fn, self)
	            end),
    foldr       = DEPRECATED ("41", "'std.list:foldr'",
                    "use 'std.functional.foldr' instead",
		    function (self, fn, e)
	              if e ~= nil then return foldr (fn, e, self) end
	              return foldr (fn, self)
	            end),
    index_key   = DEPRECATED ("41", "'std.list:index_key'",
                    function (self, fn) return index_key (fn, self)   end),
    index_value = DEPRECATED ("41", "'std.list:index_value'",
                    function (self, fn) return index_value (fn, self) end),
    relems      = DEPRECATED ("41", "'std.list:relems'",  relems),
    reverse     = DEPRECATED ("41", "'std.list:reverse'", reverse),
  },


  _functions = M,
}


return List
