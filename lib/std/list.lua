--[[--
 Tables as lists.

 Every List is also an Object, and thus inherits all of the `std.object`
 methods, particularly use of object cloning for making new List objects.

 In addition to calling methods on List objects in OO style...

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
local argscheck, export, ielems, prototype =
  base.argscheck, base.export, base.ielems, base.prototype
local M = { "std.list" }



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


-- Support for DEPRECATED apis. --

local ielems = base.ielems

local function map (fn, l)
  local r = List {}
  for e in ielems (l) do
    local v = fn (e)
    if v ~= nil then
      r[#r + 1] = v
    end
  end
  return r
end


--[[ ================= ]]--
--[[ Module Functions. ]]--
--[[ ================= ]]--


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
-- @param x item
-- @tparam List l a list
-- @treturn List new list containing `{x, unpack (l)}`
local cons = function (x, l, ...)
  if prototype (x) == "List" and prototype (l) ~= "List" then
    if not base.getcompat (M.cons) then
      io.stderr:write (base.DEPRECATIONMSG ("41",
                       "'std.list.cons' with List argument first", 2))
      base.setcompat (M.cons)
    end
    x, l = l, x
  end
  argscheck ("std.list.cons", {"any", "List?"}, {x, l})
  if next {...} then
    error (string.format (base.toomanyarg_fmt, "std.list.cons", 2, 2 + base.len {...}), 2)
  end

  return List {x, unpack (l or {})}
end
M.cons = cons


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



--[[ =============== ]]--
--[[ Object Methods. ]]--
--[[ =============== ]]--


local m = { "std.list", "List" }


--- Append an item to a list.
-- @function append
-- @param x item
-- @treturn List new list containing `{self[1], ..., self[#self], x}`
export (m, "append (any)", append)


--- Compare two lists element-by-element, from left-to-right.
--
--     if a_list:compare (another_list) == 0 then print "same" end
-- @function compare
-- @tparam table l a list
-- @return -1 if `self` is less than `l`, 0 if they are the same, and 1
--   if `self` is greater than `l`
export (m, "compare (List|table)", compare)


--- Concatenate arguments into a list.
-- @function concat
-- @param ... tuple of lists
-- @treturn List new list containing
--   `{self[1], ..., self[#self], l\_1[1], ..., l\_1[#l\_1], ..., l\_n[1], ..., l\_n[#l\_n]}`
export (m, "concat (List|table*)", concat)


--- Prepend an item to a list.
-- @function cons
-- @param x item
-- @treturn List new list containing `{x, unpack (self)}`
export (m, "cons (any)",
  function (self, x) return cons (x, self) end)


--- Repeat a list.
-- @function rep
-- @int n number of times to repeat
-- @treturn List `n` copies of `self` appended together
export (m, "rep (int)", rep)


--- Return a sub-range of a list.
-- (The equivalent of `string.sub` on strings; negative list indices
-- count from the end of the list.)
-- @function sub
-- @int from start of range (default: 1)
-- @int to end of range (default: `#self`)
-- @treturn List new list containing `{self[from], ..., self[to]}`
export (m, "sub (int?, int?)", sub)


--- Return a list with its first element removed.
-- @function tail
-- @treturn List new list containing `{self[2], ..., self[#self]}`
export (m, "tail ()", tail)



--[[ ============= ]]--
--[[ Deprecations. ]]--
--[[ ============= ]]--


local DEPRECATED = base.DEPRECATED


local function filter (pfn, l)
  local r = List {}
  for e in ielems (l) do
    if pfn (e) then
      r[#r + 1] = e
    end
  end
  return r
end


local function flatten (l)
  local r = List {}
  for v in base.tree.leaves (ipairs, l) do
    r[#r + 1] = v
  end
  return r
end


local function foldl (fn, d, t)
  if t == nil then
    local tail = {}
    for i = 2, len (d) do tail[#tail + 1] = d[i] end
    d, t = d[1], tail
  end
  return base.functional.reduce (fn, d, ipairs, t)
end


local function foldr (fn, d, t)
  if t == nil then
    local u, last = {}, len (d)
    for i = 1, last - 1 do u[#u + 1] = d[i] end
    d, t = d[last], u
  end
  return base.functional.reduce (
    function (x, y) return fn (y, x) end, d, ipairs, base.ireverse (t))
end


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


local function map_with (fn, ls)
  return map (function (...) return fn (unpack (...)) end, ls)
end


local function project (x, l)
  return map (function (t) return t[x] end, l)
end


local function relems (l) return base.ielems (base.ireverse (l)) end


local function reverse (l) return List (base.ireverse (l)) end


local function shape (s, l)
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
end


local function transpose (ls)
  local rs, len, dims = List {}, base.len (ls), map (base.len, ls)
  if #dims > 0 then
    for i = 1, math.max (unpack (dims)) do
      rs[i] = List {}
      for j = 1, len do
	-- FIXME: the if wrapper is only needed to stop the i index
	--        falling through to the metatable[2] index :(
        if i <= #ls[j] then rs[i][j] = ls[j][i] end
      end
    end
  end
  return rs
end


local function zip_with (ls, fn)
  return map_with (fn, transpose (ls))
end


m.depair      = DEPRECATED ("38", "'std.list:depair'",    depair)
m.map_with    = DEPRECATED ("38", "'std.list:map_with'",
                  function (self, fn) return map_with (fn, self) end)
m.transpose   = DEPRECATED ("38", "'std.list:transpose'", transpose)
m.zip_with    = DEPRECATED ("38", "'std.list:zip_with'",  zip_with)


M.elems       = DEPRECATED ("41", "'std.list.elems'",
                  "use 'std.ielems' instead", base.ielems)
m.elems       = DEPRECATED ("41", "'std.list:elems'",
                  "use 'std.ielems' instead", base.ielems)

M.filter      = DEPRECATED ("41", "'std.list.filter'",
                  "use 'std.functional.filter' instead", filter)
m.filter      = DEPRECATED ("41", "'std.list:filter'",
                  "use 'std.functional.filter' instead",
                  function (self, p) return filter (p, self) end)


M.flatten     = DEPRECATED ("41", "'std.list.flatten'",
                  "use 'std.functional.flatten' instead", flatten)
m.flatten     = DEPRECATED ("41", "'std.list:flatten'",
                  "use 'std.functional.flatten' instead", flatten)


M.foldl       = DEPRECATED ("41", "'std.list.foldl'",
                  "use 'std.functional.foldl' instead", foldl)
m.foldl       = DEPRECATED ("41", "'std.list:foldl'",
                  "use 'std.functional.foldl' instead",
		  function (self, fn, e)
	            if e ~= nil then return foldl (fn, e, self) end
	            return foldl (fn, self)
	          end)

M.foldr       = DEPRECATED ("41", "'std.list.foldr'",
                  "use 'std.functional.foldr' instead", foldr)
m.foldr       = DEPRECATED ("41", "'std.list:foldr'",
                  "use 'std.functional.foldr' instead",
		  function (self, fn, e)
	            if e ~= nil then return foldr (fn, e, self) end
	            return foldr (fn, self)
	          end)

M.index_key   = DEPRECATED ("41", "'std.list.index_key'",
                "compose 'std.functional.filter' and 'std.table.invert' instead",
		index_key)
m.index_key   = DEPRECATED ("41", "'std.list:index_key'",
                function (self, fn) return index_key (fn, self) end)


M.index_value = DEPRECATED ("41", "'std.list.index_value'",
                  "compose 'std.functional.filter' and 'std.table.invert' instead",
		  index_value)
m.index_value = DEPRECATED ("41", "'std.list:index_value'",
                  function (self, fn) return index_value (fn, self) end)


M.map         = DEPRECATED ("41", "'std.list.map'",
                  "use 'std.functional.map' instead", map)
m.map         = DEPRECATED ("41", "'std.list:map'",
                  "use 'std.functional.map' instead",
                  function (self, fn) return map (fn, self) end)



M.map_with    = DEPRECATED ("41", "'std.list.map_with'",
                  "use 'std.functional.map_with' instead", map_with)

M.project     = DEPRECATED ("41", "'std.list.project'",
                  "use 'std.table.project' instead", project)
m.project     = DEPRECATED ("41", "'std.list:project'",
                  "use 'std.table.project' instead",
                  function (self, x) return project (x, self) end)

M.relems      = DEPRECATED ("41", "'std.list.relems'",
                  "compose 'std.ielems' and 'std.ireverse' instead", relems)
m.relems      = DEPRECATED ("41", "'std.list:relems'",  relems)

M.reverse     = DEPRECATED ("41", "'std.list.reverse'",
                  "use 'std.ireverse' instead", reverse)
m.reverse     = DEPRECATED ("41", "'std.list:reverse'",
                  "use 'std.ireverse' instead", reverse)

M.shape       = DEPRECATED ("41", "'std.list.shape'",
                  "use 'std.table.shape' instead", shape)
m.shape       = DEPRECATED ("41", "'std.list:shape'",
                  "use 'std.table.shape' instead",
		  function (t, l) return shape (l, t) end)

M.transpose   = DEPRECATED ("41", "'std.list.transpose'",
                  "use 'std.functional.zip' instead", transpose)

M.zip_with    = DEPRECATED ("41", "'std.list.zip_with'",
                  "use 'std.functional.zip_with' instead", zip_with)



--[[ ================== ]]--
--[[ Type Declarations. ]]--
--[[ ================== ]]--


--- An Object derived List.
-- @table List

List = Object {
  -- Derived object type.
  _type      = "List",
  _functions = M,
  __index    = m,

  ------
  -- Concatenate lists.
  --     new = list .. table
  -- @function __concat
  -- @tparam List list a list
  -- @tparam table table another list, hash part is ignored
  -- @see concat
  __concat = concat,

  ------
  -- Append element to list.
  --     list = list + element
  -- @function __add
  -- @tparam List list a list
  -- @param element element to append
  -- @see append
  __add = append,

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
}


return List
