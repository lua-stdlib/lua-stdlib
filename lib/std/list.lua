--[[--
 List prototype.

 In addition to the functionality described here, List objects also
 have all the methods and metamethods of the @{std.object.prototype}
 (except where overridden here),

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Object
                 `-> List

 @prototype std.list
]]


--[[ ============================== ]]--
--[[ Cache all external references. ]]--
--[[ ============================== ]]--


local require	= require
local setfenv	= setfenv

local math = {
  ceil		= math.ceil,
  max		= math.max,
}



--[[ ====================================== ]]--
--[[ Empty environment, with strict access. ]]--
--[[ ====================================== ]]--

local _ENV, _DEBUG = _G, require "std.debug_init"._DEBUG

if _DEBUG.strict then
  _ENV = require "std.strict" {}
  if setfenv then setfenv (1, _ENV) end
end


local std	= require "std.base"
local Object	= require "std.object".prototype

local compare	= std.list.compare
local ipairs	= std.ipairs
local len	= std.operator.len
local pairs	= std.pairs
local unpack	= std.table.unpack



--[[ ================= ]]--
--[[ Implementatation. ]]--
--[[ ================= ]]--


local M, prototype


local function append (l, x)
  local r = l {}
  r[#r + 1] = x
  return r
end


local function concat (l, ...)
  local r = prototype {}
  for _, e in ipairs {l, ...} do
    for _, v in ipairs (e) do
      r[#r + 1] = v
    end
  end
  return r
end


local function rep (l, n)
  local r = prototype {}
  for i = 1, n do
    r = concat (r, l)
  end
  return r
end


local function sub (l, from, to)
  local r = prototype {}
  local lenl = len (l)
  from = from or 1
  to = to or lenl
  if from < 0 then
    from = from + lenl + 1
  end
  if to < 0 then
    to = to + lenl + 1
  end
  for i = from, to do
    r[#r + 1] = l[i]
  end
  return r
end



--[[ ============= ]]--
--[[ Deprecations. ]]--
--[[ ============= ]]--


-- This entire section can be deleted any time after 2016.01.03, along
-- with all references to these functions further down.


local DEPRECATED = require "std.debug".DEPRECATED


local function depair (ls)
  local t = {}
  for _, v in ipairs (ls) do
    t[v[1]] = v[2]
  end
  return t
end


local function enpair (t)
  local ls = prototype {}
  for i, v in pairs (t) do
    ls[#ls + 1] = prototype {i, v}
  end
  return ls
end


local function filter (pfn, l)
  local r = prototype {}
  for _, e in ipairs (l) do
    if pfn (e) then
      r[#r + 1] = e
    end
  end
  return r
end


local function flatten (l)
  local r = prototype {}
  for v in std.tree.leaves (ipairs, l) do
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
  return std.functional.reduce (fn, d, std.ielems, t)
end


local function foldr (fn, d, t)
  if t == nil then
    local u, last = {}, len (d)
    for i = 1, last - 1 do u[#u + 1] = d[i] end
    d, t = d[last], u
  end
  return std.functional.reduce (
    function (x, y) return fn (y, x) end, d, std.ielems, std.ireverse (t))
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


local function map (fn, l)
  local r = prototype {}
  for _, e in ipairs (l) do
    local v = fn (e)
    if v ~= nil then
      r[#r + 1] = v
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


local function relems (l) return std.ielems (std.ireverse (l)) end


local function reverse (l) return prototype (std.ireverse (l)) end


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
    s[zero] = math.ceil (len (l) / size)
  end
  local function fill (i, d)
    if d > len (s) then
      return l[i], i + 1
    else
      local r = prototype {}
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
  local rs, lenls, dims = prototype {}, len (ls), map (len, ls)
  if len (dims) > 0 then
    for i = 1, math.max (unpack (dims)) do
      rs[i] = prototype {}
      for j = 1, lenls do
        rs[i][j] = ls[j][i]
      end
    end
  end
  return rs
end


local function zip_with (ls, fn)
  return map_with (fn, transpose (ls))
end



--[[ ================== ]]--
--[[ Type Declarations. ]]--
--[[ ================== ]]--


local function X (decl, fn)
  return require "std.debug".argscheck ("std.list." .. decl, fn)
end


--- List prototype object.
-- @object prototype
-- @string[opt="List"] _type object name
-- @tfield[opt] table|function _init object initialisation
-- @see std.object.prototype
-- @usage
-- local List = require "std.list".prototype
-- assert (std.type (List) == "List")
prototype = Object {
  _type = "std.list.List",

  --- Metamethods
  -- @section metamethods

  --- Concatenate lists.
  -- @function prototype:__concat
  -- @tparam prototype|table m another list, or table (hash part is ignored)
  -- @see concat
  -- @usage
  -- new = alist .. {"append", "these", "elements"}
  __concat = concat,

  --- Append element to list.
  -- @function prototype:__add
  -- @param e element to append
  -- @see append
  -- @usage
  -- list = list + "element"
  __add = append,

  --- List order operator.
  -- @function prototype:__lt
  -- @tparam prototype m another list
  -- @see compare
  -- @usage
  -- max = list1 > list2 and list1 or list2
  __lt = function (list1, list2) return compare (list1, list2) < 0 end,

  --- List equality or order operator.
  -- @function prototype:__le
  -- @tparam prototype m another list
  -- @see compare
  -- @usage
  -- min = list1 <= list2 and list1 or list2
  __le = function (list1, list2) return compare (list1, list2) <= 0 end,

  __index    = {
    --- Methods
    -- @section methods

    --- Append an item to a list.
    -- @function prototype:append
    -- @param x item
    -- @treturn prototype new list with *x* appended
    -- @usage
    -- --> List {"shorter", "longer"}
    -- longer = (List {"shorter"}):append "longer"
    append = X ("append (List, any)", append),

    --- Compare two lists element-by-element, from left-to-right.
    -- @function prototype:compare
    -- @tparam prototype|table m another list, or table
    -- @return -1 if *l* is less than *m*, 0 if they are the same, and 1
    --   if *l* is greater than *m*
    -- @usage
    -- if list1:compare (list2) == 0 then print "same" end
    compare = X ("compare (List, List|table)", compare),

    --- Concatenate the elements from any number of lists.
    -- @function prototype:concat
    -- @tparam prototype|table ... additional lists, or list-like tables
    -- @treturn prototype new list with elements from arguments
    -- @usage
    -- --> List {"shorter", "short", "longer", "longest"}
    -- longest = (List {"shorter"}):concat ({"short", "longer"}, {"longest"})
    concat = X ("concat (List, List|table...)", concat),

    --- Prepend an item to a list.
    -- @function prototype:cons
    -- @param x item
    -- @treturn prototype new list with *x* followed by elements of *l*
    -- @usage
    -- --> List {"x", 1, 2, 3}
    -- consed = (List {1, 2, 3}):cons "x"
    cons = X ("cons (List, any)", function (l, x) return prototype {x, unpack (l)} end),

    --- Repeat a list.
    -- @function prototype:rep
    -- @int n number of times to repeat
    -- @treturn prototype *n* copies of *l* appended together
    -- @usage
    -- --> List {1, 2, 3, 1, 2, 3, 1, 2, 3}
    -- repped = (List {1, 2, 3}):rep (3)
    rep = X ("rep (List, int)", rep),

    --- Return a sub-range of a list.
    -- (The equivalent of @{string.sub} on strings; negative list indices
    -- count from the end of the list.)
    -- @function prototype:sub
    -- @int[opt=1] from start of range
    -- @int[opt=#l] to end of range
    -- @treturn prototype new list containing elements between *from* and *to*
    --   inclusive
    -- @usage
    -- --> List {3, 4, 5}
    -- subbed = (List {1, 2, 3, 4, 5, 6}):sub (3, 5)
    sub = X ("sub (List, ?int, ?int)", sub),

    --- Return a list with its first element removed.
    -- @function prototype:tail
    -- @treturn prototype new list with all but the first element of *l*
    -- @usage
    -- --> List {3, {4, 5}, 6, 7}
    -- tailed = (List {{1, 2}, 3, {4, 5}, 6, 7}):tail ()
    tail = X ("tail (List)", function (l) return sub (l, 2) end),

    enpair      = DEPRECATED ("41", "'std.list:enpair'", enpair),
    elems       = DEPRECATED ("41", "'std.list:elems'",
                    "use 'std.ielems' instead", std.ielems),
    filter      = DEPRECATED ("41", "'std.list:filter'",
                    "use 'std.functional.filter' instead",
                    function (self, p) return filter (p, self) end),
    flatten     = DEPRECATED ("41", "'std.list:flatten'",
                    "use 'std.functional.flatten' instead", flatten),
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
                    function (self, fn) return index_key (fn, self) end),
    index_value = DEPRECATED ("41", "'std.list:index_value'",
                    function (self, fn) return index_value (fn, self) end),
    map         = DEPRECATED ("41", "'std.list:map'",
                    "use 'std.functional.map' instead",
                    function (self, fn) return map (fn, self) end),
    project     = DEPRECATED ("41", "'std.list:project'",
                    "use 'std.table.project' instead",
                    function (self, x) return project (x, self) end),
    relems      = DEPRECATED ("41", "'std.list:relems'",  relems),
    reverse     = DEPRECATED ("41", "'std.list:reverse'",
                    "compose 'std.list' and 'std.ireverse' instead", reverse),
    shape       = DEPRECATED ("41", "'std.list:shape'",
                    "use 'std.table.shape' instead",
		    function (t, l) return shape (l, t) end),
  },
}


return std.object.Module {
  prototype = prototype,

  append  = prototype.append,
  compare = prototype.compare,
  concat  = prototype.concat,
  cons    = prototype.cons,
  rep     = prototype.rep,
  sub     = prototype.sub,
  tail    = prototype.tail,

  depair      = DEPRECATED ("41", "'std.list.depair'", depair),
  enpair      = DEPRECATED ("41", "'std.list.enpair'", enpair),
  elems       = DEPRECATED ("41", "'std.list.elems'",
                  "use 'std.ielems' instead", std.ielems),
  filter      = DEPRECATED ("41", "'std.list.filter'",
                  "use 'std.functional.filter' instead", filter),
  flatten     = DEPRECATED ("41", "'std.list.flatten'",
                  "use 'std.functional.flatten' instead", flatten),
  foldl       = DEPRECATED ("41", "'std.list.foldl'",
                  "use 'std.functional.foldl' instead", foldl),
  foldr       = DEPRECATED ("41", "'std.list.foldr'",
                  "use 'std.functional.foldr' instead", foldr),
  index_key   = DEPRECATED ("41", "'std.list.index_key'",
                  "compose 'std.functional.filter' and 'std.table.invert' instead",
                  index_key),
  index_value = DEPRECATED ("41", "'std.list.index_value'",
                  "compose 'std.functional.filter' and 'std.table.invert' instead",
                  index_value),
  map         = DEPRECATED ("41", "'std.list.map'",
                  "use 'std.functional.map' instead", map),
  map_with    = DEPRECATED ("41", "'std.list.map_with'",
                  "use 'std.functional.map_with' instead", map_with),
  project     = DEPRECATED ("41", "'std.list.project'",
                  "use 'std.table.project' instead", project),
  relems      = DEPRECATED ("41", "'std.list.relems'",
                  "compose 'std.ielems' and 'std.ireverse' instead", relems),
  reverse     = DEPRECATED ("41", "'std.list.reverse'",
                  "compose 'std.list' and 'std.ireverse' instead", reverse),
  shape       = DEPRECATED ("41", "'std.list.shape'",
                  "use 'std.table.shape' instead", shape),
  transpose   = DEPRECATED ("41", "'std.list.transpose'",
                  "use 'std.functional.zip' instead", transpose),
  zip_with    = DEPRECATED ("41", "'std.list.zip_with'",
                  "use 'std.functional.zip_with' instead", zip_with),
}
