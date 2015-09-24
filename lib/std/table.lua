--[[--
 Extensions to the core table module.

 The module table returned by `std.table` also contains all of the entries from
 the core table module.  An hygienic way to import this module, then, is simply
 to override the core `table` locally:

    local table = require "std.table"

 @corelibrary std.table
]]


local _ENV		= _G
local getmetatable	= getmetatable
local next		= next
local setfenv		= setfenv or function () end
local setmetatable	= setmetatable
local table		= table
local type		= type

local math_ceil		= math.ceil
local math_min		= math.min


local std		= require "std.base"
local debug		= require "std.debug"

local DEPRECATED	= debug.DEPRECATED
local argscheck		= debug.argscheck
local argerror		= std.debug.argerror
local collect		= std.functional.collect
local copy		= std.base.copy
local insert		= std.table.insert
local invert		= std.table.invert
local ipairs		= std.ipairs
local leaves		= std.tree.leaves
local len		= std.operator.len
local maxn		= std.table.maxn
local merge		= std.base.merge
local pairs		= std.pairs
local unpack		= std.table.unpack

if require "std.debug_init"._DEBUG.strict then
  _ENV = require "std.strict" {}
else
  _ENV = {}
end
setfenv (1, _ENV)




--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


local M, monkeys


local function merge_allfields (t, u, map, nometa)
  if type (map) ~= "table" then
    map, nometa = nil, map
  end

  if not nometa then
    setmetatable (t, getmetatable (u))
  end
  if map then
    for k, v in pairs (u) do t[map[k] or k] = v end
  else
    for k, v in pairs (u) do t[k] = v end
  end
  return t
end


local function merge_namedfields (t, u, keys, nometa)
  if type (keys) ~= "table" then
    keys, nometa = nil, keys
  end

  if not nometa then
    setmetatable (t, getmetatable (u))
  end
  for _, k in pairs (keys or {}) do t[k] = u[k] end
  return t
end


local function depair (ls)
  local t = {}
  for _, v in ipairs (ls) do
    t[v[1]] = v[2]
  end
  return t
end


local function enpair (t)
  local tt = {}
  for i, v in pairs (t) do
    tt[#tt + 1] = {i, v}
  end
  return tt
end


local function flatten (t)
  return collect (leaves, ipairs, t)
end


local function keys (t)
  local l = {}
  for k in pairs (t) do
    l[#l + 1] = k
  end
  return l
end


local function new (x, t)
  return setmetatable (t or {},
                       {__index = function (t, i)
                                    return x
                                  end})
end


local function project (fkey, tt)
  local r = {}
  for _, t in ipairs (tt) do
    r[#r + 1] = t[fkey]
  end
  return r
end


local function shape (dims, t)
  t = flatten (t)
  -- Check the shape and calculate the size of the zero, if any
  local size = 1
  local zero
  for i, v in ipairs (dims) do
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
    dims[zero] = math_ceil (len (t) / size)
  end
  local function fill (i, d)
    if d > len (dims) then
      return t[i], i + 1
    else
      local r = {}
      for j = 1, dims[d] do
        local e
        e, i = fill (i, d + 1)
        r[#r + 1] = e
      end
      return r, i
    end
  end
  return (fill (1, 1))
end


local function size (t)
  local n = 0
  for _ in pairs (t) do
    n = n + 1
  end
  return n
end


-- Preserve core table sort function.
local _sort = table.sort

local function sort (t, c)
  _sort (t, c)
  return t
end


local function monkey_patch (namespace)
  namespace = namespace or _G
  namespace.table = copy (namespace.table or {}, monkeys)
  return M
end


local _remove = table.remove

local function remove (t, pos)
  local lent = len (t)
  pos = pos or lent
  if pos < math_min (1, lent) or pos > lent + 1 then -- +1? whu? that's what 5.2.3 does!?!
    argerror ("std.table.remove", 2, "position " .. pos .. " out of bounds", 2)
  end
  return _remove (t, pos)
end


local function values (t)
  local l = {}
  for _, v in pairs (t) do
    l[#l + 1] = v
  end
  return l
end



--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


local function X (decl, fn)
  return argscheck ("std.table." .. decl, fn)
end

M = {
  --- Core Functions
  -- @section corefuncs

  --- Enhance core *table.insert* to return its result.
  -- If *pos* is not given, respect `__len` metamethod when calculating
  -- default append.  Also, diagnose out of bounds *pos* arguments
  -- consistently on any supported version of Lua.
  -- @function insert
  -- @tparam table t a table
  -- @int[opt=len (t)] pos index at which to insert new element
  -- @param v value to insert into *t*
  -- @treturn table *t*
  -- @usage
  -- --> {1, "x", 2, 3, "y"}
  -- insert (insert ({1, 2, 3}, 2, "x"), "y")
  insert = X ("insert (table, [int], any)", insert),

  --- Largest integer key in a table.
  -- @function maxn
  -- @tparam table t a table
  -- @treturn int largest integer key in *t*
  -- @usage
  -- --> 42
  -- maxn {"a", b="c", 99, [42]="x", "x", [5]=67}
  maxn = X ("maxn (table)", maxn),

  --- Enhance core *table.remove* to respect `__len` when *pos* is omitted.
  -- Also, diagnose out of bounds *pos* arguments consistently on any supported
  -- version of Lua.
  -- @function remove
  -- @tparam table t a table
  -- @int[opt=len (t)] pos index from which to remove an element
  -- @return removed value, or else `nil`
  -- @usage
  -- --> {1, 2, 5}
  -- t = {1, 2, "x", 5}
  -- remove (t, 3) == "x" and t
  remove = X ("remove (table, ?int)", remove),

  --- Enhance core *table.sort* to return its result.
  -- @function sort
  -- @tparam table t unsorted table
  -- @tparam[opt=std.operator.lt] comparator c ordering function callback
  -- @return *t* with keys sorted accordind to *c*
  -- @usage table.concat (sort (object))
  sort = X ("sort (table, ?function)", sort),

  --- Enhance core *table.unpack* to always unpack up to __len or maxn.
  -- @function unpack
  -- @tparam table t table to act on
  -- @int[opt=1] i first index to unpack
  -- @int[opt=table.maxn(t)] j last index to unpack
  -- @return ... values of numeric indices of *t*
  -- @usage return unpack (results_table)
  unpack = X ("unpack (table, ?int, ?int)", unpack),


  --- Accessor Functions
  -- @section accessorfuncs

  --- Make a shallow copy of a table, including any metatable.
  --
  -- To make deep copies, use @{std.tree.clone}.
  -- @function clone
  -- @tparam table t source table
  -- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
  -- @bool[opt] nometa if non-nil don't copy metatable
  -- @return copy of *t*, also sharing *t*'s metatable unless *nometa*
  --   is true, and with keys renamed according to *map*
  -- @see merge
  -- @see clone_select
  -- @usage
  -- shallowcopy = clone (original, {rename_this = "to_this"}, ":nometa")
  clone = X ("clone (table, [table], ?boolean|:nometa)",
             function (...) return merge_allfields ({}, ...) end),

  --- Make a partial clone of a table.
  --
  -- Like `clone`, but does not copy any fields by default.
  -- @function clone_select
  -- @tparam table t source table
  -- @tparam[opt={}] table keys list of keys to copy
  -- @bool[opt] nometa if non-nil don't copy metatable
  -- @treturn table copy of fields in *selection* from *t*, also sharing *t*'s
  --   metatable unless *nometa*
  -- @see clone
  -- @see merge_select
  -- @usage
  -- partialcopy = clone_select (original, {"this", "and_this"}, true)
  clone_select = X ("clone_select (table, [table], ?boolean|:nometa)",
                    function (...) return merge_namedfields ({}, ...) end),

  --- Turn a list of pairs into a table.
  -- @todo Find a better name.
  -- @function depair
  -- @tparam table ls list of lists
  -- @treturn table a flat table with keys and values from *ls*
  -- @see enpair
  -- @usage
  -- --> {a=1, b=2, c=3}
  -- depair {{"a", 1}, {"b", 2}, {"c", 3}}
  depair = X ("depair (list of lists)", depair),

  --- Turn a table into a list of pairs.
  -- @todo Find a better name.
  -- @function enpair
  -- @tparam table t  a table `{i1=v1, ..., in=vn}`
  -- @treturn table a new list of pairs containing `{{i1, v1}, ..., {in, vn}}`
  -- @see depair
  -- @usage
  -- --> {{1, "a"}, {2, "b"}, {3, "c"}}
  -- enpair {"a", "b", "c"}
  enpair = X ("enpair (table)", enpair),

  --- Return whether table is empty.
  -- @function empty
  -- @tparam table t any table
  -- @treturn boolean `true` if *t* is empty, otherwise `false`
  -- @usage if empty (t) then error "ohnoes" end
  empty = X ("empty (table)", function (t) return not next (t) end),

  --- Flatten a nested table into a list.
  -- @function flatten
  -- @tparam table t a table
  -- @treturn table a list of all non-table elements of *t*
  -- @usage
  -- --> {1, 2, 3, 4, 5}
  -- flatten {{1, {{2}, 3}, 4}, 5}
  flatten = X ("flatten (table)", flatten),

  --- Make a table with a default value for unset keys.
  -- @function new
  -- @param[opt=nil] x default entry value
  -- @tparam[opt={}] table t initial table
  -- @treturn table table whose unset elements are *x*
  -- @usage t = new (0)
  new = X ("new (?any, ?table)", new),

  --- Turn a tuple into a list.
  -- @function pack
  -- @param ... tuple
  -- @return list
  -- @usage
  -- --> {1, 2, "ax"}
  -- pack (("ax1"):find "(%D+)")
  pack = function (...) return {...} end,

  --- Project a list of fields from a list of tables.
  -- @function project
  -- @param fkey field to project
  -- @tparam table tt a list of tables
  -- @treturn table list of *fkey* fields from *tt*
  -- @usage
  -- --> {1, 3, "yy"}
  -- project ("xx", {{"a", xx=1, yy="z"}, {"b", yy=2}, {"c", xx=3}, {xx="yy"})
  project = X ("project (any, list of tables)", project),

  --- Shape a table according to a list of dimensions.
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
  -- @function shape
  -- @tparam table dims table of dimensions `{d1, ..., dn}`
  -- @tparam table t a table of elements
  -- @return reshaped list
  -- @usage
  -- --> {{"a", "b"}, {"c", "d"}, {"e", "f"}}
  -- shape ({3, 2}, {"a", "b", "c", "d", "e", "f"})
  shape = X ("shape (table, table)", shape),

  --- Find the number of elements in a table.
  -- @function size
  -- @tparam table t any table
  -- @treturn int number of non-nil values in *t*
  -- @usage
  -- --> 3
  -- size {foo = true, bar = true, baz = false}
  size = X ("size (table)", size),

  --- Make the list of values of a table.
  -- @function values
  -- @tparam table t any table
  -- @treturn table list of values in *t*
  -- @see keys
  -- @usage
  -- --> {"a", "c", 42}
  -- values {"a", b="c", [-1]=42}
  values = X ("values (table)", values),


  --- Mutator Functions
  -- @section mutatorfuncs

  --- Invert a table.
  -- @function invert
  -- @tparam table t a table with `{k=v, ...}`
  -- @treturn table inverted table `{v=k, ...}`
  -- @usage
  -- --> {a=1, b=2, c=3}
  -- invert {"a", "b", "c"}
  invert = X ("invert (table)", invert),

  --- Make the list of keys in table.
  -- @function keys
  -- @tparam table t a table
  -- @treturn table list of keys from *t*
  -- @see values
  -- @usage globals = keys (_G)
  keys = X ("keys (table)", keys),

  --- Destructively merge another table's fields into another.
  -- @function merge
  -- @tparam table t destination table
  -- @tparam table u table with fields to merge
  -- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
  -- @bool[opt] nometa if `true` or ":nometa" don't copy metatable
  -- @treturn table *t* with fields from *u* merged in
  -- @see clone
  -- @see merge_select
  -- @usage merge (_G, require "std.debug", {say = "log"}, ":nometa")
  merge = X ("merge (table, table, [table], ?boolean|:nometa)", merge_allfields),

  --- Destructively merge another table's named fields into *table*.
  --
  -- Like `merge`, but does not merge any fields by default.
  -- @function merge_select
  -- @tparam table t destination table
  -- @tparam table u table with fields to merge
  -- @tparam[opt={}] table keys list of keys to copy
  -- @bool[opt] nometa if `true` or ":nometa" don't copy metatable
  -- @treturn table copy of fields in *selection* from *t*, also sharing *t*'s
  --   metatable unless *nometa*
  -- @see merge
  -- @see clone_select
  -- @usage merge_select (_G, require "std.debug", {"say"}, false)
  merge_select = X ("merge_select (table, table, [table], ?boolean|:nometa)",
                    merge_namedfields),


  --- Module Functions
  -- @section modulefuncs

  --- Overwrite core `table` methods with `std` enhanced versions.
  -- @function monkey_patch
  -- @tparam[opt=_G] table namespace where to install global functions
  -- @treturn table the module table
  -- @usage local table = require "std.table".monkey_patch ()
  monkey_patch = X ("monkey_patch (?table)", monkey_patch),
}


monkeys = copy ({}, M)  -- before deprecations and core merge


--[[ ============= ]]--
--[[ Deprecations. ]]--
--[[ ============= ]]--



M.len = DEPRECATED ("41.3", "'std.table.len'",
  "use 'std.operator.len' instead", X ("len (table)", std.operator.len))


M.metamethod = DEPRECATED ("41", "'std.table.metamethod'",
  "use 'std.getmetamethod' instead", std.getmetamethod)


M.okeys = DEPRECATED ("41.3", "'std.table.okeys'",
  "compose 'std.table.keys' and 'std.table.sort' instead",
  X ("okeys (table)", function (t)
    local r = {}
    for k in pairs (t) do r[#r + 1] = k end
    return std.base.sortkeys (r)
  end))


M.ripairs = DEPRECATED ("41", "'std.table.ripairs'",
  "use 'std.ripairs' instead", std.ripairs)


M.totable = DEPRECATED ("41", "'std.table.totable'",
  "use 'std.pairs' instead",
  function (x)
    local m = std.getmetamethod (x, "__totable")
    if m then
      return m (x)
    elseif type (x) == "table" then
      return x
    elseif type (x) == "string" then
      local t = {}
      x:gsub (".", function (c) t[#t + 1] = c end)
      return t
    else
      return nil
    end
  end)



return merge (M, table)



--- Types
-- @section Types

--- Signature of a @{sort} comparator function.
-- @function comparator
-- @param a any object
-- @param b any object
-- @treturn boolean `true` if *a* sorts before *b*, otherwise `false`
-- @see sort
-- @usage
-- local reversor = function (a, b) return a > b end
-- sort (t, reversor)
