--[[--
 Tables as lists.

 Every list is also an object, and thus inherits all of the `std.object`
 methods, particularly use of object cloning for making new list objects.

 In addition to calling methods on list objects in OO style...

     local List = require "std.list"
     local l = List {1, 2, 3}
     for e in l:relems () do print (e) end
       => 3
       => 2
       => 1

 ...they can also be called as module functions with an explicit argument:

     local List = require "std.list"
     local l = List {1, 2, 3}
     for e in List.relems (l) do print (e) end
       => 3
       => 2
       => 1

 @classmod std.list
]]

local base    = require "std.base"
local func    = require "std.functional"
local Object  = require "std.object"


--- Compare two lists element-by-element, from left-to-right.
--
--     if a_list:compare (another_list) == 0 then print "same" end
-- @function compare
-- @tparam table l another list
-- @return -1 if `self` is less than `l`, 0 if they are the same, and 1
--   if `self` is greater than `l`
local compare = base.compare


--- An iterator over the elements of a list.
-- @function elems
-- @treturn function  iterator function which returns successive elements of `self`
-- @treturn table     *list*
-- @return `true`
local elems = base.elems


local List -- list prototype object forward declaration


--- Append an item to a list.
-- @param            x  item
-- @treturn std.list    new list containing `{self[1], ..., self[#self], x}`
local function append (self, x)
  return List (base.append (self, x))
end


--- Concatenate arguments into a list.
-- @param            ... tuple of lists
-- @treturn std.list     new list containing
--   `{self[1], ..., self[#self], l\_1[1], ..., l\_1[#l\_1], ..., l\_n[1], ..., l\_n[#l\_n]}`
local function concat (self, ...)
  return List (base.concat (self, ...))
end


--- An iterator over the elements of a list, in reverse.
-- @treturn function   iterator function which returns precessive elements of the `self`
-- @treturn std.list   `self`
-- @return `true`
local function relems (self)
  local n = #self + 1
  return function (self)
           n = n - 1
           if n > 0 then
             return self[n]
           end
         end,
  self, true
end


--- Map a function over a list.
-- @tparam  function f map function
-- @treturn std.list new list containing `{f (self[1]), ..., f (self[#self])}`
local function map (self, f)
  return List (func.map (f, elems, self))
end


--- Map a function over a list of lists.
-- @tparam  table    ls a list of lists
-- @tparam  function f  map function
-- @treturn std.list    new list `{f (unpack (ls[1]))), ..., f (unpack (ls[#ls]))}`
local function map_with (ls, f)
  return List (func.map (func.compose (f, unpack), elems, ls))
end


--- Filter a list according to a predicate.
-- @tparam  function p predicate function, of one argument returning a boolean
-- @treturn std.list   new list containing elements `e` of `self` for which `p (e)` is true
local function filter (self, p)
  return List (func.filter (p, elems, self))
end


--- Return a sub-range of a list.
-- (The equivalent of `string.sub` on strings; negative list indices
-- count from the end of the list.)
-- @tparam  number   from start of range (default: 1)
-- @tparam  number   to   end of range (default: `#self`)
-- @treturn std.list      new list containing `{self[from], ..., self[to]}`
local function sub (self, from, to)
  local r = List {}
  local len = #self
  from = from or 1
  to = to or len
  if from < 0 then
    from = from + len + 1
  end
  if to < 0 then
    to = to + len + 1
  end
  for i = from, to do
    table.insert (r, self[i])
  end
  return r
end


--- Return a list with its first element removed.
-- @treturn std.list  new list containing `{self[2], ..., self[#self]}`
local function tail (self)
  return sub (self, 2)
end


--- Fold a binary function through a list left associatively.
-- @tparam  function f  binary function
-- @param            e  element to place in left-most position
-- @return result
local function foldl (self, f, e)
  return func.fold (f, e, elems, self)
end


--- Fold a binary function through a list right associatively.
-- @tparam  function f  binary function
-- @param            e  element to place in right-most position
-- @return result
local function foldr (self, f, e)
  return List (func.fold (function (x, y) return f (y, x) end,
                          e, relems, self))
end


--- Prepend an item to a list.
-- @param            x  item
-- @treturn std.list    new list containing `{x, unpack (self)}`
local function cons (self, x)
  return List {x, unpack (self)}
end


--- Repeat a list.
-- @tparam  number   n number of times to repeat
-- @treturn std.list `n` copies of `self` appended together
local function rep (self, n)
  local r = List {}
  for i = 1, n do
    r = concat (r, self)
  end
  return r
end


--- Reverse a list.
-- @treturn std.list    new list containing `{self[#self], ..., self[1]}`
local function reverse (self)
  local r = List {}
  for i = #self, 1, -1 do
    table.insert (r, self[i])
  end
  return r
end


--- Transpose a list of lists.
-- This function in Lua is equivalent to zip and unzip in more strongly
-- typed languages.
-- @tparam table  ls
-- `{{ls<1,1>, ..., ls<1,c>}, ..., {ls&lt;r,1>, ..., ls&lt;r,c>}}`
-- @treturn std.list new list containing
-- `{{ls<1,1>, ..., ls&lt;r,1>}, ..., {ls<1,c>, ..., ls&lt;r,c>}}`
local function transpose (ls)
  local rs, len = List {}, #ls
  for i = 1, math.max (unpack (map (ls, function (l) return #l end))) do
    rs[i] = List {}
    for j = 1, len do
      rs[i][j] = ls[j][i]
    end
  end
  return rs
end


--- Zip a list of lists together with a function.
-- @tparam  table    ls list of lists
-- @tparam  function f  function
-- @treturn std.list    a new list containing
--   `{f (ls[1][1], ..., ls[#ls][1]), ..., f (ls[1][N], ..., ls[#ls][N])`
-- where `N = max {map (function (l) return #l end, ls)}`
local function zip_with (ls, f)
  return map_with (transpose (ls), f)
end


--- Project a list of fields from a list of tables.
-- @param            f  field to project
-- @treturn std.list    list of `f` fields
local function project (self, f)
  return map (self, function (t) return t[f] end)
end


--- Turn a table into a list of pairs.
-- @todo Find a better name.
-- @tparam  table    t  a table `{i1=v1, ..., in=vn}`
-- @treturn std.list    a new list containing `{{i1, v1}, ..., {in, vn}}`
-- @see depair
local function enpair (t)
  local ls = List {}
  for i, v in pairs (t) do
    table.insert (ls, List {i, v})
  end
  return ls
end


--- Turn a list of pairs into a table.
-- @todo Find a better name.
-- @tparam  table ls list of lists `{{i1, v1}, ..., {in, vn}}`
-- @treturn table    a new list containing table `{i1=v1, ..., in=vn}`
-- @see enpair
local function depair (ls)
  local t = {}
  for v in elems (ls) do
    t[v[1]] = v[2]
  end
  return t
end


--- Flatten a list.
-- @treturn std.list flattened list
local function flatten (self)
  local r = List {}
  for v in base.ileaves (self) do
    table.insert (r, v)
  end
  return r
end


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
-- @tparam table s `{d1, ..., dn}`
-- @return reshaped list
local function shape (self, s)
  self = flatten (self)
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
    s[zero] = math.ceil (#self / size)
  end
  local function fill (i, d)
    if d > #s then
      return self[i], i + 1
    else
      local r = List {}
      for j = 1, s[d] do
        local e
        e, i = fill (i, d + 1)
        table.insert (r, e)
      end
      return r, i
    end
  end
  return (fill (1, 1))
end


--- Make an index of a list of tables on a given field
-- @tparam table     l  list of tables `{t1, ..., tn}`
-- @param            f  field
-- @treturn std.list    index `{t1[f]=1, ..., tn[f]=n}`
local function index_key (l, f)
  local r = List {}
  for i, v in ipairs (l) do
    local k = v[f]
    if k then
      r[k] = i
    end
  end
  return r
end


--- Copy a list of tables, indexed on a given field
-- @tparam  table    l  list of tables `{i1=t1, ..., in=tn}`
-- @param            f  field whose value should be used as index
-- @treturn std.list    index `{t1[f]=t1, ..., tn[f]=tn}`
local function index_value (l, f)
  local r = List {}
  for i, v in ipairs (l) do
    local k = v[f]
    if k then
      r[k] = v
    end
  end
  return r
end


--- @export
local metamethods = {
  append      = append,
  compare     = compare,
  concat      = concat,
  cons        = cons,
  depair      = depair,
  elems       = elems,
  enpair      = enpair,
  filter      = filter,
  flatten     = flatten,
  foldl       = foldl,
  foldr       = foldr,
  index_key   = index_key,
  index_value = index_value,
  map         = map,
  map_with    = map_with,
  project     = project,
  relems      = relems,
  rep         = rep,
  reverse     = reverse,
  shape       = shape,
  sub         = sub,
  tail        = tail,
  transpose   = transpose,
  zip_with    = zip_with,
}


List = Object {
  -- Derived object type.
  _type = "List",

  ------
  -- Concatenate lists.
  --     new = list .. table
  -- @function __concat
  -- @tparam std.list list a list
  -- @tparam table    table another list, hash part is ignored
  -- @see concat
  __concat = concat,

  ------
  -- Append element to list.
  --     list = list + element
  -- @function __add
  -- @tparam std.list list a list
  -- @param           element element to append
  -- @see append
  __add    = append,

  ------
  -- List order operator.
  --     max = list1 > list2 and list1 or list2
  -- @tparam std.list list1 a list
  -- @tparam std.list list2 another list
  -- @see std.list:compare
  __lt = function (list1, list2) return compare (list1, list2) < 0 end,

  ------
  -- List equality or order operator.
  --     min = list1 <= list2 and list1 or list2
  -- @tparam std.list list1 a list
  -- @tparam std.list list2 another list
  -- @see std.list:compare
  __le = function (list1, list2) return compare (list1, list2) <= 0 end,

  __index = base.merge (metamethods, {
    -- camelCase compatibility.
    indexKey   = index_key,
    indexValue = index_value,
    mapWith    = map_with,
    zipWith    = zip_with,
  }),
}


-- Function forms of operators
func.op[".."] = concat

return List
