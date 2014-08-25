--[[--
 Extensions to the core table module.

 The module table returned by `std.table` also contains all of the entries from
 the core table module.  An hygienic way to import this module, then, is simply
 to override the core `table` locally:

    local table = require "std.table"

 @module std.table
]]


local base  = require "std.base"
local debug = require "std.debug"

local collect       = base.functional.collect
local leaves        = base.tree.leaves
local ielems, ipairs, pairs = base.ielems, base.ipairs, base.pairs


local M



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


--- Merge one table's fields into another.
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
-- @param nometa if non-nil don't copy metatable
-- @treturn table *t* with fields from *u* merged in
local function merge_allfields (t, u, map, nometa)
  map = map or {}
  if type (map) ~= "table" then
    map, nometa = {}, map
  end

  if not nometa then
    setmetatable (t, getmetatable (u))
  end
  for k, v in pairs (u) do
    t[map[k] or k] = v
  end
  return t
end


--- Merge one table's named fields into another.
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table keys list of keys to copy
-- @param nometa if non-nil don't copy metatable
-- @treturn table copy of fields in *selection* from *t*, also sharing *t*'s
--   metatable unless *nometa*
local function merge_namedfields (t, u, keys, nometa)
  keys = keys or {}
  if type (keys) ~= "table" then
    keys, nometa = {}, keys
  end

  if not nometa then
    setmetatable (t, getmetatable (u))
  end
  for _, k in ipairs (keys) do
    t[k] = u[k]
  end
  return t
end



--[[ ================= ]]--
--[[ Module Functions. ]]--
--[[ ================= ]]--


--- Make a shallow copy of a table, including any metatable.
--
-- To make deep copies, use @{tree.clone}.
-- @tparam table t source table
-- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
-- @bool[opt] nometa if non-nil don't copy metatable
-- @return copy of *t*, also sharing *t*'s metatable unless *nometa*
--   is true, and with keys renamed according to *map*
-- @see merge
-- @see clone_select
-- @usage
-- shallowcopy = clone (original, {rename_this = "to_this"}, ":nometa")
local function clone (...) return merge_allfields ({}, ...) end


--- Make a partial clone of a table.
--
-- Like `clone`, but does not copy any fields by default.
-- @tparam table t source table
-- @tparam[opt={}] table keys list of keys to copy
-- @bool[opt] nometa if non-nil don't copy metatable
-- @treturn table copy of fields in *selection* from *t*, also sharing *t*'s
--   metatable unless *nometa*
-- @see clone
-- @see merge_select
-- @usage
-- partialcopy = clone_select (original, {"this", "and_this"}, true)
local function clone_select (...) return merge_namedfields ({}, ...) end


--- Turn a list of pairs into a table.
-- @todo Find a better name.
-- @tparam table ls list of lists `{{i1, v1}, ..., {in, vn}}`
-- @treturn table a new list containing table `{i1=v1, ..., in=vn}`
-- @see enpair
local function depair (ls)
  local t = {}
  for v in ielems (ls) do
    t[v[1]] = v[2]
  end
  return t
end


--- Turn a table into a list of pairs.
-- @todo Find a better name.
-- @tparam table t  a table `{i1=v1, ..., in=vn}`
-- @treturn table a new list of pairs containing `{{i1, v1}, ..., {in, vn}}`
-- @see depair
local function enpair (t)
  local tt = {}
  for i, v in pairs (t) do
    tt[#tt + 1] = {i, v}
  end
  return tt
end


--- Return whether table is empty.
-- @tparam table t any table
-- @treturn boolean `true` if *t* is empty, otherwise `false`
-- @usage if empty (t) then error "ohnoes" end
local function empty (t)
  return not next (t)
end


--- Flatten a nested table into a list.
-- @tparam table t a table
-- @treturn table a list of all non-table elements of *t*
local function flatten (t)
  return collect (leaves, ipairs, t)
end


--- Invert a table.
-- @tparam table t a table with `{k=v, ...}`
-- @treturn table inverted table `{v=k, ...}`
-- @usage values = invert (t)
local function invert (t)
  local i = {}
  for k, v in pairs (t) do
    i[v] = k
  end
  return i
end


--- Make the list of keys in table.
-- @tparam table t a table
-- @treturn table list of keys from *t*
-- @see values
-- @usage globals = keys (_G)
local function keys (t)
  local l = {}
  for k, _ in pairs (t) do
    l[#l + 1] = k
  end
  return l
end


--- Destructively merge another table's fields into another.
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
-- @bool[opt] nometa if `true` or ":nometa" don't copy metatable
-- @treturn table *t* with fields from *u* merged in
-- @see clone
-- @see merge_select
-- @usage merge (_G, require "std.debug", {say = "log"}, ":nometa")
local merge = merge_allfields


--- Destructively merge another table's named fields into *table*.
--
-- Like `merge`, but does not merge any fields by default.
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table keys list of keys to copy
-- @bool[opt] nometa if `true` or ":nometa" don't copy metatable
-- @treturn table copy of fields in *selection* from *t*, also sharing *t*'s
--   metatable unless *nometa*
-- @see merge
-- @see clone_select
-- @usage merge_select (_G, require "std.debug", {"say"}, false)
local merge_select = merge_namedfields


--- Make a table with a default value for unset keys.
-- @param[opt=nil] x default entry value
-- @tparam[opt={}] table t initial table
-- @treturn table table whose unset elements are *x*
-- @usage t = new (0)
local function new (x, t)
  return setmetatable (t or {},
                       {__index = function (t, i)
                                    return x
                                  end})
end


--- Turn a tuple into a list.
-- @param ... tuple
-- @return list
local function pack (...)
  return {...}
end


--- Project a list of fields from a list of tables.
-- @param fkey field to project
-- @tparam table tt a list of tables
-- @treturn table list of *fkey* fields from *tt*
local function project (fkey, tt)
  local r = {}
  for _, t in ipairs (tt) do
    r[#r + 1] = t[fkey]
  end
  return r
end


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
-- @tparam table dims table of dimensions `{d1, ..., dn}`
-- @tparam table t a table of elements
-- @return reshaped list
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
    dims[zero] = math.ceil (#t / size)
  end
  local function fill (i, d)
    if d > #dims then
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


--- Find the number of elements in a table.
-- @tparam table t any table
-- @treturn int number of non-nil values in *t*
-- @usage count = size {foo = true, bar = true, baz = false}
local function size (t)
  local n = 0
  for _ in pairs (t) do
    n = n + 1
  end
  return n
end


-- Preserve core table sort function.
local _sort = table.sort

--- Make table.sort return its result.
-- @tparam table t unsorted table
-- @tparam[opt=std.operator["<"]] comparator c ordering function callback
--   lua `<` operator
-- @return *t* with keys sorted accordind to *c*
-- @usage table.concat (sort (object))
local function sort (t, c)
  _sort (t, c)
  return t
end


--- Overwrite core methods with `std` enhanced versions.
--
-- Replaces core `table.sort` with `std.table` version.
-- @tparam[opt=_G] table namespace where to install global functions
-- @treturn table the module table
-- @usage local table = require "std.table".monkey_patch ()
local function monkey_patch (namespace)
  namespace.table.sort = M.sort
  return M
end


--- Turn an object into a table according to `__totable` metamethod.
-- @function totable
-- @tparam object|table|string x object to turn into a table
-- @treturn table resulting table or `nil`
-- @usage print (table.concat (totable (object)))

local getmetamethod = base.getmetamethod

local function totable (x)
  local m = getmetamethod (x, "__totable")
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
end


--- Make the list of values of a table.
-- @tparam table t any table
-- @treturn table list of values in *t*
-- @see keys
local function values (t)
  local l = {}
  for _, v in pairs (t) do
    l[#l + 1] = v
  end
  return l
end


local export = debug.export

--- @export
M = {
  clone        = export "clone (table, [table], boolean|:nometa?)",
  clone_select = export "clone_select (table, [table], boolean|:nometa?)",
  depair       = export "depair (list of lists)",
  enpair       = export "enpair (table)",
  empty        = export "empty (table)",
  flatten      = export "flatten (table)",
  invert       = export "invert (table)",
  keys         = export "keys (table)",
  merge        = export "merge (table, table, [table], boolean|:nometa?)",
  merge_select = export "merge_select (table, table, [table], boolean|:nometa?)",
  new          = export "new (any?, table?)",
  pack         = pack,
  project      = export "project (any, list of tables)",
  shape        = export "shape (table, table)",
  size         = export "size (table)",
  sort         = export "sort (table, function?)",
  monkey_patch = export "monkey_patch (table?)",
  totable      = export "totable (object|table|string)",
  values       = export "values (table)",
}


--[[ ============= ]]--
--[[ Deprecations. ]]--
--[[ ============= ]]--


local DEPRECATED = debug.DEPRECATED

M.clone_rename = DEPRECATED ("39", "'std.table.clone_rename'",
  "use the new `map` argument to 'std.table.clone' instead",
  function (map, t)
    local r = clone (t)
    for i, v in pairs (map) do
      r[v] = t[i]
      r[i] = nil
    end
    return r
  end)


M.metamethod = DEPRECATED ("41", "'std.table.metamethod'",
  "use 'std.getmetamethod' instead", base.getmetamethod)


M.ripairs = DEPRECATED ("41", "'std.table.ripairs'",
  "use 'std.ripairs' instead", base.ripairs)



for k, v in pairs (table) do
  M[k] = M[k] or v
end

return M



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
